export interface WorkspaceAgent {
  name: string;
  paneId: string;
  status: string;
}

export function listWorkspaceAgents(value: unknown, workspaceId: string, callerPaneId: string): WorkspaceAgent[] {
  const agents = new Map<string, WorkspaceAgent>();
  collectAgents(value, (agent) => {
    if (agent.paneId === callerPaneId || !agent.paneId.startsWith(`${workspaceId}:`)) return;
    agents.set(agent.name, agent);
  });
  return [...agents.values()];
}

export function findWorkspaceAgent(value: unknown, name: string, workspaceId: string): WorkspaceAgent | undefined {
  return listWorkspaceAgents(value, workspaceId, "").find((agent) => agent.name === name);
}

export function findAgentStatus(value: unknown): string | undefined {
  if (!isRecord(value)) return undefined;
  if (typeof value.agent_status === "string") return value.agent_status;
  if (typeof value.state === "string" && ["working", "blocked", "idle", "done", "unknown"].includes(value.state)) {
    return value.state;
  }
  for (const nested of Object.values(value)) {
    const found = findAgentStatus(nested);
    if (found) return found;
  }
  return undefined;
}

export function isMessageableStatus(status: string | undefined): boolean {
  return status === "idle" || status === "done";
}

function collectAgents(value: unknown, visit: (agent: WorkspaceAgent) => void): void {
  if (Array.isArray(value)) {
    for (const item of value) collectAgents(item, visit);
    return;
  }
  if (!isRecord(value)) return;

  if (typeof value.name === "string" && typeof value.pane_id === "string") {
    visit({
      name: value.name,
      paneId: value.pane_id,
      status: findAgentStatus(value) ?? "unknown",
    });
  }
  for (const nested of Object.values(value)) collectAgents(nested, visit);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
