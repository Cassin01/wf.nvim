local static = require("wf.static")
local plug_name = static.plug_name
local row_offset_ = static.row_offset
local gen_obj = require("wf.common").gen_obj
local ns_wf_output_obj_which = vim.api.nvim_create_namespace("wf_output_obj_which")
local same_text = require("wf.skip_front_duplication")
local sign_group_prompt = require("wf.static").sign_group_prompt
local augname_skip_front_duplicate = static.augname_skip_front_duplicate

-- called by  update_output_obj
-- TODO: make this function Domain
local function set_highlight(buf, lines, opts, endup_obj, which_obj, fuzzy_obj, which_line)
  local ret = {}
  local current_buf = vim.api.nvim_get_current_buf()
  local prefix_size = opts.prefix_size
  vim.api.nvim_buf_clear_namespace(buf, ns_wf_output_obj_which, 0, -1)

  local heads = {}
  for l = 0, #lines - 1 do
    -- head
    local match_ = lines[l + 1]:sub(2, prefix_size + 1)
    local match = string.match(match_, "^<[%u%l%d%-@]+>") -- matches with <Space>, <CR>, etc
    table.insert(heads, match ~= nil and match or lines[l + 1]:sub(2, 2))
    local till = match ~= nil and #match or 1

    -- prefix
    table.insert(ret, function()
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_wf_output_obj_which,
        "WFWhichRem",
        l,
        1 + till,
        prefix_size + 1
        )
      end)

    -- separator
    table.insert(ret, function()
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_wf_output_obj_which,
        "WFSeparator",
        l,
        prefix_size + 4,
        prefix_size + 5
        )
      end)
  end

  -- skip duplications
  local duplication = false
  if opts.behavior.skip_front_duplication and current_buf == which_obj.buf then
    local subs = {}
    for _, line in ipairs(lines) do
      local sub = string.sub(line, 2, prefix_size + 1)
      table.insert(subs, sub)
    end
    local rest = same_text(subs)
    -- TMP: remove prefix_size dependencies
    -- if rest ~= "" and #rest < prefix_size then
    if rest ~= "" then
      duplication = true
      local function _add_rest(text)
        return function()
          vim.api.nvim_buf_set_lines(which_obj.buf, 0, -1, true, { text })
          vim.api.nvim_win_set_cursor(which_obj.win, { 1, vim.fn.strwidth(text) })
          -- MARK: sign place {{{
          vim.fn.sign_place(
            0,
            sign_group_prompt .. "which",
            sign_group_prompt .. "which",
            which_obj.buf,
            { lnum = 1, priority = 10 }
          )
          -- MARK: sign place }}}
        end
      end

      local cs = {}
      for l, _ in ipairs(lines) do
        -- c: decision
        local c = subs[l]:sub(1 + #rest, 1 + #rest)
        -- local ok, err = pcall(function()
        if c ~= "" then
          vim.api.nvim_buf_set_keymap(
            which_obj.buf,
            "i",
            c,
            "",
            { callback = _add_rest(which_line .. rest .. c) }
            )
          table.insert(cs, c)
        end
          -- end)
        -- if not ok then
          -- print("c: " .. c .. "|")
          -- print("Error: " .. err)
        -- end
        table.insert(ret, function()
          vim.api.nvim_buf_add_highlight(
            buf,
            ns_wf_output_obj_which,
            "WFWhichUnique",
            l - 1,
            1 + #rest,
            2 + #rest
            )
          end)
      end
      local g = vim.api.nvim_create_augroup(augname_skip_front_duplicate, { clear = true })
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        callback = function()
          for _, c in ipairs(cs) do
            vim.api.nvim_buf_del_keymap(which_obj.buf, "i", c)
          end
        end,
        once = true,
        buffer = which_obj.buf,
        group = g,
      })
    end
  end

  -- head
  if not duplication and current_buf == which_obj.buf then
    for l, head in ipairs(heads) do
      local is_unique = (function()
        for j, head_ in ipairs(heads) do
          if l ~= j and head == head_ then
            return false
          end
        end
        return true
      end)()
      if is_unique and endup_obj[l]["type"] == "key" and opts.behavior.skip_back_duplication then
        table.insert(ret, function()
          vim.api.nvim_buf_add_highlight(
            buf,
            ns_wf_output_obj_which,
            "WFWhichUnique",
            l - 1,
            1,
            1 + #head
            )
          end)
      else
        table.insert(ret, function()
          vim.api.nvim_buf_add_highlight(
            buf,
            ns_wf_output_obj_which,
            "WFWhichOn",
            l - 1,
            1,
            1 + #head
            )
          end)
      end
    end
  elseif duplication or current_buf == fuzzy_obj.buf then
    for l, head in ipairs(heads) do
      table.insert(ret, function()
        vim.api.nvim_buf_add_highlight(buf, ns_wf_output_obj_which, "WFWhichRem", l - 1, 1, 1 + #head)
      end)
    end
  end
  return ret
end

-- generate output object(buf and win)
local function output_obj_gen(opts)
  local style = opts.style
  local buf, win = gen_obj(
    row_offset_() + style.input_win_row_offset + style.input_win_row_offset,
    opts,
    false,
    "nofile",
    style.borderchars.top[2]
  )
  vim.api.nvim_buf_set_option(buf, "filetype", plug_name .. "output")
  local wcnf = vim.api.nvim_win_get_config(win)
  vim.api.nvim_win_set_config(
    win,
    vim.fn.extend(wcnf, {
      border = style.borderchars.top,
      -- title_pos = "center",
      -- title = style.borderchars.top[2],
    })
  )
  return { buf = buf, win = win }
end

local function update_output_obj(
  obj,
  choices,
  lines,
  row_offset,
  opts,
  endup_obj,
  which_obj,
  fuzzy_obj,
  which_line
)
  vim.api.nvim_buf_set_option(obj.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(obj.buf, 0, -1, true, choices)
  local cnf = vim.api.nvim_win_get_config(obj.win)
  local height = vim.api.nvim_buf_line_count(obj.buf)
  local row = lines - height - row_offset - 1
  local top_margin = 4
  if height > lines - row_offset + top_margin then
    height = lines - row_offset - 1 - top_margin
    row = 0 + top_margin
  end

  vim.api.nvim_win_set_config(
    obj.win,
    vim.fn.extend(cnf, { height = height, row = row })
    -- vim.fn.extend(cnf, { height = height, row = row, title_pos = "center" })
  )

  local tasks = set_highlight(obj.buf, choices, opts, endup_obj, which_obj, fuzzy_obj, which_line)

  for _, task in ipairs(tasks) do
    task()
  end


  vim.api.nvim_buf_set_option(obj.buf, "modifiable", false)
end

return { update_output_obj = update_output_obj, output_obj_gen = output_obj_gen }
