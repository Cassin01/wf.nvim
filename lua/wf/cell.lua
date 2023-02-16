local new = function(id, key, text, type_)
	return {
		key = key,
		id = id,
		text = text,
		-- key or group
		["type"] = type_,
	}
end

return { new = new }
