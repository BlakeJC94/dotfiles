import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Type } from "typebox";
import type { ExtensionAPI, ExtensionToolContext } from "@earendil-works/pi-coding-agent";

import {
  findAgentStatus,
  findWorkspaceAgent,
  isMessageableStatus,
  listWorkspaceAgents,
  type WorkspaceAgent,
} from "./communication-state.ts";

const execFileAsync = promisify(execFile);
const COMMUNICATION_PARAMS = Type.Object({
  action: Type.Union([Type.Literal("list"), Type.Literal("message")]),
  recipient: Type.Optional(Type.String()),
  message: Type.Optional(Type.String()),
});

interface CommunicationParams {
  action: "list" | "message";
  recipient?: string;
  message?: string;
}

export function registerCommunicationTool(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "my_agent_communicate",
    label: "My Agent Communicate",
    description:
      "List live agents in this Herdr workspace or send a message to an idle workflow teammate by exact agent name.",
    promptSnippet: "discover or message an available agent in this Herdr workspace",
    promptGuidelines: [
      "Use my_agent_communicate to discover peers and send handoffs; do not use shell access for Herdr communication.",
      "Only message agents named in the active workflow context. A matching role name alone does not establish workflow membership.",
      "Do not message a working or blocked agent, and do not resend when delivery is uncertain. Relay through the workflow coordinator instead.",
    ],
    parameters: COMMUNICATION_PARAMS,
    defaultActive: false,
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx: ExtensionToolContext) {
      const input = params as CommunicationParams;
      const context = getWorkspaceContext();
      if (!context) return errorResult("Herdr workspace context is unavailable in this session.");

      try {
        const agents = await listCurrentWorkspaceAgents(context);
        if (input.action === "list") return listResult(context.workspaceId, agents);

        const recipient = input.recipient?.trim();
        const message = input.message?.trim();
        if (!recipient) return errorResult("action=message requires recipient.");
        if (!message) return errorResult("action=message requires a non-empty message.");

        const peer = agents.find((agent) => agent.name === recipient);
        if (!peer) {
          return errorResult(`No live agent named ${recipient} is available in workspace ${context.workspaceId}.`);
        }

        const latest = await herdrJson(["agent", "get", recipient]);
        const latestPeer = findWorkspaceAgent(latest, recipient, context.workspaceId);
        if (!latestPeer || latestPeer.paneId !== peer.paneId) {
          return errorResult(`${recipient} is no longer in workspace ${context.workspaceId}; refresh the agent list.`);
        }
        const status = findAgentStatus(latest);
        if (!isMessageableStatus(status)) {
          return errorResult(`${recipient} is ${status ?? "unknown"}; message only idle or done agents.`);
        }

        await herdrJson(["agent", "prompt", recipient, message, "--wait", "--timeout", "120000"]);
        const response = await herdrText(["agent", "read", recipient, "--source", "recent-unwrapped", "--lines", "80"]);
        const finalState = await herdrJson(["agent", "get", recipient]);
        const finalStatus = findAgentStatus(finalState);
        if (!isMessageableStatus(finalStatus)) {
          return errorResult(`Message sent to ${recipient}, but it finished in ${finalStatus ?? "unknown"} state. Inspect its output before continuing.\n\n${response}`);
        }
        return {
          content: [{ type: "text" as const, text: `Message delivered to ${recipient}.\n\n${response}` }],
          details: { workspaceId: context.workspaceId, recipient, response },
        };
      } catch (error) {
        return errorResult(
          `Herdr communication failed. Delivery may be uncertain; inspect the recipient before retrying: ${errorMessage(error)}`,
        );
      }
    },
  });
}

function getWorkspaceContext(): { workspaceId: string; paneId: string } | undefined {
  const paneId = process.env.HERDR_PANE_ID;
  const workspaceId = process.env.HERDR_WORKSPACE_ID ?? paneId?.split(":")[0];
  if (process.env.HERDR_ENV !== "1" || !paneId || !workspaceId) return undefined;
  return { workspaceId, paneId };
}

async function listCurrentWorkspaceAgents(context: { workspaceId: string; paneId: string }): Promise<WorkspaceAgent[]> {
  const listed = await herdrJson(["agent", "list"]);
  return listWorkspaceAgents(listed, context.workspaceId, context.paneId);
}

async function herdrJson(args: string[]): Promise<unknown> {
  const { stdout } = await execFileAsync("herdr", args, { timeout: 130000, maxBuffer: 1024 * 1024 });
  const envelope: unknown = JSON.parse(stdout);
  if (!isRecord(envelope) || !("result" in envelope)) throw new Error("Herdr returned an unexpected response.");
  return envelope.result;
}

async function herdrText(args: string[]): Promise<string> {
  const { stdout } = await execFileAsync("herdr", args, { timeout: 15000, maxBuffer: 1024 * 1024 });
  return stdout.trim();
}

function listResult(workspaceId: string, agents: WorkspaceAgent[]) {
  const lines = agents.map((agent) => `- ${agent.name} (${agent.status}) ${agent.paneId}`);
  return {
    content: [{ type: "text" as const, text: `Agents in Herdr workspace ${workspaceId}:\n${lines.join("\n") || "(none)"}` }],
    details: { workspaceId, agents },
  };
}

function errorResult(message: string) {
  return { content: [{ type: "text" as const, text: message }], details: { error: message }, isError: true };
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    const stderr = "stderr" in error && typeof error.stderr === "string" ? error.stderr.trim() : "";
    return [error.message, stderr].filter(Boolean).join(": ");
  }
  return String(error);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
