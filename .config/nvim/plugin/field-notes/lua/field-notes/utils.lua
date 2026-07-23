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
    return get_git_output(dir, { "rev-parse", "--git-dir" })
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
            local project_path = vim.fn.finddir(".git/..", current_dir .. ";")
            local project_root = vim.fn.fnamemodify(project_path, ":p"):gsub("/$", "")
            local is_bare_repo = get_git_output(current_dir, { "rev-parse", "--is-bare-repository" }) == "true"
            local core_worktree = get_git_output(current_dir, { "config", "--get", "core.worktree" })
            local worktree_path = core_worktree
            if worktree_path ~= "" and worktree_path:sub(1, 1) ~= "/" then
                worktree_path = current_dir .. "/" .. worktree_path
            end
            if worktree_path ~= "" then
                worktree_path = vim.fn.fnamemodify(worktree_path, ":p"):gsub("/$", "")
            end
            local git_dir_in_home = git_dir_path:sub(1, #home_dir + 1) == (home_dir .. "/")

            -- AIDEV-NOTE: Ignore home-level bare repos (eg ~/.dotfiles with worktree=$HOME) for auto-title.
            local is_home_bare_repo = is_bare_repo and git_dir_in_home and (worktree_path == "" or worktree_path == home_dir)

            if project_root == home_dir or git_dir_path == home_dir or is_home_bare_repo then
                git_dir = ""
            else
                project_name = project_path:gsub("^.*/", "")
                branch_name = get_git_output(current_dir, { "branch", "--show-current", "--quiet" })
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
