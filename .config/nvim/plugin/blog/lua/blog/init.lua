local M = {}

local config = require("blog.config")

function M.blog_header()
    local title = ""
    local heading_line_num = 0
    local line_count = vim.fn.line("$")

    for line_num = 1, line_count do
        local line_content = vim.fn.getline(line_num)
        if line_content:match("^# ") then
            title = line_content:gsub("^# ", "")
            heading_line_num = line_num
            break
        end
    end

    if #title == 0 then
        print("Error: No heading found (line starting with '# ')")
        return
    end

    local date_str = os.date("%Y-%m-%dT%T%z")
    date_str = date_str:gsub("([+-]%d%d)(%d%d)$", "%1:%2")

    local front_matter = {
        "+++",
        "date = '" .. date_str .. "'",
        "draft = true",
        "title = '" .. title .. "'",
        "+++",
    }

    vim.fn.append(0, front_matter)

    local adjusted_line_num = heading_line_num + #front_matter
    vim.cmd(adjusted_line_num .. "delete")

    print("Added blog header with title: " .. title)
end

function M.blog_write(subdir)
    local target = vim.fn.expand(config.get("blog_content_dir")) .. "/" .. subdir .. "/" .. vim.fn.expand("%:t")

    if vim.fn.filereadable(target) == 1 then
        local choice = vim.fn.confirm("File already exists:\n" .. target .. "\nOverwrite?", "&Yes\n&No", 2)
        if choice ~= 1 then
            print("Aborted: file not written.")
            return
        end
    end

    vim.cmd("write " .. vim.fn.fnameescape(target))
    vim.cmd("edit " .. vim.fn.fnameescape(target))
    print("File written to: " .. target)
    M.blog_header()
end

function M.blog_image(opts)
    -- Paste hugo image
    -- Get source image path from command arguments
    local src = opts.args
    if src == "" then
        print("Usage: :BlogImage <path-to-image>")
        return
    end

    -- Resolve to absolute path
    src = vim.fn.fnamemodify(src, ":p")
    if not vim.loop.fs_stat(src) then
        print("File not found: " .. src)
        return
    end

    -- Determine target directory (file's stem) and create it
    local target_dir = vim.fn.expand("%:p:r")
    vim.fn.mkdir(target_dir, "p")

    -- Generate unique destination filename (preserve original extension)
    local ext = vim.fn.fnamemodify(src, ":e")
    if ext == "" then
        ext = "png"
    end
    local timestamp = os.date("%Y%m%d%H%M%S")
    local random = math.random(1000, 9999)
    local dest_name = timestamp .. "_" .. random .. "." .. ext
    local dest = target_dir .. "/" .. dest_name

    -- Copy file
    local ok, err = vim.loop.fs_copyfile(src, dest)
    if not ok then
        print("Copy failed: " .. (err or "unknown error"))
        return
    end

    -- Alt text from visual selection or prompt
    local alt_text = ""
    local mode = vim.fn.mode()
    if mode:find("[vV]") then
        vim.cmd('normal! gv"xy')
        alt_text = vim.fn.getreg("x")
    else
        alt_text = vim.fn.input("Alt text: ")
    end

    -- Relative path from markdown file to image
    local rel_path = "./" .. dest_name
    local img_tag = "![" .. alt_text .. "](" .. rel_path .. ")"

    -- Insert or replace selection
    if mode:find("[vV]") then
        vim.cmd('normal! gv"_s' .. img_tag:gsub(" ", "\\ ") .. "\27")
    else
        vim.api.nvim_put({ img_tag }, "", true, true)
    end
end

function M.setup(opts)
    config.setup(opts)

    vim.api.nvim_create_user_command("BlogHeader", function()
        M.blog_header()
    end, {
        desc = "Add Hugo front matter to blog post",
    })

    vim.api.nvim_create_user_command("BlogWrite", function(opts)
        M.blog_write(opts.args)
    end, {
        nargs = 1,
        desc = "Write blog post to content directory",
    })

    vim.api.nvim_create_user_command("BlogImage", function(opts)
        M.blog_image(opts)
    end, {
        nargs = 1,
        desc = "Copy image into subdirecotry for use display in Hugo page",
    })
end

return M
