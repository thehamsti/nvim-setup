return {
  {
    "hamstillm",
    dir = "~/projects/hamstillm.nvim",
    dev = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local system_prompt =
        "You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks"
      local helpful_prompt = "You are a helpful assistant. What I have sent are my notes so far."
      local hamstillm = require "hamstillm"

      local function handle_open_router_spec_data(data_stream)
        local success, json = pcall(vim.json.decode, data_stream)
        if success then
          if json.choices and json.choices[1] and json.choices[1].text then
            local content = json.choices[1].text
            if content then
              hamstillm.write_string_at_cursor(content)
            end
          end
        else
          print("non json " .. data_stream)
        end
      end

      local function custom_make_openai_spec_curl_args(opts, prompt)
        local url = opts.url
        local api_key = opts.api_key_name and os.getenv(opts.api_key_name)
        local data = {
          prompt = prompt,
          model = opts.model,
          temperature = 0.7,
          stream = true,
        }
        local args = { "-N", "-X", "POST", "-H", "Content-Type: application/json", "-d", vim.json.encode(data) }
        if api_key then
          table.insert(args, "-H")
          table.insert(args, "Authorization: Bearer " .. api_key)
        end
        table.insert(args, url)
        return args
      end

      local function custom_make_ollama_spec_curl_args(opts, prompt)
        local url = opts.url
        local data = {
          prompt = prompt,
          model = opts.model,
        }
        local args = { "-N", "-X", "POST", "-H", "Content-Type: application/json", "-d", vim.json.encode(data) }
        table.insert(args, url)
        return args
      end

      local function ollama_help()
        hamstillm.invoke_llm_and_stream_into_editor({
            url = "http://localhost:11434/api/generate",
            model = "llama3.1:latest",
            system_prompt = system_prompt,
        }, custom_make_ollama_spec_curl_args, handle_open_router_spec_data)
      end

      local function llama_405b_base()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://openrouter.ai/api/v1/chat/completions",
          model = "meta-llama/llama-3.1-405b",
          api_key_name = "OPEN_ROUTER_API_KEY",
          max_tokens = "128",
          replace = false,
        }, custom_make_openai_spec_curl_args, handle_open_router_spec_data)
      end

      local function groq_replace()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.groq.com/openai/v1/chat/completions",
          model = "llama-3.1-70b-versatile",
          api_key_name = "GROQ_API_KEY",
          system_prompt = system_prompt,
          replace = true,
        }, hamstillm.make_openai_spec_curl_args, hamstillm.handle_openai_spec_data)
      end

      local function groq_help()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.groq.com/openai/v1/chat/completions",
          model = "llama-3.1-70b-versatile",
          api_key_name = "GROQ_API_KEY",
          system_prompt = helpful_prompt,
          replace = false,
        }, hamstillm.make_openai_spec_curl_args, hamstillm.handle_openai_spec_data)
      end

      local function llama405b_replace()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.lambdalabs.com/v1/chat/completions",
          model = "hermes-3-llama-3.1-405b-fp8",
          api_key_name = "LAMBDA_API_KEY",
          system_prompt = system_prompt,
          replace = true,
        }, hamstillm.make_openai_spec_curl_args, hamstillm.handle_openai_spec_data)
      end

      local function llama405b_help()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.lambdalabs.com/v1/chat/completions",
          model = "hermes-3-llama-3.1-405b-fp8",
          api_key_name = "LAMBDA_API_KEY",
          system_prompt = helpful_prompt,
          replace = false,
        }, hamstillm.make_openai_spec_curl_args, hamstillm.handle_openai_spec_data)
      end

      local function anthropic_help()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.anthropic.com/v1/messages",
          model = "claude-3-5-sonnet-20240620",
          api_key_name = "ANTHROPIC_API_KEY",
          system_prompt = helpful_prompt,
          replace = false,
        }, hamstillm.make_anthropic_spec_curl_args, hamstillm.handle_anthropic_spec_data)
      end

      local function anthropic_replace()
        hamstillm.invoke_llm_and_stream_into_editor({
          url = "https://api.anthropic.com/v1/messages",
          model = "claude-3-5-sonnet-20240620",
          api_key_name = "ANTHROPIC_API_KEY",
          system_prompt = system_prompt,
          replace = true,
        }, hamstillm.make_anthropic_spec_curl_args, hamstillm.handle_anthropic_spec_data)
      end

      -- What are you?
      vim.keymap.set({ "n", "v" }, "<leader>ht", ollama_help, { desc = "llm ollama" })
      vim.keymap.set({ "n", "v" }, "<leader>hf", groq_replace, { desc = "llm groq" })
      vim.keymap.set({ "n", "v" }, "<leader>hF", groq_help, { desc = "llm groq_help" })
      vim.keymap.set({ "n", "v" }, "<leader>hr", llama405b_help, { desc = "llm llama405b_help" })
      vim.keymap.set({ "n", "v" }, "<leader>hR", llama405b_replace, { desc = "llm llama405b_replace" })
      vim.keymap.set({ "n", "v" }, "<leader>hh", anthropic_help, { desc = "llm anthropic_help" })
      vim.keymap.set({ "n", "v" }, "<leader>hH", anthropic_replace, { desc = "llm anthropic" })
      vim.keymap.set({ "n", "v" }, "<leader>hj", llama_405b_base, { desc = "llama base" })
    end,
  },
  --   {
  --     "David-Kunz/gen.nvim",
  --     opts = {
  --       model = "llama3", -- The default model to use.
  --       host = "localhost", -- The host running the Ollama service.
  --       port = "11434", -- The port on which the Ollama service is listening.
  --       quit_map = "q", -- set keymap for close the response window
  --       retry_map = "<c-r>", -- set keymap to re-send the current prompt
  --       init = function(options)
  --         pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
  --       end,
  --       -- Function to initialize Ollama
  --       command = function(options)
  --         local body = { model = options.model, stream = true }
  --         return "curl --silent --no-buffer -X POST http://"
  --           .. options.host
  --           .. ":"
  --           .. options.port
  --           .. "/api/chat -d $body"
  --       end,
  --       -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
  --       -- This can also be a command string.
  --       -- The executed command must return a JSON object with { response, context }
  --       -- (context property is optional).
  --       -- list_models = '<omitted lua function>', -- Retrieves a list of model names
  --       display_mode = "float", -- The display mode. Can be "float" or "split".
  --       show_prompt = false, -- Shows the prompt submitted to Ollama.
  --       show_model = false, -- Displays which model you are using at the beginning of your chat session.
  --       no_auto_close = false, -- Never closes the window automatically.
  --       debug = false, -- Prints errors and the command which is run.
  --     },
  --   },
}
