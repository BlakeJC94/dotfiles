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
        local git_dir = M.get_git_dir()
        local project_name = ""
        local branch_name = ""

        if #git_dir > 0 then
            local project_path = vim.fn.finddir(".git/..", vim.fn.expand("%:p:h") .. ";")
            project_name = project_path:gsub("^.*/", "")

            branch_name = get_git_output(vim.fn.expand("%:p:h"), { "branch", "--show-current", "--quiet" })
        else
            local cwd_parts = vim.split(vim.fn.getcwd(), "/", { trimempty = true })
            project_name = cwd_parts[#cwd_parts - 1] or cwd_parts[#cwd_parts] or "notes"
            branch_name = cwd_parts[#cwd_parts] or "scratch"
        end

        project_name = project_name:gsub("^%+", "")
        branch_name = branch_name:gsub("^%+", "")
        title = project_name .. ": " .. branch_name
    end

    return title
end

return M
