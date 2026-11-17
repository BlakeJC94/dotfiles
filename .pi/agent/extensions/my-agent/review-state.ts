export type ReviewStatus = "starting" | "activating" | "prompting" | "waiting" | "completed" | "blocked";
export type ReviewAction = "start" | "follow_up" | "resume";

export interface ReviewModelSettings {
  provider: string;
  model: string;
  thinkingLevel: string;
}

export interface ReviewState {
  id: string;
  reviewerModel: ReviewModelSettings;
  name: string;
  paneId?: string;
  round: number;
  status: ReviewStatus;
  goal: string;
  planPath: string;
  diffScope: string;
  decisions: string;
  constraints: string;
  checkResults: string;
  updates?: string;
  revision: string;
  marker?: string;
  feedback?: string;
}

export function getReviewState(branch: readonly unknown[]): ReviewState | undefined {
  const entry = [...branch].reverse().find((candidate) => {
    return isRecord(candidate) && candidate.type === "custom" && candidate.customType === "my-agent-review";
  });
  if (!isRecord(entry) || !isRecord(entry.data)) return undefined;
  const value = entry.data;
  if (
    typeof value.id !== "string" ||
    typeof value.name !== "string" ||
    !isRecord(value.reviewerModel) ||
    typeof value.reviewerModel.provider !== "string" ||
    typeof value.reviewerModel.model !== "string" ||
    typeof value.reviewerModel.thinkingLevel !== "string" ||
    typeof value.round !== "number" ||
    !Number.isInteger(value.round) ||
    value.round < 1 ||
    value.round > 3 ||
    !isReviewStatus(value.status) ||
    typeof value.goal !== "string" ||
    typeof value.planPath !== "string" ||
    typeof value.diffScope !== "string" ||
    typeof value.decisions !== "string" ||
    typeof value.constraints !== "string" ||
    typeof value.checkResults !== "string" ||
    typeof value.revision !== "string"
  ) {
    return undefined;
  }
  if (value.paneId !== undefined && typeof value.paneId !== "string") return undefined;
  if (value.updates !== undefined && typeof value.updates !== "string") return undefined;
  if (value.marker !== undefined && typeof value.marker !== "string") return undefined;
  if (value.feedback !== undefined && typeof value.feedback !== "string") return undefined;
  return value as unknown as ReviewState;
}

export function buildReviewPrompt(state: ReviewState): string {
  const followUp = state.round > 1;
  return [
    "Review the current changes and return only actionable findings, or exactly 'No further notes.'",
    `Review cycle: ${state.id}; round ${state.round}/3; revision: ${state.revision}.`,
    `Goal: ${state.goal}`,
    `Approved plan: ${state.planPath}`,
    `Exact diff scope: ${state.diffScope}`,
    `Decisions: ${state.decisions}`,
    `Constraints: ${state.constraints}`,
    `Checks: ${state.checkResults}`,
    ...(followUp ? [`Round updates: ${state.updates ?? "None provided."}`] : []),
    "Read the approved plan and the specified diff scope. Do not edit files.",
    "Report findings with severity, file and line, impact, and the smallest fix.",
    `End your complete response with this exact line: ${state.marker}`,
  ].join("\n");
}

export function hasCompletedMarker(output: string, marker: string): boolean {
  const first = output.indexOf(marker);
  return first >= 0 && output.indexOf(marker, first + marker.length) >= 0;
}

export function isReviewStatus(value: unknown): value is ReviewStatus {
  return value === "starting" || value === "activating" || value === "prompting" || value === "waiting" || value === "completed" || value === "blocked";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
