return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Function to read Claude Code OAuth token
      local function get_claude_token()
        local credentials_file = vim.fn.expand("~/.claude/.credentials.json")
        local file = io.open(credentials_file, "r")
        if not file then
          vim.notify("Claude Code credentials not found. Please run: claude auth", vim.log.levels.ERROR)
          return nil
        end

        local content = file:read("*all")
        file:close()

        local ok, credentials = pcall(vim.json.decode, content)
        if ok and credentials.claudeAiOauth and credentials.claudeAiOauth.accessToken then
          return credentials.claudeAiOauth.accessToken
        end

        return nil
      end

      local token = get_claude_token()
      if not token then
        return -- Exit if no token available
      end

      require("minuet").setup({
        provider = "claude",
        provider_options = {
          claude = {
            model = "claude-sonnet-4-5-20250929", -- Using Claude Sonnet 4.5
            max_tokens = 512,
            stream = true,
            api_key = token, -- Use Claude Code's OAuth token
            end_point = "https://api.anthropic.com/v1/messages",
            optional = {
              -- Additional Claude parameters can be added here
            },
          },
        },
        -- General settings
        request_timeout = 3, -- seconds
        throttle = 1000, -- milliseconds between requests
        debounce = 400, -- milliseconds to wait before triggering
        -- Context window for Claude
        context_window = 12288, -- ~12K tokens
        n_completions = 1, -- Number of completion variants
      })
    end,
  },

  -- Configure blink.cmp to use minuet as a source
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000, -- Match request_timeout * 1000
            score_offset = 50, -- Higher priority for AI suggestions
          },
        },
      },
      completion = {
        -- Avoid unnecessary API calls
        trigger = {
          prefetch_on_insert = false,
        },
      },
    },
  },
}
