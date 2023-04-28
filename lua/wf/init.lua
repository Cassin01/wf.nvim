-- MIT License Copyright (c) 2022 Cassin01

-- Documentation ==============================================================
--- A modern which-key for neovim
---
--- # Getting started~
---
--- Getting started with wf.nvim:
---  1. Put a `require('wf').setup()` call somewhere in your neovim config.
---  2. Read |wf.setup| to check what config keys are aviable and what you can put
---     inside the setup call
---  3. Read |wf.builtin| to check which builtin pickers are offered and what
---     options these implement
---  4. Profit
---
--- # Keymapping~
---
--- The default key assignments are shown in the table below.
---
--- tag	char	action
--- *i_CTRL-T*	CTRL-T	Toggle the which-key with fuzzy-finder
--- *n_CTRL-T*	CTRL-T	Toggle the which-key with fuzzy-finder
--- *n_<ESC>*	<ESC>	Quit wf.nvim
--- *n_CTRL-C*	CTRL-C	Quit wf.nvim
---
---@tag wf.nvim

local util = require("wf.util")
local au = util.au
local rt = util.rt
local get_mode = util.get_mode
local async = util.async
local ingect_deeply = util.ingect_deeply
local match_from_tail = util.match_from_tail
local fuzzy = require("wf.fuzzy")
local which = require("wf.which")
local output_obj_gen = require("wf.output").output_obj_gen
local static = require("wf.static")
local bmap = static.bmap
local row_offset = static.row_offset
local full_name = static.full_name
local augname_leave_check = static.augname_leave_check
local _g = static._g
local sign_group_prompt = static.sign_group_prompt
local cell = require("wf.cell")
local which_insert_map = require("wf.which_map").setup
local group = require("wf.group")
local core = require("wf.core").core
local setup = require("wf.setup")
local input = require("wf.input").input

-- if cursor not on the objects then quit wf.
local lg = vim.api.nvim_create_augroup(augname_leave_check, { clear = true })
local function leave_check(which_obj, fuzzy_obj, output_obj, del)
  pcall(
    au,
    lg,
    "WinEnter",
    vim.schedule_wrap(function()
      local current_win = vim.api.nvim_get_current_win()
      for _, obj in ipairs({ fuzzy_obj, which_obj, output_obj }) do
        if current_win == obj.win then
          leave_check(fuzzy_obj, which_obj, output_obj, del)
          return
        end
      end
      return del()
    end),
    { once = true }
  )
end

local function objs_setup(fuzzy_obj, which_obj, output_obj, caller_obj, choices_obj, callback)
  local objs = { fuzzy_obj, which_obj, output_obj }
  local del = function(callback_) -- deliminator of the whole process
    vim.schedule(function()
      -- autocommands contained in this group will also be deleted and cleared
      vim.api.nvim_del_augroup_by_name(augname_leave_check)
      -- restore only the autogroup
      lg = vim.api.nvim_create_augroup(augname_leave_check, { clear = true })
    end)
    if caller_obj.mode == "n" then
      if callback_ ~= nil then
        au(
          vim.api.nvim_create_augroup("WFCallbackModeChanged", { clear = true }),
          "ModeChanged",
          callback_,
          { once = true, pattern = "*:n" }
        )
      end
      vim.schedule(function() -- これがないと謎modeに入ってしまう。
        vim.cmd("stopinsert")
      end)
    end

    vim.schedule(function()
      local cursor_valid, original_cursor = pcall(vim.api.nvim_win_get_cursor, caller_obj.win)
      if vim.api.nvim_win_is_valid(caller_obj.win) then
        vim.api.nvim_set_current_win(caller_obj.win)
        vim.api.nvim_win_set_cursor(caller_obj.win, { original_cursor[1], original_cursor[2] })
        -- pcall(vim.api.nvim_set_current_win, caller_obj.win)
        -- pcall(
        --     vim.api.nvim_win_set_cursor,
        --     caller_obj.win,
        --     { original_cursor[1], original_cursor[2] }
        --     )

        -- if
        --     cursor_valid
        --     and vim.api.nvim_get_mode().mode == "i"
        --     and caller_obj.mode ~= "i"
        -- then
        --     print("original cursor")
        --     print(vim.inspect(original_cursor))
        --     print("current cursor")
        --     print(vim.inspect(vim.api.nvim_win_get_cursor(0)))
        --     pcall(
        --         vim.api.nvim_win_set_cursor,
        --         caller_obj.win,
        --         { original_cursor[1], original_cursor[2] }
        --     )
        -- end
      end
      for _, o in ipairs(objs) do
        if vim.api.nvim_buf_is_valid(o.buf) then
          -- vim.api.nvim_set_current_win(o.win)
          vim.api.nvim_buf_delete(o.buf, { force = true })
        end
        if vim.api.nvim_win_is_valid(o.win) then
          vim.api.nvim_win_close(o.win, true)
        end
      end
    end)
  end

  -- for _, o in ipairs(objs) do
  --   au(_g, "BufWinLeave", function()
  --     del()
  --   end, { buffer = o.buf })
  -- end

  local to_which = function()
    vim.api.nvim_set_current_win(which_obj.win)
  end
  local to_fuzzy = function()
    vim.api.nvim_set_current_win(fuzzy_obj.win)
  end

  local which_key_list_operator = {
    escape = "<C-C>",
    toggle = "<C-T>",
  }
  for _, o in ipairs(objs) do
    bmap(o.buf, "n", "<esc>", del, "quit")
  end
  local inputs = { fuzzy_obj, which_obj }
  for _, o in ipairs(inputs) do
    bmap(o.buf, { "i", "n" }, which_key_list_operator.escape, del, "quit")
    bmap(o.buf, { "n" }, "m", "", "disable sign")
  end
  bmap(
    fuzzy_obj.buf,
    { "i", "n" },
    which_key_list_operator.toggle,
    to_which,
    "start which key mode"
  )
  bmap(
    which_obj.buf,
    { "i", "n" },
    which_key_list_operator.toggle,
    to_fuzzy,
    "start which key mode"
  )

  -- If `[` is mapped at buffer with `no wait`, sometimes `<C-[>` is ignored and neovim regard as `[`.
  -- So we need to map `<C-[>` to `<C-[>` at buffer with `no wait`.
  vim.api.nvim_buf_set_keymap(
    which_obj.buf,
    "i",
    "<C-[>",
    "<ESC>",
    { noremap = true, silent = true, desc = "Normal mode" }
  )

  local which_map_list = which_insert_map(
    which_obj.buf,
    { which_key_list_operator.toggle, which_key_list_operator.escape }
  )
  local select_ = function()
    local fuzzy_line = vim.api.nvim_buf_get_lines(fuzzy_obj.buf, 0, -1, true)[1]
    local which_line = vim.api.nvim_buf_get_lines(which_obj.buf, 0, -1, true)[1]
    local fuzzy_matched_obj = (function()
      if fuzzy_line == "" then
        return choices_obj
      else
        return vim.fn.matchfuzzy(choices_obj, fuzzy_line, { key = "text" })
      end
    end)()
    for _, match in ipairs(fuzzy_matched_obj) do
      if match.key == which_line then
        del()
        callback(match.id, match.text)
        return
      end
    end
  end
  bmap(which_obj.buf, { "n", "i" }, "<CR>", select_, "select matched which key")
  bmap(fuzzy_obj.buf, { "n", "i" }, "<CR>", select_, "select matched which key")
  return { del = del, which_map_list = which_map_list }
end

local function swap_win_pos(up, down, style)
  local height = 1
  local row = vim.o.lines - height - row_offset() - 1

  local cnf_up = vim.api.nvim_win_get_config(up.win)
  vim.api.nvim_win_set_config(
    up.win,
    vim.fn.extend(
      cnf_up,
      (function()
        if vim.v.version < 800 then
          return {
            row = row - style.input_win_row_offset,
            border = style.borderchars.center,
          }
        else
          return {
            row = row - style.input_win_row_offset,
            border = style.borderchars.center,
            title_pos = "center",
            title = { { up.name, up.name == " Which Key " and "WFTitleWhich" or "WFTitleFuzzy" } },
          }
        end
      end)()
    )
  )

  local cnf_down = vim.api.nvim_win_get_config(down.win)
  vim.api.nvim_win_set_config(
    down.win,
    vim.fn.extend(
      cnf_down,
      (function()
        if vim.v.version < 800 then
          return {
            row = row,
            border = style.borderchars.bottom,
          }
        else
          return {
            row = row,
            border = style.borderchars.bottom,
            title_pos = "center",
            title = { { down.name, "WFTitleFreeze" } },
          }
        end
      end)()
    )
  )

  for _, o in ipairs({ up, down }) do
    vim.api.nvim_win_set_option(o.win, "foldcolumn", "1")
    --MARK: sign place {{{
    vim.api.nvim_win_set_option(o.win, "signcolumn", "yes:" .. tostring(vim.fn.strwidth(o.prompt)))
    -- vim.api.nvim_win_set_option(o.win, "signcolumn", "yes:2")
    --MARK: sign place }}}
  end
end

local function fuzzy_setup(which_obj, fuzzy_obj, output_obj, choices_obj, groups_obj, opts, cursor)
  local winenter = function()
    vim.api.nvim_win_set_option(
      fuzzy_obj.win,
      "winhl",
      "Normal:WFFocus,FloatBorder:WFFloatBorderFocus"
    )

    vim.fn.sign_unplace(sign_group_prompt .. "fuzzyfreeze", { buffer = fuzzy_obj.buf })

    -- MARK: sign place {{{
    vim.fn.sign_place(
      0,
      sign_group_prompt .. "fuzzy",
      sign_group_prompt .. "fuzzy",
      fuzzy_obj.buf,
      { lnum = 1, priority = 10 }
    )
    -- MARK: sign place }}}

    -- vim.schedule(function()
    --     vim.api.nvim_win_set_option(fuzzy_obj.win, "foldcolumn", "1")
    --     vim.api.nvim_win_set_option(fuzzy_obj.win, "signcolumn", "yes:2")
    -- end)

    local wcnf = vim.api.nvim_win_get_config(output_obj.win)
    vim.api.nvim_win_set_config(
      output_obj.win,
      vim.fn.extend(wcnf, {
        title = (function()
          if opts.title ~= nil then
            return { { " " .. opts.title .. " ", "WFTitleOutputFuzzy" } }
          else
            return opts.style.borderchars.top[2]
          end
        end)(),
      })
    )

    core(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
    -- run(core)(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
    swap_win_pos(fuzzy_obj, which_obj, opts.style)
  end
  if cursor then
    vim.schedule(function()
      winenter()

      -- MARK: sign place {{{
      vim.fn.sign_place(
        0,
        sign_group_prompt .. "whichfreeze",
        sign_group_prompt .. "whichfreeze",
        which_obj.buf,
        { lnum = 1, priority = 10 }
      )
      -- MARK: sign place }}}
      local _, _ = pcall(function()
        require("cmp").setup.buffer({ enabled = false })
      end)
    end)
  end
  au(_g, { "TextChangedI", "TextChanged" }, function()
    core(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
    -- run(core)(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
  end, { buffer = fuzzy_obj.buf })
  au(_g, "WinEnter", winenter, { buffer = fuzzy_obj.buf })
  au(_g, "WinLeave", function()
    vim.fn.sign_unplace(sign_group_prompt .. "fuzzyfreeze", { buffer = fuzzy_obj.buf })
    vim.fn.sign_unplace(sign_group_prompt .. "fuzzy", { buffer = fuzzy_obj.buf })
    -- MARK: sign place {{{
    vim.fn.sign_place(
      0,
      sign_group_prompt .. "fuzzyfreeze",
      sign_group_prompt .. "fuzzyfreeze",
      fuzzy_obj.buf,
      { lnum = 1, priority = 10 }
    )
    -- MARK: sign place }}}
    vim.api.nvim_win_set_option(
      fuzzy_obj.win,
      "winhl",
      "Normal:WFComment,FloatBorder:WFFloatBorder"
    )
  end, { buffer = fuzzy_obj.buf })
end

local function which_setup(
  which_obj,
  fuzzy_obj,
  output_obj,
  choices_obj,
  groups_obj,
  callback,
  obj_handlers,
  opts,
  cursor
)
  local winenter = function()
    vim.api.nvim_set_hl(0, "WFWhich", { link = "WFWhichOn" })

    vim.api.nvim_win_set_option(
      which_obj.win,
      "winhl",
      "Normal:WFFocus,FloatBorder:WFFloatBorderFocus"
    )
    -- MARK: sign place {{{
    vim.fn.sign_place(
      0,
      sign_group_prompt .. "which",
      sign_group_prompt .. "which",
      which_obj.buf,
      { lnum = 1, priority = 10 }
    )
    -- MARK: sign place }}}

    -- vim.schedule(function()
    --     vim.api.nvim_win_set_option(which_obj.win, "foldcolumn", "1")
    --     vim.api.nvim_win_set_option(which_obj.win, "signcolumn", "yes:2")
    -- end)
    local wcnf = vim.api.nvim_win_get_config(output_obj.win)
    vim.api.nvim_win_set_config(
      output_obj.win,
      vim.fn.extend(wcnf, {
        title = (function()
          if vim.v.version < 801 then
            return nil
          elseif opts.title ~= nil then
            return { { " " .. opts.title .. " ", "WFTitleOutputWhich" } }
          else
            return opts.style.borderchars.top[2]
          end
        end)(),
      })
    )
    core(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
    swap_win_pos(which_obj, fuzzy_obj, opts.style)
  end
  if cursor then
    vim.schedule(function()
      winenter()
      -- MARK: sign place {{{
      vim.fn.sign_place(
        0,
        sign_group_prompt .. "fuzzyfreeze",
        sign_group_prompt .. "fuzzyfreeze",
        fuzzy_obj.buf,
        { lnum = 1, priority = 10 }
      )
      -- MARK: sign place }}}
      local _, _ = pcall(function()
        require("cmp").setup.buffer({ enabled = false })
      end)
    end)
  end
  au(_g, "BufEnter", function()
    vim.fn.sign_unplace(sign_group_prompt .. "whichfreeze", { buffer = which_obj.buf })
    local _, _ = pcall(function()
      require("cmp").setup.buffer({ enabled = false })
    end)
  end, { buffer = which_obj.buf })
  au(_g, "WinLeave", function()
    vim.api.nvim_set_hl(0, "WFWhich", { link = "WFFreeze" })

    vim.fn.sign_unplace(sign_group_prompt .. "which", { buffer = which_obj.buf })
    -- MARK: sign place {{{
    vim.fn.sign_place(
      0,
      sign_group_prompt .. "whichfreeze",
      sign_group_prompt .. "whichfreeze",
      which_obj.buf,
      { lnum = 1, priority = 10 }
    )
    -- MARK: sign place }}}
    vim.api.nvim_win_set_option(
      which_obj.win,
      "winhl",
      "Normal:WFComment,FloatBorder:WFFloatBorder"
    )
  end, { buffer = which_obj.buf })
  au(
    _g,
    { "TextChangedI", "TextChanged" },
    vim.schedule_wrap(function()
      -- print("TextChangedI")
      -- print(vim.inspect(vim.api.nvim_get_mode()))
      -- print(vim.api.nvim_buf_get_lines(which_obj.buf, 0, -1, true)[1], "huga")

      local id, text = core(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
      if id ~= nil then
        obj_handlers.del(function()
          callback(id, text)
        end)
        -- async(callback)(id, text)
      end
    end),
    { buffer = which_obj.buf }
  )
  au(_g, "WinEnter", winenter, { buffer = which_obj.buf })
  -- bmap(which_obj.buf, { "n", "i" }, "<CR>", function()
  --   local fuzzy_line = vim.api.nvim_buf_get_lines(fuzzy_obj.buf, 0, -1, true)[1]
  --   local which_line = vim.api.nvim_buf_get_lines(which_obj.buf, 0, -1, true)[1]
  --   local fuzzy_matched_obj = (function()
  --     if fuzzy_line == "" then
  --       return choices_obj
  --     else
  --       return vim.fn.matchfuzzy(choices_obj, fuzzy_line, { key = "text" })
  --     end
  --   end)()
  --   for _, match in ipairs(fuzzy_matched_obj) do
  --     if match.key == which_line then
  --       obj_handlers.del()
  --       callback(match.id)
  --       return
  --     end
  --   end
  -- end, "match")
  bmap(which_obj.buf, { "i" }, "<C-H>", function()
    local pos = vim.api.nvim_win_get_cursor(which_obj.win)
    local line = vim.api.nvim_buf_get_lines(which_obj.buf, pos[1] - 1, pos[1], true)[1]
    local front = string.sub(line, 1, pos[2])
    local match = (function()
      for _, v in ipairs(obj_handlers.which_map_list) do
        if match_from_tail(front, v) then
          return v
        end
      end
      return nil
    end)()
    if match == nil then
      return rt("<C-H>")
    else
      return rt("<Plug>(wf-erase-word)")
    end
  end, "<C-h>", { expr = true })
  bmap(which_obj.buf, { "i" }, "<Plug>(wf-erase-word)", function()
    local pos = vim.api.nvim_win_get_cursor(which_obj.win)
    local line = vim.api.nvim_buf_get_lines(which_obj.buf, pos[1] - 1, pos[1], true)[1]
    local front = string.sub(line, 1, pos[2])
    local match = (function()
      for _, v in ipairs(obj_handlers.which_map_list) do
        if match_from_tail(front, v) then
          return v
        end
      end
      return nil
    end)()
    local back = string.sub(line, pos[2] + 1)
    local new_front = string.sub(front, 1, #front - #match)
    vim.fn.sign_unplace(sign_group_prompt .. "which", { buffer = which_obj.buf })
    vim.api.nvim_buf_set_lines(which_obj.buf, pos[1] - 1, pos[1], true, { new_front .. back })
    vim.api.nvim_win_set_cursor(which_obj.win, { pos[1], vim.fn.strwidth(new_front) })
    -- MARK: sign place {{{
    vim.fn.sign_place(
      0,
      sign_group_prompt .. "which",
      sign_group_prompt .. "which",
      which_obj.buf,
      { lnum = 1, priority = 10 }
    )
    -- MARK: sign place }}}
  end, "<C-h>")
end

-- core
local function _callback(
  caller_obj,
  fuzzy_obj,
  which_obj,
  output_obj,
  choices_obj,
  groups_obj,
  callback,
  opts
)
  local obj_handlers =
    objs_setup(fuzzy_obj, which_obj, output_obj, caller_obj, choices_obj, callback)
  which_setup(
    which_obj,
    fuzzy_obj,
    output_obj,
    choices_obj,
    groups_obj,
    callback,
    obj_handlers,
    opts,
    opts.selector == "which"
  )
  fuzzy_setup(
    which_obj,
    fuzzy_obj,
    output_obj,
    choices_obj,
    groups_obj,
    opts,
    opts.selector == "fuzzy"
  )

  -- vim.api.nvim_buf_set_lines(which_obj.buf, 0, -1, true, { opts.text_insert_in_advance })
  -- local c = vim.g[full_name .. "#char_insert_in_advance"]
  -- if c ~= nil then
  --     vim.api.nvim_buf_set_lines(fuzzy_obj.buf, 0, -1, true, { opts.text_insert_in_advance .. c })
  -- else
  --     vim.g[full_name .. "#text_insert_in_advance"] = opts.text_insert_in_advance
  --     vim.g[full_name .. "#which_obj_buf"] = which_obj.buf
  -- end
  -- if opts.selector == "fuzzy" then
  --     vim.api.nvim_set_current_win(fuzzy_obj.win)
  --     -- vim.schedule(function()
  --         -- vim.cmd("startinsert!")
  --     -- end)
  -- elseif opts.selector == "which" then
  --     vim.api.nvim_set_current_win(which_obj.win)
  --     -- vim.schedule(function()
  --         -- vim.cmd("startinsert!")
  --     -- end)
  -- else
  --     print("selector must be fuzzy or which")
  --     obj_handlers.del()
  --     return
  -- end
  if opts.selector ~= "fuzzy" and opts.selector ~= "which" then
    print("selector must be fuzzy or which")
    obj_handlers.del()
    return
  end
  leave_check(which_obj, fuzzy_obj, output_obj, obj_handlers.del)
end

local function setup_objs(choices_obj, callback, opts_)
  local _opts = vim.deepcopy(require("wf.config"))
  local opts = ingect_deeply(_opts, opts_ or vim.emptydict())

  vim.fn.sign_define(sign_group_prompt .. "fuzzy", {
    text = opts.style.icons.fuzzy_prompt,
    texthl = "WFFuzzyPrompt",
  })
  vim.fn.sign_define(sign_group_prompt .. "which", {
    text = opts.style.icons.which_prompt,
    texthl = "WFWhich",
  })
  vim.fn.sign_define(sign_group_prompt .. "fuzzyfreeze", {
    text = opts.style.icons.fuzzy_prompt,
    texthl = "WFFreeze",
  })
  vim.fn.sign_define(sign_group_prompt .. "whichfreeze", {
    text = opts.style.icons.which_prompt,
    texthl = "WFFreeze",
  })

  local caller_obj = (function()
    local win = vim.api.nvim_get_current_win()
    return {
      win = win,
      buf = vim.api.nvim_get_current_buf(),
      cursor = vim.api.nvim_win_get_cursor(win),
      mode = get_mode(),
    }
  end)()

  -- store key group_obj in list
  local groups_obj = group.new(opts.key_group_dict)

  -- generate the buffer for output
  local output_obj = output_obj_gen(opts)

  -- generate the buffer for input
  local which_obj = which.input_obj_gen(opts, opts.selector == "which")
  local fuzzy_obj = fuzzy.input_obj_gen(opts, opts.selector == "fuzzy")
  vim.api.nvim_buf_set_lines(which_obj.buf, -2, -1, true, { opts.text_insert_in_advance })
  print("fuzzy buf name: ", vim.api.nvim_buf_get_name(fuzzy_obj.buf))

  vim.schedule(function()
    vim.cmd("startinsert!")
  end)

  _callback(caller_obj, fuzzy_obj, which_obj, output_obj, choices_obj, groups_obj, callback, opts)
end

---@tag wf.select
---@param items items
---@param opts WFOptions
---@param on_choice fun(string, table)|fun(num, table)
---@usage `require("wf").select(items, opts, on_choice)`
local function select(items, opts, on_choice)
  vim.validate({
    items = { items, "table", false },
    on_choice = { on_choice, "function", false },
  })
  opts = opts or {}

  local cells = false
  local choices = (function()
    local metatable = getmetatable(items)
    if metatable ~= nil and metatable["__type"] == "cells" then
      cells = true
      return items
    else
      local choices = {}
      for i, val in pairs(items) do
        table.insert(choices, cell.new(i, tostring(i), val, "key"))
      end
      return choices
    end
  end)()

  local on_choice_wraped = on_choice
  local callback = function(choice, text)
    if cells then
      on_choice_wraped(text, choice)
    elseif type(choice) == "string" and vim.fn.has_key(items, choice) then
      on_choice_wraped(items[choice], choice)
    elseif type(choice) == "number" and items[choice] ~= nil then
      on_choice_wraped(items[choice], choice)
    else
      print("invalid choice")
    end
  end
  setup_objs(choices, callback, opts)
end

return { select = select, setup = setup.setup }
