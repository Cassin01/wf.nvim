local M = {}

-- @param a cell
-- @param b cell
local function _which(a, b)
	return a.key < b.key
end

-- @param a cell
-- @param b cell
local function _fuzzy(a, b)
	return a.text < b.text
end

-- @param tbl [cell]
function M.which(tbl)
	table.sort(tbl, _which)
	return tbl
end

-- @param tbl [cell]
function M.fuzzy(tbl)
	table.sort(tbl, _fuzzy)
	return tbl
end

return M
