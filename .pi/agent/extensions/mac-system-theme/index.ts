/**
 * Syncs pi theme with macOS system appearance (dark/light mode).
 *
 * Usage:
 *   pi -e examples/extensions/mac-system-theme.ts
 */

import { exec } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Key used to persist the interval ID across module reloads via globalThis.
// Without this, /reload would orphan the old setInterval (still polling) while
// session_start registers a new one, causing duplicate polling intervals.
const INTERVAL_KEY = "__pi_mac_theme_sync_interval";

const execAsync = promisify(exec);
const darkTheme = "gruvbox-dark"
const lightTheme = "gruvbox-light"

async function isDarkMode(): Promise<boolean> {
    try {
        const { stdout } = await execAsync(
            "osascript -e 'tell application \"System Events\" to tell appearance preferences to return dark mode'",
        );
        return stdout.trim() === "true";
    } catch {
        return false;
    }
}

function getStoredInterval(): ReturnType<typeof setInterval> | null {
    return (globalThis as any)[INTERVAL_KEY] ?? null;
}

function storeInterval(id: ReturnType<typeof setInterval> | null) {
    (globalThis as any)[INTERVAL_KEY] = id;
}

export default function (pi: ExtensionAPI) {
    // --- On module reload, the old module's session_shutdown may not fire
    // before the new module is evaluated, so we proactively clean up any
    // orphaned interval inherited from a previous module instance. ---
    const existingId = getStoredInterval();
    if (existingId) {
        clearInterval(existingId);
        storeInterval(null);
    }

    pi.on("session_start", async (_event, ctx) => {
        let currentTheme = (await isDarkMode()) ? darkTheme: lightTheme;

        // First application: pass the theme name (not the object) so the
        // theme is written to settings.json and applied to all TUI components
        // including the editor. This ensures syntax highlighting also takes
        // effect on /reload and /resume, where the editor component
        // reinitializes after session_start and an in-memory-only apply
        // would miss it. The interval below uses the object (in-memory only)
        // to avoid writing settings.json on every 2s poll.
        ctx.ui.setTheme(currentTheme);

        const id = setInterval(async () => {
            const newTheme = (await isDarkMode()) ? darkTheme: lightTheme;
            if (newTheme !== currentTheme) {
                currentTheme = newTheme;
                // Use the theme object for interval-driven changes so
                // settings.json is never written on every poll tick.
                const themeObj = ctx.ui.getTheme(newTheme);
                if (themeObj) ctx.ui.setTheme(themeObj);
            }
        }, 2000);

        storeInterval(id);
    });

    pi.on("session_shutdown", () => {
        const id = getStoredInterval();
        if (id) {
            clearInterval(id);
            storeInterval(null);
        }
    });
}
