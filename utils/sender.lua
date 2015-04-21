local socket = require 'socket'
io.stdout:setvbuf('line') 

local address, port = '10.1.0.2', 8888 

print('sending')
local i=1
while true do
	local m='M '..i
	local fd=assert(socket.connect(address, port, '*', 0))
	local m, err = fd:receive('*a')
	--print(m)
	fd:close()
 	socket.sleep(1)
 	i=i+1
end
