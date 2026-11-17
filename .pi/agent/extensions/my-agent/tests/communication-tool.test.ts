import assert from "node:assert/strict";
import { test } from "node:test";

import { isMessageableStatus, listWorkspaceAgents } from "../communication-state.ts";

test("listWorkspaceAgents returns only other agents in the caller's workspace", () => {
  const agents = listWorkspaceAgents(
    {
      result: {
        agents: [
          { agent: "pi", name: "workflow-planner", pane_id: "w2:p1", agent_status: "idle", workspace_id: "w2" },
          { agent: "pi", name: "workflow-coder", pane_id: "w2:p2", agent_status: "working", workspace_id: "w2" },
          { agent: "pi", name: "other-workflow", pane_id: "w3:p1", agent_status: "idle", workspace_id: "w3" },
          { agent: "pi", name: "self", pane_id: "w2:p9", agent_status: "idle", workspace_id: "w2" },
        ],
      },
    },
    "w2",
    "w2:p9",
  );

  assert.deepEqual(agents, [
    { name: "workflow-planner", paneId: "w2:p1", status: "idle" },
    { name: "workflow-coder", paneId: "w2:p2", status: "working" },
  ]);
});

test("only idle or done agents can receive a direct message", () => {
  assert.equal(isMessageableStatus("idle"), true);
  assert.equal(isMessageableStatus("done"), true);
  assert.equal(isMessageableStatus("working"), false);
  assert.equal(isMessageableStatus("blocked"), false);
  assert.equal(isMessageableStatus(undefined), false);
});
