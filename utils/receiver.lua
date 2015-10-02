local socket = require 'socket'
io.stdout:setvbuf('line') 

local locaddr, locport = '10.1.0.2', 8888 
local recvt, sendt = {}, {}

local fdaccept=assert(socket.bind(locaddr, locport))
fdaccept:settimeout(0)
recvt[#recvt+1]=fdaccept

print ('accepting')
while true do
	local recvt_ready, sendt_ready, err_accept = socket.select(recvt, sendt, -1)
	if err_accept~='timeout' then
		for _, fd in ipairs(recvt_ready) do
				local client, err=fd:accept()
				if client then
					local m = '>'.. socket.gettime()
					client:send(m)
					--print(m)
					client:close()
				else
					print('!!!! accept failed with', err)
				end
		end

	end
end
