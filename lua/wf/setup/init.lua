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

  vim.fn.sign_define(sign_group_prompt .. "fuzzy", {
    text = ">", -- opts.style.icons.fuzzy_prompt,
    texthl = "WFFuzzyPrompt",
  })
  vim.fn.sign_define(sign_group_prompt .. "which", {
    text = ">", -- opts.style.icons.which_prompt,
    texthl = "WFWhich",
  })
  vim.fn.sign_define(sign_group_prompt .. "fuzzyfreeze", {
    text = ">", -- opts.style.icons.fuzzy_prompt,
    texthl = "WFFreeze",
  })
  vim.fn.sign_define(sign_group_prompt .. "whichfreeze", {
    text = ">", -- opts.style.icons.which_prompt,
    texthl = "WFFreeze",
  })
end

return { setup = setup }
