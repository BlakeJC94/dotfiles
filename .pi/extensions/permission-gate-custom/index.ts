import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Rule = {
    name: string;
    pattern: RegExp;
};

const ALLOWLIST: Rule[] = [
    // AIDEV-NOTE: Read-only git commands bypass prompts; all other git commands are gated.
    { name: "git-status", pattern: /^\s*git\s+status\b[^;&|]*$/i },
    { name: "git-diff", pattern: /^\s*git\s+diff\b[^;&|]*$/i },
    { name: "git-log", pattern: /^\s*git\s+log\b[^;&|]*$/i },
    { name: "git-show", pattern: /^\s*git\s+show\b[^;&|]*$/i },
    { name: "git-rev-parse", pattern: /^\s*git\s+rev-parse\b[^;&|]*$/i },
    { name: "git-remote-v", pattern: /^\s*git\s+remote\s+-v\b[^;&|]*$/i },
    { name: "git-branch-list", pattern: /^\s*git\s+branch\s+(?:--list|--show-current)\b[^;&|]*$/i },
    { name: "git-tag-list", pattern: /^\s*git\s+tag\s+--list\b[^;&|]*$/i },
    { name: "git-ls-files", pattern: /^\s*git\s+ls-files\b[^;&|]*$/i },
    { name: "git-ls-tree", pattern: /^\s*git\s+ls-tree\b[^;&|]*$/i },
    { name: "git-cat-file", pattern: /^\s*git\s+cat-file\b[^;&|]*$/i },
    { name: "git-blame", pattern: /^\s*git\s+blame\b[^;&|]*$/i },
];

const BLOCKLIST: Rule[] = [
    // AIDEV-NOTE: High-risk command families requiring per-command approval.
    { name: "recursive-delete", pattern: /\brm\s+(-rf?|--recursive)\b/i },
    { name: "rm", pattern: /\brm\b/i },
    { name: "sudo", pattern: /\bsudo\b/i },
    { name: "su", pattern: /\bsu\b/i },
    { name: "doas", pattern: /\bdoas\b/i },
    { name: "bash", pattern: /\bbash\b/i },
    { name: "sh", pattern: /(^|\s)sh(\s|$)/i },
    { name: "zsh", pattern: /\bzsh\b/i },
    { name: "bash-c", pattern: /\bbash\s+-c\b/i },
    { name: "sh-c", pattern: /(^|\s)sh\s+-c\b/i },
    { name: "zsh-c", pattern: /\bzsh\s+-c\b/i },
    { name: "source", pattern: /(^|\s)source\s+/i },
    { name: "dot-source", pattern: /(^|\s)\.\s+\S+/i },
    { name: "eval", pattern: /(^|\s)eval\s+/i },

    { name: "python", pattern: /\bpython(\d+(\.\d+)?)?\b/i },
    { name: "python-c", pattern: /\bpython(\d+(\.\d+)?)?\s+-c\b/i },
    { name: "uv-run", pattern: /\buv\s+run\b/i },
    { name: "node-e", pattern: /\bnode\s+-e\b/i },
    { name: "perl-e", pattern: /\bperl\s+-e\b/i },
    { name: "ruby-e", pattern: /\bruby\s+-e\b/i },

    { name: "apt", pattern: /\bapt(?:-get)?\b/i },
    { name: "brew", pattern: /\bbrew\b/i },
    { name: "pip", pattern: /\bpip(?:3)?\b/i },
    { name: "pipx", pattern: /\bpipx\b/i },
    { name: "npm", pattern: /\bnpm\b/i },
    { name: "pnpm", pattern: /\bpnpm\b/i },
    { name: "yarn", pattern: /\byarn\b/i },
    { name: "bun", pattern: /\bbun\b/i },
    { name: "cargo-install", pattern: /\bcargo\s+install\b/i },
    { name: "go-install", pattern: /\bgo\s+install\b/i },
    { name: "snap", pattern: /\bsnap\b/i },
    { name: "flatpak", pattern: /\bflatpak\b/i },
    { name: "apk", pattern: /\bapk\b/i },
    { name: "dnf", pattern: /\bdnf\b/i },
    { name: "yum", pattern: /\byum\b/i },
    { name: "pacman", pattern: /\bpacman\b/i },

    { name: "aws-cli", pattern: /\baws\b/i },
    { name: "gcp-cli", pattern: /\bgcloud\b/i },
    { name: "gsutil", pattern: /\bgsutil\b/i },
    { name: "azure-cli", pattern: /\baz\b/i },
    { name: "kubectl", pattern: /\bkubectl\b/i },
    { name: "helm", pattern: /\bhelm\b/i },
    { name: "terraform", pattern: /\bterraform\b/i },
    { name: "terragrunt", pattern: /\bterragrunt\b/i },

    { name: "curl", pattern: /\bcurl\b/i },
    { name: "wget", pattern: /\bwget\b/i },
    { name: "curl-pipe-shell", pattern: /\bcurl\b.*\|\s*(sh|bash|zsh)\b/i },
    { name: "scp", pattern: /\bscp\b/i },
    { name: "rsync", pattern: /\brsync\b/i },
    { name: "sftp", pattern: /\bsftp\b/i },
    { name: "ssh", pattern: /\bssh\b/i },
    { name: "netcat", pattern: /\b(?:nc|netcat|ncat|socat)\b/i },
    { name: "openssl", pattern: /\bopenssl\b/i },

    { name: "chmod", pattern: /\bchmod\b/i },
    { name: "chown", pattern: /\bchown\b/i },
    { name: "chgrp", pattern: /\bchgrp\b/i },
    { name: "mount", pattern: /\bmount\b/i },
    { name: "umount", pattern: /\bumount\b/i },
    { name: "systemctl", pattern: /\bsystemctl\b/i },
    { name: "service", pattern: /\bservice\b/i },
    { name: "launchctl", pattern: /\blaunchctl\b/i },
    { name: "passwd", pattern: /\bpasswd\b/i },
    { name: "useradd", pattern: /\buseradd\b/i },
    { name: "usermod", pattern: /\busermod\b/i },
    { name: "userdel", pattern: /\buserdel\b/i },
    { name: "visudo", pattern: /\bvisudo\b/i },

    { name: "mv-force", pattern: /\bmv\b[^\n]*\s-f\b/i },
    { name: "cp-force", pattern: /\bcp\b[^\n]*\s-f\b/i },
    { name: "dd", pattern: /\bdd\b/i },
    { name: "mkfs", pattern: /\bmkfs(?:\.[\w-]+)?\b/i },
    { name: "fdisk", pattern: /\bfdisk\b/i },
    { name: "parted", pattern: /\bparted\b/i },
    { name: "wipefs", pattern: /\bwipefs\b/i },
    { name: "shred", pattern: /\bshred\b/i },
    { name: "truncate", pattern: /\btruncate\b/i },
    { name: "ln-force", pattern: /\bln\b[^\n]*\s-sf\b/i },

    { name: "git-non-readonly", pattern: /\bgit\b/i },
];

function firstMatch(command: string, rules: Rule[]): Rule | undefined {
    return rules.find((rule) => rule.pattern.test(command));
}

export default function permissionGateCustom(pi: ExtensionAPI): void {
    pi.on("tool_call", async (event, ctx) => {
        if (event.toolName !== "bash") return;

        const command = String(event.input.command ?? "").trim();
        if (!command) return;

        const allowMatch = firstMatch(command, ALLOWLIST);
        if (allowMatch) return;

        const blockMatch = firstMatch(command, BLOCKLIST);
        if (!blockMatch) return;

        // AIDEV-NOTE: Non-interactive runs cannot prompt, so dangerous commands are fail-closed.
        if (!ctx.hasUI) {
            console.warn(`[permission-gate-custom] blocked in non-interactive mode: ${command}`);
            return {
                block: true,
                reason: `Blocked by permission-gate-custom (${blockMatch.name}) in non-interactive mode`,
            };
        }

        const approved = await ctx.ui.confirm(
            "Approve bash command?",
            `Rule: ${blockMatch.name}\n\n${command}`,
        );

        if (!approved) {
            return {
                block: true,
                reason: `Blocked by user (${blockMatch.name})`,
            };
        }
    });
}
