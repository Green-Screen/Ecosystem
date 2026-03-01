-- EasyType

-- Version: 2.0

--[[

	Simplified and optimized

]]--

-- Written for performance
--!strict

-- A custom type checker made for type-checking custom objects and classes

return function(Value: any, ShouldClassInstance: boolean?): string
	local t: any = typeof(Value)
	if (t == "table" and Value.ClassName) or (t == "Instance" and ShouldClassInstance) then
		-- If its a custom object or instance
		return Value.ClassName
	end
	return t
end
