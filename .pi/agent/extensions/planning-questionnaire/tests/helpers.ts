/**
 * Lightweight fakes for unit-testing the planning-questionnaire extension.
 *
 * These mirror only the slices of `ExtensionAPI`, command/tool contexts, and the
 * TUI/Theme that the extension actually touches. They intentionally avoid loading
 * the real pi runtime.
 */

/** A theme whose `fg`/`bold` pass text through unchanged, so render output is ANSI-free and assertable. */
export function passthroughTheme(): {
  fg: (color: string, text: string) => string
  bold: (text: string) => string
} {
  return {
    fg: (_color, text) => text,
    bold: (text) => text,
  }
}

/** Minimal fake TUI: render requests are no-ops; `terminal.rows` satisfies the Editor. */
export function fakeTui(): { requestRender(): void; terminal: { rows: number } } {
  return {
    requestRender() {},
    terminal: { rows: 24 },
  }
}

type EventHandler = (event: unknown, ctx: unknown) => unknown

export interface FakePi {
  handlers: Record<string, EventHandler[]>
  commands: Record<string, { description: string; handler: EventHandler }>
  tools: unknown[]
  sentMessages: string[]
  on(event: string, handler: EventHandler): void
  registerCommand(name: string, def: { description: string; handler: EventHandler }): void
  registerTool(def: unknown): void
  sendUserMessage(message: string): void
}

/** A recording stand-in for `ExtensionAPI` capturing event handlers, commands, tools, and sent messages. */
export function createFakePi(): FakePi {
  const handlers: Record<string, EventHandler[]> = {}
  const commands: Record<string, { description: string; handler: EventHandler }> = {}
  const tools: unknown[] = []
  const sentMessages: string[] = []
  return {
    handlers,
    commands,
    tools,
    sentMessages,
    on(event, handler) {
      ;(handlers[event] ??= []).push(handler)
    },
    registerCommand(name, def) {
      commands[name] = def
    },
    registerTool(def) {
      tools.push(def)
    },
    sendUserMessage(message) {
      sentMessages.push(message)
    },
  }
}

export interface FakeCommandCtx {
  isIdle: () => boolean
  sessionManager: { getBranch: () => unknown[] }
  ui: {
    notify: (message: string, level: string) => void
    setStatus: (key: string, value: unknown) => void
    theme: { fg: (color: string, text: string) => string }
  }
}

export interface FakeCommandState {
  ctx: FakeCommandCtx
  notifications: { message: string; level: string }[]
  status: Record<string, unknown>
}

/** A `/clarify` command context with controllable session branch and idle state. */
export function createFakeCommandCtx(options: {
  branch?: unknown[]
  idle?: boolean
} = {}): FakeCommandState {
  const notifications: { message: string; level: string }[] = []
  const status: Record<string, unknown> = {}
  const ctx: FakeCommandCtx = {
    isIdle: () => options.idle ?? true,
    sessionManager: { getBranch: () => options.branch ?? [] },
    ui: {
      notify: (message, level) => notifications.push({ message, level }),
      setStatus: (key, value) => {
        status[key] = value
      },
      theme: { fg: (_color, text) => text },
    },
  }
  return { ctx, notifications, status }
}

/** Build a session branch entry like the ones `sessionManager.getBranch()` returns. */
export function userEntry(text: string): { type: "message"; message: { role: "user"; content: string } } {
  return { type: "message", message: { role: "user", content: text } }
}

/** A tool-execute context whose `ui.custom` resolves with a preset result, bypassing the real UI. */
export function createExecuteCtx(
  mode: "tui" | "print",
  customResult: { cancelled: boolean; answers: string[][] },
): {
  ctx: { mode: string; ui: { custom: (factory: unknown) => Promise<typeof customResult> } }
} {
  return {
    ctx: {
      mode,
      ui: {
        custom: async () => customResult,
      },
    },
  }
}
