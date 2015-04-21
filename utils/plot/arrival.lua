#!/bin/lua

local tonumber, ipairs, pairs = tonumber, ipairs, pairs 

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
local buff_occupation = {}
local targets = {}


local total_sent = 0

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
	local ts
  local buff_hist = {}

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
    else
      
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
        
        if not targets[target] then 
          targets[target] = true
          targets[#targets+1] = target
        end
      else
        --1262304604 TEST-INFO: BUFFER CONTENT: node1 1 node3 1 
        local buff 
        ts, buff = line:match('^(%S*) TEST%-INFO: BUFFER CONTENT: (.*)$')
        ts = tonumber(ts)
        if ts and buff then
          local words = {}
          local buffreg = { ts = ts }
          for word in buff:gmatch("%S+") do words[#words+1] = word end
          for i=1, #words, 2 do
            buffreg[words[i]] = words[i+1]
          end
          buff_hist[#buff_hist+1] = buffreg
        end
      end
    end
    
    local sent = line:match(' (%d+) bytes$')
		if sent then total_sent = total_sent + sent end
    
		if not ts then ts = tonumber(line:match('^(%S*) '))  end
  end
  if not ts then print ('WARNING, A NO LOG ENTRY FOUND IN', filename) end
  if last_ts<ts then last_ts=ts end
  
  local n = tonumber(filename:match('files%-(%d+)/'))
  buff_occupation[n] = buff_hist  
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

-----------------------------------------------------------------
-- arrival
do
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

  local sent, arrived = 0, 0
  for nid, n in pairs(notifs) do
    --print (nid, n.source, n.target, n.sent, n.arrived, n.latency)
    outfiles[n.target]:write(nid..' '..n.source..' '..n.target..' '..n.sent..' '..n.arrived..' '..n.latency..'\n')
    if n.sent then sent = sent + 1 end
    if n.arrived>0 then arrived = arrived + 1 end
  end
  for _, f in pairs(outfiles) do f:close() end

  print ('total sent:', sent, 'total arrived', arrived, 'delivery rate', arrived/sent)
end
-----------------------------------------------------------------


-----------------------------------------------------------------
-- buffer occupation
do
  local buff_totals = {}
  local buff_range = {}
  local f = assert(io.open('buffer.data', 'w'))
  local node_range={3, 12}
  for node = node_range[1], node_range[2] do
    for i, reg in ipairs(buff_occupation[node]) do
      local range = buff_range[i] or {ts = reg.ts-first_ts}
      buff_range[i] = range
      --f:write(reg.ts-first_ts)
      for _, target in ipairs(targets) do
        --if reg[target] then
          range[target] = range[target] or {min=math.huge, max=0, tot=0}
          local count = tonumber(reg[target]) or 0
          if range[target].min > count then range[target].min = count end
          if range[target].max < count then range[target].max = count end
          range[target].tot = range[target].tot + count 
          buff_totals[target] = (buff_totals[target] or 0) + count
        --end
        --f:write(' '..target..' '..count)
      end
      --f:write('\n')
    end  
  end

  local node_amount = node_range[2]-node_range[1]+1
  for _, reg in ipairs(buff_range) do
    f:write(reg.ts)
    for _, target in ipairs(targets) do
      f:write(' '..target..' '..reg[target].tot/node_amount..' '..reg[target].min..' '..reg[target].max)
    end
    f:write('\n')
  end
  f:close() 

  print ('accumulated buffer use by target on nodes '..node_range[1]..'..'..node_range[2])
  for k, v in pairs(buff_totals) do print ('', k, v) end
end
-----------------------------------------------------------------

