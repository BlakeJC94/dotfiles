local M = {}

local config = require("field-notes.config")

local notes = require("field-notes.notes")
local log = require("field-notes.log")

function M.setup(opts)
    config.setup(opts)
    notes.setup()
    log.setup()
end

return M
