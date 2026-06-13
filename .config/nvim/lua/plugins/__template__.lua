return {}

--- Without config
-- return { "https://github.com/USER/REPO" }

--- With config
--- https://lazy.folke.io/spec
-- return {
--     "https://github.com/mfussenegger/nvim-jdtls",
--     lazy = true,
--     branch = "main",
--     build = " ... ",
--     opts = { ... },
--     keys = {
--         { "KEY", "VAL", opts... },
--     },
--     cmd = { ... },
--     config = function()
--         ...
--     end
-- }
