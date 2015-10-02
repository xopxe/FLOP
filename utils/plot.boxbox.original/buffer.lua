#!/bin/lua

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local first_ts=math.huge
local last_ts=0
local notifs = {}

local total_sent = 0

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
	local ts
  for line in f:lines() do
    local sid, target, nid
    
    --1262307420.3907 TEST-INFO: ARRIVED FOR SUB1@node1: N3@node2
    ts, sid, nid = line:match('^(%S*) TEST%-INFO: ARRIVED FOR (%S*): (%S*)$')
    ts = tonumber(ts)
    if ts and sid and nid then
      --print (ts, sid, nid)
      local notif = notifs[nid] or {}
      notifs[nid] = notif
      notif.arrived = notif.arrived or ts
      notif.sid = sid
      if first_ts>ts then first_ts=ts end
    end
    
    --1262304505 TEST-INFO: NOTIFICATING FOR target=node3: N4@node2
    ts, target, nid = line:match('^(%S*) TEST%-INFO: NOTIFICATING FOR target=(%S*): (%S*)$')
    ts = tonumber(ts)
    if ts and target and nid then
      --print (ts, sid, nid)
      local notif = notifs[nid] or {}
      notifs[nid] = notif
      notif.sent = ts
      notif.target = target
			notif.source = nid:match('@(.*)$')
      if first_ts>ts then first_ts=ts end
    end

    local sent = line:match(' (%d+) bytes$')
		if sent then total_sent = total_sent + sent end
		if not ts then ts = tonumber(line:match('^(%S*) ')) end
  end
  if last_ts<ts then last_ts=ts end
end

local process_file_buffer_use = function ()
	local filename = os.capture('ls ../../ns-3-dce-git/files-5/var/log/*/stdout')
  local f = assert(io.open(filename,'r'))
	local buff_totals = {}
  local buff_last = {}
	local last_buff_line
  for line in f:lines() do
		--1262304604 TEST-INFO: BUFFER CONTENT: node1 1 node3 1 
    local ts, buff = line:match('^(%S*) TEST%-INFO: BUFFER CONTENT: (.*)$')
    ts = tonumber(ts)
    if ts and buff then
			local words = {}
      buff_last = {}
			for word in buff:gmatch("%S+") do words[#words+1] = word end
			for i=1, #words, 2 do
				local target, count = words[i], words[i+1]
        buff_last[target] = count
				buff_totals[target] = (buff_totals[target] or 0) + count
			end
      last_buff_line = buff
    end
  end
	print ('accumulated buffer use by target on node6:')
	for k, v in pairs(buff_totals) do print ('', k, v) end
	print ('current buffer use by target on node6:')
	for k, v in pairs(buff_last) do print ('', k, v) end
end


---[[
local files = os.capture('ls ../../ns-3-dce-git/files-*/var/log/*/stdout')
for file in files:gmatch('%S+') do
	process_file(file)
end
--]]

--[[
process_file('../../ns-3-dce-git/files-0/var/log/23976/stdout')
process_file('../../ns-3-dce-git/files-1/var/log/50144/stdout')
process_file('../../ns-3-dce-git/files-2/var/log/49853/stdout')
--]]

print ('bytes transmited:', total_sent)
print ('simulated time:', last_ts-first_ts)
process_file_buffer_use()

local outfiles = {}

for nid, n in pairs(notifs) do
  if n.sent and n.arrived 
  then n.latency = n.arrived-n.sent 
  else n.latency = 0 end
  
  if n.sent then n.sent=n.sent-first_ts end
  if n.arrived then n.arrived=n.arrived-first_ts 
  else n.arrived=0 end

	if not outfiles[n.target] then
		outfiles[n.target] = assert(io.open('arrival_'..n.target..'.data', 'w'))
	end

end

for nid, n in pairs(notifs) do
  --print (nid, n.source, n.target, n.sent, n.arrived, n.latency)
	outfiles[n.target]:write(nid..' '..n.source..' '..n.target..' '..n.sent..' '..n.arrived..' '..n.latency..'\n')
end

for _, f in pairs(outfiles) do f:close() end

