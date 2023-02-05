local ns_wf_which_obj = vim.api.nvim_create_namespace("wf_which_obj")
local ns_wf_fuzzy_obj = vim.api.nvim_create_namespace("wf_fuzzy_obj")

local update = function(which_obj, fuzzy_obj, choices_size, matched_size)
  local counter = tostring(matched_size) .. "/" .. tostring(choices_size)
  vim.api.nvim_buf_clear_namespace(which_obj.buf, ns_wf_which_obj, 0, -1)
  vim.api.nvim_buf_clear_namespace(fuzzy_obj.buf, ns_wf_fuzzy_obj, 0, -1)
  local prompt_counter = function(buf, ns)
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        virt_text = { { counter, "WFWhichObjCounter" } },
        virt_text_pos = "right_align",
      })
  end
  if which_obj.buf == vim.api.nvim_get_current_buf() then
    prompt_counter(which_obj.buf, ns_wf_which_obj)
  else
    prompt_counter(fuzzy_obj.buf, ns_wf_fuzzy_obj)
  end
end

return { update = update }
