vim.opt_local.formatoptions:remove("tc")
vim.opt_local.wrap = true
vim.opt_local.conceallevel = 1

-- Treat backslash commands as words so they can expand on a delimiter.
vim.opt_local.iskeyword:append("\\")
vim.cmd([[inoreabbrev <buffer> <expr> \log '* ' . strftime('%H%M')[:2] . '0']])
vim.cmd([[inoreabbrev <buffer> \todo * [ ] **TODO**]])
vim.cmd([[inoreabbrev <buffer> \comment * **COMMENT**]])
vim.cmd([[inoreabbrev <buffer> \idea * **IDEA**:]])
vim.cmd([[inoreabbrev <buffer> \question * **QUESTION**]])
vim.cmd([[inoreabbrev <buffer> \answer * **ANSWER**]])
vim.cmd([[inoreabbrev <buffer> \action * **ACTION**]])
vim.cmd([[inoreabbrev <buffer> \note * **NOTE**]])

vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4

-- Treesitter folds
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

local buf = vim.api.nvim_get_current_buf()
if not vim.b[buf].field_notes_reload_watcher then
    local notes_dir = vim.fs.normalize(vim.fn.expand("~/Workspace/field-notes"))
    local notes_prefix = notes_dir:gsub("/$", "") .. "/"
    local path = vim.fs.normalize(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p"))

    if path:sub(1, #notes_prefix) == notes_prefix then
        local filename = vim.fs.basename(path)
        local directory = vim.fs.dirname(path)
        local watcher = vim.uv.new_fs_event()
        local autosave = vim.uv.new_timer()
        local pending = false
        local external_change = false

        local function get_disk_version()
            local stat = vim.uv.fs_stat(path)
            if not stat then
                return nil
            end
            return string.format("%s:%s:%s:%s", stat.ino or "", stat.size, stat.mtime.sec, stat.mtime.nsec or 0)
        end

        local known_disk_version = get_disk_version()

        local function remember_disk_version()
            known_disk_version = get_disk_version()
            external_change = false
        end

        local function pause_autosave()
            if not external_change then
                external_change = true
                vim.notify(
                    "Field note changed on disk; autosave paused. Save or reload manually to resolve.",
                    vim.log.levels.WARN
                )
            end
        end

        local started, err = watcher:start(directory, {}, function(watch_err, changed_name)
            if watch_err then
                vim.schedule(function()
                    vim.notify("Field-notes watcher error: " .. tostring(watch_err), vim.log.levels.WARN)
                end)
                return
            end
            if changed_name and changed_name ~= filename then
                return
            end

            vim.schedule(function()
                if pending or not vim.api.nvim_buf_is_valid(buf) then
                    return
                end
                pending = true
                vim.defer_fn(function()
                    pending = false
                    if not vim.api.nvim_buf_is_valid(buf) then
                        return
                    end
                    if get_disk_version() == known_disk_version then
                        return
                    end
                    if vim.bo[buf].modified then
                        pause_autosave()
                        return
                    end
                    -- An external reload invalidates the old undo tree; don't persist it.
                    local undofile = vim.bo[buf].undofile
                    vim.bo[buf].undofile = false
                    local ok, reload_err = pcall(vim.api.nvim_buf_call, buf, function()
                        vim.cmd("checktime")
                    end)
                    vim.bo[buf].undofile = undofile
                    if not ok then
                        vim.notify("Could not reload field note: " .. tostring(reload_err), vim.log.levels.WARN)
                        return
                    end
                    known_disk_version = get_disk_version()
                end, 100)
            end)
        end)

        if started then
            vim.b[buf].field_notes_reload_watcher = true
            autosave:start(10000, 10000, function()
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(buf) then
                        return
                    end
                    local current_disk_version = get_disk_version()
                    if not vim.bo[buf].modified then
                        if not external_change then
                            known_disk_version = current_disk_version
                        end
                        return
                    end
                    if current_disk_version ~= known_disk_version then
                        pause_autosave()
                        return
                    end
                    if external_change then
                        return
                    end

                    local ok, write_err = pcall(function()
                        vim.api.nvim_buf_call(buf, function()
                            vim.cmd("silent write")
                        end)
                    end)
                    if not ok then
                        vim.notify("Could not autosave field note: " .. tostring(write_err), vim.log.levels.WARN)
                    end
                end)
            end)
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
                buffer = buf,
                callback = remember_disk_version,
            })
            vim.api.nvim_create_autocmd("BufWipeout", {
                buffer = buf,
                once = true,
                callback = function()
                    watcher:stop()
                    watcher:close()
                    autosave:stop()
                    autosave:close()
                end,
            })
        else
            watcher:close()
            autosave:close()
            vim.notify("Could not watch " .. directory .. ": " .. tostring(err), vim.log.levels.WARN)
        end
    end
end
