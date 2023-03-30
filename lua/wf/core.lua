local util = require("wf.util")
local rev = util.array_reverse
local match_from_front = util.match_from_front
local fill_spaces = util.fill_spaces
local group = require("wf.group")
local output_obj_which = require("wf.output_obj_which")
-- local update_output_obj = require("wf.output").update_output_obj
-- local set_highlight = require("wf.output").set_highlight
local prompt_counter_update = require("wf.prompt_counter").update
local ns_wf_output_obj_fuzzy = vim.api.nvim_create_namespace("wf_output_obj_fuzzy")

-- core filtering flow
local core = function(choices_obj, groups_obj, which_obj, fuzzy_obj, output_obj, opts)
  -- filter with fuzzy match
  local fuzzy_line = vim.api.nvim_buf_get_lines(fuzzy_obj.buf, 0, -1, true)[1]
  local matches_obj, poss = (function()
    if fuzzy_line == "" then
      return choices_obj
    else
      local obj = vim.fn.matchfuzzypos(choices_obj, fuzzy_line, { key = "text" })
      local poss = obj[2]
      return rev(obj[1]), rev(poss)
    end
  end)()

  -- filter with which key match
  local which_line = vim.api.nvim_buf_get_lines(which_obj.buf, 0, -1, true)[1]
  local which_matches_obj = (function()
    local obj = {}
    for lnum, match in ipairs(matches_obj) do
      if match_from_front(match.key, which_line) then
        match["lnum"] = lnum
        table.insert(obj, match)
      end
    end
    return obj
  end)()

  -- integrate groups
  local folded_obj = vim.api.nvim_get_current_buf() == which_obj.buf
      and group.integrate(which_matches_obj, groups_obj, #which_line)
    or which_matches_obj

  -- sorter
  local endup_obj = (function()
    if opts.sorter == nil then
      return folded_obj
    else
      return opts.sorter(folded_obj)
    end
  end)()

  -- return early  without drawing if determined
  -- when narrowed down to one, return it
  if
    which_line ~= ""
    and #endup_obj == 1
    and (opts.behavior.skip_back_duplication or endup_obj[1].key == which_line)
  then
    return endup_obj[1].id, endup_obj[1].text
  end

  -- take out info's
  local function meta_key(sub)
    if string.match(sub, "^<") == "<" then
      local till = sub:match("^<[%w%-]+>")
      if till ~= nil then
        return #till
      end
    end
    return vim.fn.strwidth(string.match(sub, "."))
  end

  -- local ids = {}
  local texts = {}
  local match_posses = {}
  for _, match in ipairs(endup_obj) do
    -- table.insert(ids, { id = match.id, key = match.key })
    local sub = string.sub(match.key, 1 + #which_line, opts.prefix_size + #which_line)

    local str = fill_spaces(sub == "" and "<CR>" or sub, opts.prefix_size)
    local desc = (function()
      if vim.api.nvim_get_current_buf() == which_obj.buf then
        return output_obj_which:add(
          output_obj.buf,
          #texts,
          opts.output_obj_which_mode_desc_format(match),
          opts.prefix_size + 6
        )
      else
        return match.text
      end
    end)()
    local text = string.format(" %s %s %s", str, opts.style.icons.separator, desc)

    table.insert(texts, text)

    local till_len = meta_key(sub)
    table.insert(match_posses, { match.lnum, till_len })
  end

  -- update output_obj
  local _row_offset = vim.o.cmdheight
    + (vim.o.laststatus > 0 and 1 or 0)
    + opts.style.input_win_row_offset

  -- update_output_obj {{{
  vim.api.nvim_buf_set_option(output_obj.buf, "modifiable", true)

  -- domain layer
  local hls = (function()
    local hls = {}
    local current_buf = vim.api.nvim_get_current_buf()
    local prefix_size = opts.prefix_size
    vim.api.nvim_buf_clear_namespace(buf, ns_wf_output_obj_which, 0, -1)

    local heads = {}
    for l = 0, #texts - 1 do
      -- head
      local match_ = texts[l + 1]:sub(2, prefix_size + 1)
      local match = string.match(match_, "^<[%u%l%d%-@]+>") -- matches with <Space>, <CR>, etc
      table.insert(heads, match ~= nil and match or texts[l + 1]:sub(2, 2))
      local till = match ~= nil and #match or 1

      -- prefix
      table.insert(hls, function()
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
      table.insert(hls, function()
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
      for _, line in ipairs(texts) do
        -- local sub = string.sub(line, 2, prefix_size + 1)
        local sub = string.sub(line, 2) -- FIXED
        table.insert(subs, sub)
      end
      local rest = same_text(subs)
      -- TMP: remove prefix_size dependencies
      -- if rest ~= "" and #rest < prefix_size then
      if rest ~= "" then -- FIXED
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
        for l, line in ipairs(texts) do
          -- c: decision
          local c = subs[l]:sub(1 + #rest, 1 + #rest)
          if c ~= "" then -- TODO: remove this, TMP: not to show the error
            vim.api.nvim_buf_set_keymap(
              which_obj.buf,
              "i",
              c,
              "",
              { callback = _add_rest(which_line .. rest .. c) }
            )
            table.insert(cs, c)
          end

          table.insert(hls, function()
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

    -- highlight heads
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
          table.insert(hls, function()
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
          table.insert(hls, function()
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
        table.insert(hls, function()
          vim.api.nvim_buf_add_highlight(
            buf,
            ns_wf_output_obj_which,
            "WFWhichRem",
            l - 1,
            1,
            1 + #head
          )
        end)
      end
    end
    return hls
  end)()
  -- local hls =
  --   set_highlight(output_obj.buf, texts, opts, endup_obj, which_obj, fuzzy_obj, which_line)

  -- application layer
  vim.api.nvim_buf_set_lines(output_obj.buf, 0, -1, true, texts)

  local height = vim.api.nvim_buf_line_count(output_obj.buf)
  local row_offset = _row_offset + opts.style.input_win_row_offset
  local row = vim.o.lines - height - row_offset - 1
  local top_margin = 4
  if height > vim.o.lines - row_offset + top_margin then
    height = vim.o.lines - row_offset - 1 - top_margin
    row = 0 + top_margin
  end

  local cnf = vim.api.nvim_win_get_config(output_obj.win)
  vim.api.nvim_win_set_config(output_obj.win, vim.fn.extend(cnf, { height = height, row = row }))

  -- set highlights
  for _, hl in ipairs(hls) do
    hl()
  end

  vim.api.nvim_buf_set_option(output_obj.buf, "modifiable", false)
  -- }}}

  -- update_output_obj(
  --   output_obj,
  --   texts,
  --   vim.o.lines,
  --   _row_offset + opts.style.input_win_row_offset,
  --   opts,
  --   endup_obj,
  --   which_obj,
  --   fuzzy_obj,
  --   which_line
  -- )

  -- highlight fuzzy matches
  if vim.api.nvim_get_current_buf() == fuzzy_obj.buf then
    for i, match_pos in ipairs(match_posses) do
      if poss ~= nil then
        for _, v in ipairs(poss[match_pos[1]]) do
          vim.api.nvim_buf_add_highlight(
            output_obj.buf,
            ns_wf_output_obj_fuzzy,
            "WFFuzzy",
            i - 1,
            v + opts.prefix_size + 6,
            v + opts.prefix_size + 7
          )
        end
      end
    end
  end

  -- highlight which matches
  if vim.api.nvim_get_current_buf() == which_obj.buf then
    output_obj_which:place(output_obj.buf)
  else
    output_obj_which:clear(output_obj.buf)
  end

  -- update prompt counter
  prompt_counter_update(which_obj, fuzzy_obj, #choices_obj, #which_matches_obj)
end

return { core = core }
