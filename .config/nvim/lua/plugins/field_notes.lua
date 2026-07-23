return {
    dir = vim.fn.stdpath("config") .. "/plugin/field-notes",
    lazy = false,
    dependencies = {
        "https://github.com/ibhagwan/fzf-lua",
    },
    opts = {
        field_notes_dir = vim.fn.expand("~/Workspace/field-notes"),
        field_notes_templates_dir = vim.fn.stdpath("config") .. "/plugin/field-notes/_templates",
    },
    keys = {
        { "<Leader>nn", ":Note<CR>" },
        { "<Leader>nf", ":FzfLua notes<CR>" },
        { "<Leader>nl", ":FzfLua notes_link<CR>" },
    },
    config = function(_, opts)
        local field_notes = require("field-notes")
        field_notes.setup(opts)

        local fzf = require("fzf-lua")
        local dir = require("field-notes.config").get("field_notes_dir")
        local selector_cmd = "find . -maxdepth 1 -type f -printf '%T@ %f\n' | sort -rn | sed 's/^[^ ]* //'"

        -- AIDEV-NOTE: field-notes owns notes selectors; fzf-lua just hosts the registered extensions.
        fzf.register_extension("notes", function(o)
            o = fzf.config.normalize_opts(o, "notes")
            if not o then
                return
            end
            fzf.files(vim.tbl_extend("force", {
                cwd = dir,
                cmd = selector_cmd,
                actions = {
                    ["default"] = function(selected)
                        if not selected or #selected == 0 then
                            return
                        end
                        local stem = selected[1]:gsub("%.md$", "")
                        field_notes.open_note(false, stem)
                    end,
                },
            }, o))
        end, {
            prompt = "Notes> ",
        })

        fzf.register_extension("notes_link", function(o)
            o = fzf.config.normalize_opts(o, "notes_link")
            if not o then
                return
            end
            fzf.files(vim.tbl_extend("force", {
                cwd = dir,
                cmd = selector_cmd,
                actions = {
                    ["default"] = function(selected)
                        if not selected or #selected == 0 then
                            return
                        end
                        local stem = selected[1]:gsub("%.md$", "")
                        field_notes.link_note(stem, vim.fn.expand("#"))
                    end,
                },
            }, o))
        end, {
            prompt = "NoteLink> ",
        })
    end,
}
