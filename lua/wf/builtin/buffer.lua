local select = require("wf").select
local gen_highlight = require("wf.util").gen_highlight

local function require_deviocon()
  return require("nvim-web-devicons")
end

local ok, devicon = pcall(require_deviocon)

local function get_active_buffers()
  local blist = vim.fn.getbufinfo({ bufloaded = 1, buflisted = 1 })
  local res = {}
  local bs = {}
  for _, b in ipairs(blist) do
    if vim.fn.empty(b.name) == 0 then -- or b.hidden ~= 0 then
      res[b.bufnr] = b.name
      bs[b.bufnr] = b
    end
  end
  return res, bs
end

---@tag builtin.buffer
---@param opts? WFOptions
local function buffer(opts)
  local function _buffer()
    local choices, bs = get_active_buffers()
    local current_buf = vim.api.nvim_get_current_buf()
    local _opts = {
      title = "Buffer",
      behavior = {
        skip_front_duplication = true,
        skip_back_duplication = true,
      },
      style = {
        width = vim.o.columns,
      },
      prefix_size = 3,
      output_obj_which_mode_desc_format = function(match_obj)
        local desc = match_obj.text
        local id = match_obj.id
        local bufinfo = bs[id]
        if bufinfo ~= nil and bufinfo.variables["terminal_job_id"] ~= nil then
          return { { "  ", "Identifier" }, { desc, "WFWhichDesc" } }
        end
        local hldesc = bufinfo.changed == 1 and "String" or "WFWhichDesc"
        local function fnamemodify(fname)
          return vim.fn.fnamemodify(fname, ":.")
        end
        if id == current_buf then
          return { { "  ", "Identifier" }, { fnamemodify(desc), hldesc } }
        end
        if ok then
          local icon, color = devicon.get_icon_color(desc)
          if icon ~= nil then
            local sp = vim.fn.strwidth(icon) > 1 and (icon .. "") or (icon .. " ")
            return { { sp .. " ", gen_highlight(desc, color) }, { fnamemodify(desc), hldesc } }
          else
            return { { "  ", "Identifier" }, { fnamemodify(desc), hldesc } }
          end
        else
          return { { fnamemodify(desc), hldesc } }
        end
      end,
    }
    opts = opts or {}
    for k, v in pairs(opts) do
      _opts[k] = v
    end
    if table.maxn(choices) == 0 then
      vim.api.nvim_echo({
        { "No buffers to switch to.", "ErrorMsg" },
        { " @wf.builtin.buffer", "Comment" },
      }, false, {})
      return
    end
    select(choices, _opts, function(_, lhs)
      if vim.fn.bufexists(lhs) ~= 0 then
        vim.api.nvim_set_current_buf(tonumber(lhs))
      end
    end)
  end

  return _buffer
end

return buffer
