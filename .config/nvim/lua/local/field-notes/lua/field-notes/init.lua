local M = {}

local config = require("field-notes.config")

local notes = require("field-notes.notes")
local link = require("field-notes.link")
local log = require("field-notes.log")
local urltitle = require("field-notes.urltitle")

-- AIDEV-NOTE: Expose stable top-level API used by external config/actions.
M.open_note = notes.open_note
M.link_note = link.link_note
M.url_title = urltitle.url_title

function M.setup(opts)
    config.setup(opts)
    notes.setup()
    log.setup()
end

return M
