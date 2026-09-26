local M = {}

local function trim_trailing_newlines(text)
    return (text or ""):gsub("\n+$", "")
end

local function get_git_output(dir, git_args)
    if vim.system then
        local argv = { "git", "-C", dir }
        vim.list_extend(argv, git_args)
        local result = vim.system(argv, { text = true }):wait()
        if result.code ~= 0 then
            return ""
        end

        return trim_trailing_newlines(result.stdout)
    end

    local cmd = string.format("git -C %s %s", vim.fn.shellescape(dir), table.concat(git_args, " "))
    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        return ""
    end

    return trim_trailing_newlines(output)
end

function M.slugify(str)
    local output = str:lower()
    output = output:gsub("%W+", "-")
    output = output:gsub("^-+", "")
    output = output:gsub("-+$", "")
    return output
end

function M.get_git_dir()
    if vim.fn.executable("git") == 0 then
        return ""
    end

    local dir = vim.fn.expand("%:p:h")
    local result = get_git_output(dir, { "rev-parse", "--git-dir" })

    if result ~= "" then
        return result
    end

    -- Detect the dotfiles bare repo (~/.dotfiles with worktree=$HOME).
    -- The alias `git dotfiles` in ~/.gitconfig runs:
    --   git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
    -- Standard git discovery won't find it (no .git in $HOME), so check explicitly.
    local home = vim.fn.expand("~")
    local dotfiles_dir = home .. "/.dotfiles"
    if dir:sub(1, #home) == home and vim.fn.isdirectory(dotfiles_dir) == 1 then
        local is_bare = get_git_output(dotfiles_dir, { "rev-parse", "--is-bare-repository" })
        if is_bare == "true" then
            return dotfiles_dir
        end
    end

    return ""
end

-- AIDEV-NOTE: Use argv-based copy to avoid shell quoting bugs in paths.
function M.copy_file(source_path, dest_path)
    if vim.system then
        local result = vim.system({ "cp", source_path, dest_path }, { text = true }):wait()
        if result.code ~= 0 then
            local error_text = vim.trim(result.stderr or result.stdout or "cp failed")
            return nil, error_text
        end

        return true
    end

    local cmd = string.format("cp %s %s", vim.fn.shellescape(source_path), vim.fn.shellescape(dest_path))
    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        return nil, vim.trim(output)
    end

    return true
end

function M.get_note_image_dir()
    local note_parent_dir = vim.fn.expand("%:p:h")
    local note_stem = vim.fn.expand("%:t:r")
    local img_subdir = M.slugify(note_stem)
    local img_dir = note_parent_dir .. "/img/" .. img_subdir

    return img_dir, img_subdir, note_parent_dir, note_stem
end

function M.markdown_image_link(alt_text, relative_path)
    return "![" .. alt_text .. "](" .. relative_path .. ")"
end

function M.get_note_title(...)
    local args = { ... }
    local title = table.concat(args, " ")

    if #title == 0 then
        local current_dir = vim.fn.expand("%:p:h")
        local git_dir = M.get_git_dir()
        local project_name = ""
        local branch_name = ""

        if #git_dir > 0 then
            local home_dir = vim.fn.fnamemodify(vim.fn.expand("~"), ":p"):gsub("/$", "")
            local git_dir_path = git_dir
            if git_dir_path:sub(1, 1) ~= "/" then
                git_dir_path = current_dir .. "/" .. git_dir_path
            end
            git_dir_path = vim.fn.fnamemodify(git_dir_path, ":p"):gsub("/$", "")

            -- Hardcoded: skip the dotfiles bare repo (~/.dotfiles with worktree=$HOME)
            -- Declined via `git dotfiles` alias in ~/.gitconfig.
            local dotfiles_dir = home_dir .. "/.dotfiles"
            if git_dir_path == dotfiles_dir then
                git_dir = ""
            else
                local project_path = vim.fn.finddir(".git/..", current_dir .. ";")
                local project_root = vim.fn.fnamemodify(project_path, ":p"):gsub("/$", "")

                if project_root == home_dir or git_dir_path == home_dir then
                    git_dir = ""
                else
                    project_name = project_path:gsub("^.*/", "")
                    branch_name = get_git_output(current_dir, { "branch", "--show-current", "--quiet" })
                end
            end
        end

        if #git_dir == 0 then
            local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", "")
            local current_dir = vim.fn.fnamemodify(cwd, ":t")
            local parent_dir = vim.fn.fnamemodify(cwd, ":h:t")
            if parent_dir == "" then
                title = current_dir
            else
                title = parent_dir .. ": " .. current_dir
            end
        else
            project_name = project_name:gsub("^%+", "")
            branch_name = branch_name:gsub("^%+", "")
            title = project_name .. ": " .. branch_name
        end
    end

    return title
end

return M
