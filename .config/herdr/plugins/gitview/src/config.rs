use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::OnceLock;

use serde::Deserialize;

use crate::logx::log;

/// User config from `$HERDR_PLUGIN_CONFIG_DIR/config.toml`. Every key is
/// optional; a missing file or a parse error never prevents startup — we log
/// and fall back to defaults (per shared contracts).
#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
pub struct Config {
    /// Branch-scope base; "" = auto-detect via `Repo::detect_base`.
    pub base: String,
    /// Optional metadata directory for a bare-repo worktree fallback.
    pub git_dir: Option<PathBuf>,
    /// Optional worktree root paired with `git_dir`; supports absolute or `~/` paths.
    pub work_tree: Option<PathBuf>,
    /// Which side the list pane sits on: "right" | "left".
    pub list_side: ListSide,
    /// Editor argv; file (and `+<line>`) appended when launching.
    pub editor: Vec<String>,
    /// Auto-refresh interval in ms; 0 disables polling.
    pub poll_ms: u64,
    pub show_untracked: bool,
    /// Appearance and diff tint flavor.
    pub theme: Theme,
    /// Added/deleted line styling: full backgrounds or only the change gutter.
    pub diff_highlight: DiffHighlight,
    /// Syntax theme: system follows `theme`; explicit Gruvbox variants override it.
    pub syntax_theme: SyntaxTheme,
    /// Which scope the view opens in: "worktree" (default) or "branch".
    pub default_scope: ScopePref,
    /// Unchanged context lines kept around each change before folding (git's
    /// diff.context equivalent). Clamped to 0..=20.
    pub context_lines: usize,
    /// Number of columns a tab expands to in the diff pane. Tabs are expanded
    /// to spaces at render time because ratatui does not interpret `\t`.
    /// Clamped to 1..=16.
    pub tab_width: usize,
    /// action name -> key string, overrides `keymap::DEFAULT_KEYS`.
    pub keybindings: HashMap<String, String>,
    /// How much of the tab the whole gitview sidebar takes (percent of the
    /// tab width). The existing layout is squeezed into the rest, so the
    /// default is an even split with whatever you already had open. Clamped
    /// to 20..=80.
    pub view_width_percent: u8,
    /// How much of the gitview area the file list takes (percent). Clamped
    /// to 10..=80.
    pub list_width_percent: u8,
    /// Sidebar mode: when another pane of the tab already runs nvim (plain
    /// or the herdr-nvim sidebar), Enter opens the file there instead of
    /// starting an editor on the gitview diff pane.
    pub reuse_tab_nvim: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ListSide {
    Right,
    Left,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Theme {
    #[default]
    System,
    Dark,
    Light,
}

impl Theme {
    pub fn is_light(self) -> bool {
        match self {
            Theme::System => system_is_light(),
            Theme::Dark => false,
            Theme::Light => true,
        }
    }
}

fn system_is_light() -> bool {
    static IS_LIGHT: OnceLock<bool> = OnceLock::new();
    *IS_LIGHT.get_or_init(detect_system_is_light)
}

#[cfg(target_os = "macos")]
fn detect_system_is_light() -> bool {
    match std::process::Command::new("/usr/bin/defaults")
        .args(["read", "-g", "AppleInterfaceStyle"])
        .output()
    {
        Ok(output) if output.status.success() => !String::from_utf8_lossy(&output.stdout)
            .trim()
            .eq_ignore_ascii_case("dark"),
        Ok(_) => true,
        Err(_) => false,
    }
}

#[cfg(target_os = "linux")]
fn detect_system_is_light() -> bool {
    std::env::var("COLORFGBG")
        .ok()
        .and_then(|value| value.rsplit(';').next()?.parse::<u8>().ok())
        .is_some_and(|background| background >= 7)
}

#[cfg(not(any(target_os = "macos", target_os = "linux")))]
fn detect_system_is_light() -> bool {
    false
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DiffHighlight {
    #[default]
    Full,
    Gutter,
}

impl DiffHighlight {
    pub fn as_str(self) -> &'static str {
        match self {
            DiffHighlight::Full => "full",
            DiffHighlight::Gutter => "gutter",
        }
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SyntaxTheme {
    #[default]
    System,
    GruvboxDark,
    GruvboxLight,
}

impl SyntaxTheme {
    pub fn as_str(self) -> &'static str {
        match self {
            SyntaxTheme::System => "system",
            SyntaxTheme::GruvboxDark => "gruvbox-dark",
            SyntaxTheme::GruvboxLight => "gruvbox-light",
        }
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ScopePref {
    #[default]
    Worktree,
    Branch,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            base: String::new(),
            git_dir: None,
            work_tree: None,
            list_side: ListSide::Right,
            editor: vec!["nvim".into()],
            poll_ms: 2000,
            show_untracked: true,
            theme: Theme::System,
            diff_highlight: DiffHighlight::Full,
            syntax_theme: SyntaxTheme::System,
            default_scope: ScopePref::Worktree,
            context_lines: 3,
            tab_width: 4,
            keybindings: HashMap::new(),
            view_width_percent: 50,
            list_width_percent: 29,
            reuse_tab_nvim: true,
        }
    }
}

impl Config {
    /// Custom bare-repo context only within the configured worktree, whose
    /// root's `.git` file must point at the configured metadata.
    pub fn bare_repo_context_for(&self, dir: &std::path::Path) -> Option<(PathBuf, PathBuf)> {
        if !self.git_dir.as_ref()?.is_absolute() || !self.work_tree.as_ref()?.is_absolute() {
            return None;
        }
        let git_dir = self.git_dir.as_ref()?.canonicalize().ok()?;
        let work_tree = self.work_tree.as_ref()?.canonicalize().ok()?;
        let dir = dir.canonicalize().ok()?;
        if !dir.starts_with(&work_tree) {
            return None;
        }
        let pointer = std::fs::read_to_string(work_tree.join(".git")).ok()?;
        let target = PathBuf::from(pointer.trim().strip_prefix("gitdir: ")?);
        let target = if target.is_absolute() {
            target
        } else {
            work_tree.join(target)
        };
        (target.canonicalize().ok()? == git_dir).then_some((git_dir, work_tree))
    }

    pub fn load() -> Config {
        Config::load_from(config_path().as_deref())
    }

    /// The config in `path` (`None` or a missing file: the defaults).
    pub fn load_from(path: Option<&std::path::Path>) -> Config {
        let Some(path) = path else {
            return Config::default();
        };
        match std::fs::read_to_string(path) {
            Ok(raw) => Config::parse(&raw),
            Err(_) => Config::default(), // missing file is the normal case
        }
    }

    /// Parse TOML; on error log + fall back to defaults, then clamp.
    fn parse(raw: &str) -> Config {
        let mut cfg = match toml::from_str::<Config>(raw) {
            Ok(cfg) => cfg,
            Err(err) => {
                log(format!("config parse error, using defaults: {err}"));
                eprintln!("gitview: config parse error, using defaults: {err}");
                Config::default()
            }
        };
        let home = std::env::var_os("HOME").map(PathBuf::from);
        cfg.git_dir = cfg
            .git_dir
            .map(|path| expand_home_path(path, home.as_deref()));
        cfg.work_tree = cfg
            .work_tree
            .map(|path| expand_home_path(path, home.as_deref()));
        cfg.context_lines = cfg.context_lines.min(20);
        cfg.tab_width = cfg.tab_width.clamp(1, 16);
        cfg.view_width_percent = cfg.view_width_percent.clamp(20, 80);
        cfg.list_width_percent = cfg.list_width_percent.clamp(10, 80);
        // A tiny non-zero poll interval would hammer git; keep it sane.
        if cfg.poll_ms > 0 {
            cfg.poll_ms = cfg.poll_ms.max(250);
        }
        cfg
    }
}

fn expand_home_path(path: PathBuf, home: Option<&Path>) -> PathBuf {
    let Some(value) = path.to_str().map(str::to_owned) else {
        return path;
    };
    if value == "~" {
        return home.map(Path::to_path_buf).unwrap_or(path);
    }
    if let (Some(home), Some(suffix)) = (home, value.strip_prefix("~/")) {
        return home.join(suffix);
    }
    path
}

fn config_path() -> Option<PathBuf> {
    std::env::var_os("HERDR_PLUGIN_CONFIG_DIR").map(|dir| PathBuf::from(dir).join("config.toml"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_file_gives_defaults() {
        let cfg = Config::parse("");
        assert_eq!(cfg.list_side, ListSide::Right);
        assert_eq!(cfg.editor, vec!["nvim".to_string()]);
        assert_eq!(cfg.poll_ms, 2000);
        assert!(cfg.show_untracked);
        assert!(cfg.base.is_empty());
        assert!(cfg.keybindings.is_empty());
    }

    #[test]
    fn partial_file_keeps_other_defaults() {
        let cfg = Config::parse(
            r#"
            list_side = "left"

            [keybindings]
            stage = "a"
            "#,
        );
        assert_eq!(cfg.list_side, ListSide::Left);
        assert_eq!(cfg.editor, vec!["nvim".to_string()]); // untouched default
        assert_eq!(cfg.keybindings.get("stage").map(String::as_str), Some("a"));
    }

    #[test]
    fn bad_toml_falls_back_to_defaults() {
        let cfg = Config::parse("list_side = [not toml");
        assert_eq!(cfg.list_side, ListSide::Right);
    }

    #[test]
    fn numbers_take_their_defaults_and_are_clamped_into_range() {
        type Field = fn(&Config) -> u64;
        let poll: Field = |c| c.poll_ms;
        let view: Field = |c| c.view_width_percent.into();
        let list: Field = |c| c.list_width_percent.into();
        let tab: Field = |c| c.tab_width as u64;
        let context: Field = |c| c.context_lines as u64;
        for (toml, field, want) in [
            ("poll_ms = 5", poll, 250),
            ("poll_ms = 0", poll, 0), // disabled, not clamped
            ("poll_ms = 1000", poll, 1000),
            ("", view, 50),
            ("view_width_percent = 5", view, 20),
            ("", list, 29),
            ("list_width_percent = 99", list, 80),
            ("", tab, 4),
            ("tab_width = 0", tab, 1),
            ("tab_width = 99", tab, 16),
            ("tab_width = 8", tab, 8),
            ("context_lines = 99", context, 20),
        ] {
            assert_eq!(field(&Config::parse(toml)), want, "{toml:?}");
        }
    }

    #[test]
    fn home_relative_paths_expand_but_other_paths_do_not() {
        let home = Path::new("/home/blake");
        assert_eq!(expand_home_path(PathBuf::from("~"), Some(home)), home);
        assert_eq!(
            expand_home_path(PathBuf::from("~/.dotfiles"), Some(home)),
            home.join(".dotfiles")
        );
        assert_eq!(
            expand_home_path(PathBuf::from("/srv/dotfiles"), Some(home)),
            PathBuf::from("/srv/dotfiles")
        );
        assert_eq!(
            expand_home_path(PathBuf::from("~other/dotfiles"), Some(home)),
            PathBuf::from("~other/dotfiles")
        );
        assert_eq!(
            expand_home_path(PathBuf::from("~/.dotfiles"), None),
            PathBuf::from("~/.dotfiles")
        );
    }

    #[test]
    fn default_scope_parses() {
        assert_eq!(
            Config::parse(r#"default_scope = "branch""#).default_scope,
            ScopePref::Branch
        );
    }
}
