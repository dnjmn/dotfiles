-- Seamless navigation between neovim splits and tmux panes.
-- The tmux half lives in config/tmux/tmux.conf (root-table C-h/j/k/l).
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left pane" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower pane" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper pane" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right pane" },
  },
}
