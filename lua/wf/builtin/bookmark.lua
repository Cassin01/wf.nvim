local select = require("wf").select
local gen_highlight = require("wf.util").gen_highlight

local function require_deviocon()
  return require("nvim-web-devicons")
end

local ok, devicon = pcall(require_deviocon)

---@tag builtin.bookmark
---@param bookmark_dirs table
---@usage bookmark({nvim="~/.config/nvim", zsh="~/.zshrc"})
---@param opts? WFOptions
local function bookmark(bookmark_dirs, opts)
  local function _bookmark()
    opts = opts or {}
    local _opts = {
      title = "Bookmark",
      behavior = {
        skip_front_duplication = true,
        skip_back_duplication = true,
      },
      output_obj_which_mode_desc_format = function(match_obj)
        local desc = match_obj.text
        if ok then
          if match_obj.type == "group" then
            return { { desc, "WFWhichDesc" }, { " +", "WFExpandable" } }
          else
            local icon, color = devicon.get_icon_color(desc)
            if icon ~= nil then
              local name = gen_highlight(desc, color)
              local sp = vim.fn.strwidth(icon) > 1 and (icon .. "") or (icon .. " ")
              return { { sp .. " ", name }, { desc, "WFWhichDesc" } }
            else
              return { { "  ", "Directory" }, { desc, "WFWhichDesc" } }
            end
          end
        else
          if match_obj.type == "group" then
            return { { desc, "WFWhichDesc" }, { " +", "WFExpandable" } }
          else
            return { { desc, "WFWhichDesc" } }
          end
        end
      end,
    }
    for k, v in pairs(opts) do
      _opts[k] = v
    end

    select(bookmark_dirs, _opts, function(path_, _)
      local path = vim.fn.expand(path_)
      if vim.fn.isdirectory(path) ~= 0 then
        if vim.fn.exists(":Telescope") then
          require("telescope").extensions.file_browser.file_browser({
            path = path_,
            depth = 4,
          })
          return
        elseif vim.fn.exists(":CtrlP") then
          local command = "CtrlP " .. path
          vim.cmd(command)
          return
        elseif vim.g.loaded_netrwPlugin == 0 and vim.g.loaded_netrw == 0 then
          local command = "e " .. path
          vim.cmd(command)
          return
        else
          print("not matched")
        end
      elseif vim.fn.filereadable(path) ~= 0 then
        local command = "vi " .. path
        vim.cmd(command)
        return
      else
        print("The file/dir does not found")
      end
    end)
  end

  return _bookmark
end

return bookmark
