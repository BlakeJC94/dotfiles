import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { readdir, readFile } from "node:fs/promises";
import type { Dirent } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import { promisify } from "node:util";
import { pages } from "./pages.ts";

const execFileAsync = promisify(execFile);
const extensionFile = /\.(?:[cm]?js|[cm]?ts)$/i;

type Plugin = { name: string };

async function packageName(directory: string): Promise<string | undefined> {
  try {
    const manifest = JSON.parse(await readFile(join(directory, "package.json"), "utf8")) as {
      name?: unknown;
    };
    return typeof manifest.name === "string" ? manifest.name : undefined;
  } catch {
    return undefined;
  }
}

async function hasExtensionEntry(directory: string): Promise<boolean> {
  let entries: Dirent[];
  try {
    entries = await readdir(directory, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }

  if (entries.some((entry) => entry.isFile() && /^index\.(?:[cm]?js|[cm]?ts)$/i.test(entry.name))) {
    return true;
  }

  try {
    const manifest = JSON.parse(await readFile(join(directory, "package.json"), "utf8")) as {
      pi?: { extensions?: unknown };
    };
    return Array.isArray(manifest.pi?.extensions) && manifest.pi.extensions.length > 0;
  } catch {
    return false;
  }
}

async function scanExtensionDirectory(directory: string): Promise<Plugin[]> {
  let entries: Dirent[];
  try {
    entries = await readdir(directory, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return [];
    throw error;
  }

  const plugins: Plugin[] = [];
  for (const entry of entries) {
    if (entry.isFile() && extensionFile.test(entry.name) && !entry.name.endsWith(".d.ts")) {
      plugins.push({ name: entry.name.replace(extensionFile, "") });
    } else if (entry.isDirectory() && (await hasExtensionEntry(join(directory, entry.name)))) {
      plugins.push({ name: entry.name });
    }
  }
  return plugins;
}

async function listPiPackages(cwd: string): Promise<Plugin[]> {
  const { stdout } = await execFileAsync("pi", ["list", "--no-approve"], { cwd, encoding: "utf8" });
  const matches = stdout.matchAll(/^ {2}([^\r\n]+)\r?\n {4}([^\r\n]+)$/gm);
  const plugins: Plugin[] = [];

  for (const match of matches) {
    const source = match[1]?.trim();
    const directory = match[2]?.trim();
    if (!source || !directory) continue;
    plugins.push({ name: (await packageName(directory)) ?? basename(directory) });
  }
  return plugins;
}

function getPage(name: string): string | undefined {
  const pageName = Object.keys(pages).find((page) => page.toLowerCase() === name.toLowerCase());
  return pageName ? pages[pageName] : undefined;
}

async function discoverPlugins(cwd: string): Promise<{ plugins: Plugin[]; packageError?: string }> {
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  const localDirectories = [join(agentDir, "extensions"), join(cwd, ".pi", "extensions")];
  const scanned = (await Promise.all(localDirectories.map(scanExtensionDirectory))).flat();
  let packages: Plugin[] = [];
  let packageError: string | undefined;

  try {
    packages = await listPiPackages(cwd);
  } catch (error) {
    packageError = error instanceof Error ? error.message : String(error);
  }

  const plugins = new Map<string, Plugin>();
  for (const plugin of [...scanned, ...packages]) {
    plugins.set(plugin.name.toLowerCase(), plugin);
  }
  return { plugins: [...plugins.values()].sort((a, b) => a.name.localeCompare(b.name)), packageError };
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("plugin-help", {
    description: "List installed Pi extensions or show a local TL;DR page",
    getArgumentCompletions: (prefix) =>
      Object.keys(pages)
        .filter((name) => name.toLowerCase().startsWith(prefix.toLowerCase()))
        .map((name) => ({ value: name, label: name })),
    handler: async (args, ctx) => {
      const { plugins, packageError } = await discoverPlugins(ctx.cwd);
      const name = args.trim();

      if (!name) {
        if (packageError) ctx.ui.notify(`pi list failed: ${packageError}`, "warning");
        if (plugins.length === 0) {
          ctx.ui.notify("No Pi extensions found.", "info");
          return;
        }

        const items = plugins.map(({ name: pluginName }) => {
          const hasPage = Object.keys(pages).some((pageName) => pageName.toLowerCase() === pluginName.toLowerCase());
          return `${pluginName}${hasPage ? "" : " (TL;DR missing)"}`;
        });
        const selected = await ctx.ui.select("Installed Pi extensions", items);
        if (!selected) return;
        const selectedName = selected.replace(/ \(TL;DR missing\)$/, "");
        const selectedPlugin = plugins.find((candidate) => candidate.name === selectedName);
        if (selectedPlugin) {
          const page = getPage(selectedPlugin.name);
          ctx.ui.notify(page ?? `No TL;DR page for "${selectedPlugin.name}". Add one to plugin-help/pages.ts.`, page ? "info" : "warning");
        }
        return;
      }

      const plugin = plugins.find((candidate) => candidate.name.toLowerCase() === name.toLowerCase());
      if (!plugin) {
        ctx.ui.notify(`Unknown Pi extension "${name}". Run /plugin-help to list extensions.`, "warning");
        return;
      }

      const page = getPage(plugin.name);
      if (!page) {
        ctx.ui.notify(`No TL;DR page for "${plugin.name}". Add one to plugin-help/pages.ts.`, "warning");
        return;
      }

      ctx.ui.notify(page, "info");
    },
  });
}
