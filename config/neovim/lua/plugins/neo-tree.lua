-- Neo-tree file explorer configuration
-- Override LazyVim defaults to use current working directory instead of git root

return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
      end,
      desc = "Explorer (cwd)",
    },
    -- Disable the float explorer binding
    { "<leader>fe", false },
    { "<leader>fE", false },
  },
  opts = {
    filesystem = {
      -- Use current working directory instead of git root
      bind_to_cwd = true,
      -- Follow the current file
      follow_current_file = {
        enabled = true,
      },
      -- Don't hijack netrw
      hijack_netrw_behavior = "open_default",
      -- Use current directory instead of git root
      use_libuv_file_watcher = true,
    },
    window = {
      position = "left", -- Always use left sidebar, not float
      mappings = {
        -- Update '.' to show current directory instead of git root
        ["."] = "set_root",
        -- Add mapping to navigate to parent directory
        ["<bs>"] = "navigate_up",
        -- Add mapping to toggle hidden files
        ["H"] = "toggle_hidden",
      },
    },
  },
}
