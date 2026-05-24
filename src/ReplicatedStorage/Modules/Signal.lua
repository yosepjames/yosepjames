-- Lightweight bindable-free signal for internal module communication
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	local id = {}
	self._listeners[id] = fn
	return {
		Disconnect = function()
			self._listeners[id] = nil
		end,
	}
end

function Signal:Fire(...)
	for _, fn in pairs(self._listeners) do
		task.spawn(fn, ...)
	end
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

return Signal
