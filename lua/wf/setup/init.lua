local extend = require("wf.util").extend
local full_name = require("wf.static").full_name
local sign_group_prompt = require("wf.static").sign_group_prompt

-- @param ground string "fg" or "bg"
local function get_hl(tbl, name, ground)
  local _ground = vim.fn.synIDattr(vim.fn.hlID(name), ground, "gui")
  if _ground ~= "" then
    tbl[ground] = _ground
  end
  return tbl
end

local function rev(name)
  local tbl = { default = true }
  local bg = vim.fn.synIDattr(vim.fn.hlID("NormalFloat"), "bg#", "gui")
  local fg = vim.fn.synIDattr(vim.fn.hlID(name), "fg#", "gui")
  if bg ~= "" then
    tbl["fg"] = bg
  end
  if fg ~= "" then
    tbl["bg"] = fg
  end
  return tbl
end

local themes = {
  chad = {
    highlight = {
      WFNornal = "NormalFloat",
      WFComment = (function()
        local tbl = { default = true }
        tbl = get_hl(tbl, "Comment", "fg")
        tbl = get_hl(tbl, "NormalFloat", "bg")
        return tbl
      end)(),
      -- WFFloatBorder = (function()
      --   local tbl = { default = true }
      --   tbl = get_hl(tbl, "FloatBorder", "fg")
      --   tbl = get_hl(tbl, "NormalFloat", "bg")
      --   return tbl
      -- end)(),
      WFFloatBorder = "NormalFloat",
      WFFloatBorderFocus = "Normal",
      WFWhichRem = "Comment",
      WFWhichOn = "Keyword",
      WFFuzzy = "String",
      WFFuzzyPrompt = "Error",
      WFFocus = "Normal",
      WFFreeze = "Comment",
      WFWhichObjCounter = "Comment",
      WFWhichDesc = "Normal",
      WFSeparator = "Comment",
      WFGroup = "Function",
      WFWhichUnique = rev("Keyword"), -- opts.behavior.shortest_match
      WFExpandable = "Type",
      WFTitleOutputWhich = rev("Function"),
      WFTitleOutputFuzzy = rev("String"),
      WFTitleWhich = rev("Keyword"),
      WFTitleFuzzy = rev("Error"),
      WFTitleFreeze = "WFFreeze",
    },
  },
  default = {
    highlight = {
      WFNormal = "Normal",
      WFFloatBorder = "FloatBorder",
      WFFloatBorderFocus = "FloatBorder",
      WFComment = "Comment",
      WFWhichRem = "Comment",
      WFWhichOn = "Keyword",
      WFFuzzy = "String",
      WFFuzzyPrompt = "Error",
      WFFocus = "WFNormal",
      WFFreeze = "Comment",
      WFWhichObjCounter = "NonText",
      WFWhichDesc = "Normal",
      WFSeparator = "Comment",
      WFGroup = "Function",
      WFWhichUnique = "Type",
      WFExpandable = "Type",
      WFTitleOutput = "Title",
      WFTitleWhich = "Title",
      WFTitleFuzzy = "Title",
      WFTitleFreeze = "WFFreeze",
    },
  },
  space = {
    highlight = {
      WFFloatBorder = "FloatBorder",
      WFFloatBorderFocus = "FloatBorder",
      WFNormal = "Normal",
      WFComment = "Comment",
      WFWhichRem = "Comment",
      WFWhichOn = "Keyword",
      WFFuzzy = "String",
      WFFuzzyPrompt = "Error",
      WFFocus = "WFNormal",
      WFFreeze = "Comment",
      WFWhichObjCounter = "NonText",
      WFWhichDesc = "Normal",
      WFSeparator = "FloatBorder",
      WFGroup = "Function",
      WFWhichUnique = "Type",
      WFExpandable = "Type",
      WFTitleOutput = "Title",
      WFTitleWhich = "Title",
      WFTitleFuzzy = "Title",
      WFTitleFreeze = "WFFreeze",
    },
  },
}

local function timeout(ms callback)
  local uv = vim.loop
  local timer = uv.new_timer()
  local callback = vim.schedule_wrap(
    function()
      uv.timer_stop(timer)
      uv.close(timer)
      callback()
    end
    )
  uv.timer_start(timer, ms, 0, callback)
end

---@param mode string|table
---@lhs string
---@rhs string|function
---@opts table
local function nowait_keymap_set(param, lhs, rhs, opts)
  if vim.g["wf_nowait_keymaps"] == nil then
    vim.g["wf_nowait_keymaps"] = {}
  end
  opts["nowait"] = true
  local map = function()
    vim.keymap.set(praram, lhs, rhs, opts)
  end
  local bmap = function()
    opts["buffer"] = true
    vim.keymap.set(param, lhs, rhs, opts)
  end
  vim.g["wf_nowait_keymaps"][lhs] = { map = map, bmap = bmap }
end

---@param opts table
local function setup(opts)
  opts = opts or { theme = "default" }
  opts.highlight = opts["highlight"] or themes[opts["theme"] or "default"].highlight

  for k, v in pairs(opts.highlight) do
    if type(v) == "string" then
      vim.api.nvim_set_hl(0, k, { default = true, link = v })
    elseif type(v) == "table" then
      vim.api.nvim_set_hl(0, k, v)
    end
  end
  vim.g[full_name .. "#theme"] = opts.theme

  timeout(100, function()
    for _, v in pairs(vim.api.nvim_eval("g:wf_nowait_keymaps")) do
      v.map()
    end
  end)
  vim.api.nvim_create_autocmd({"BufEnter", "BufAdd" }, {
    group = vim.api.nvim_create_augroup("wf_nowait_keymaps", { clear = true }),
    callback = function()
      timeout(100, function()
        for _, v in pairs(vim.api.nvim_eval("g:wf_nowait_keymaps")) do
          v.bmap()
        end
      end)
    end
    })

end

return { setup = setup, nowait_keymap_set = nowait_keymap_set }
