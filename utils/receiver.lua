local socket = require 'socket'

local udp_in = assert(socket.udp())
assert(udp_in:setsockname('*', 8888)) --(iface, port))
while true do
 local m, err=udp_in:receive()
 print ('>', m, err)
end
