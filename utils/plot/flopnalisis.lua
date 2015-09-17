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
local p_evolution = {}
local targets = {}


local total_sent = 0
local total_get_bytes_from = {}
local total_traffic_on = {}

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
	local ts
  local buff_hist = {}
  local p_hist = {}
  
  local broadcast_bytes = 0
  local get_bytes = 0
  local lte_bytes = 0
  local get_bytes_from = {}
  local get_from

  for line in f:lines() do
    local sid, target, nid, bytes, ip
    
    --1262304262.0081 FLOP-DEBUG: Broadcast view (654 bytes)    
    ts, bytes = line:match('^(%S*) FLOP%-DEBUG: Broadcast view %((%S*) bytes%)$')
    if ts and bytes then
      broadcast_bytes = broadcast_bytes + bytes
    else
      ts, bytes = line:match('^(%S*) FLOP%-DEBUG: Succesfull GET fragment[^%+]+%+(%S*) bytes%)$')
      if ts and bytes then
        if get_from==1 or get_from==7 then
          lte_bytes = lte_bytes + bytes
        else
          get_bytes = get_bytes + bytes
          get_bytes_from[get_from] = get_bytes_from[get_from] + bytes
          total_get_bytes_from[get_from] = total_get_bytes_from[get_from] + bytes
        end
      else
        --1262304131.5957 FLOP-DETAIL: Requesting /N1.chunk?s=1 to 10.1.0.1:8080
        ts, ip = line:match('^(%S*) FLOP%-DETAIL: Requesting %S+ to 10%.1%.0%.(%S*):8080$')
        if ts and ip then
          get_from = tonumber(ip)
          get_bytes_from[get_from] = get_bytes_from[get_from] or 0
          total_get_bytes_from[get_from] = total_get_bytes_from[get_from] or 0
        else
          --[[
          --1262304151 TEST-INFO: NOTIFICATING chunk 11: 100000 bytes
          ts, bytes = line:match('^(%S*) TEST%-INFO: NOTIFICATING chunk %S+: (%S+) bytes$')
          if ts and bytes then
            lte_bytes = lte_bytes + bytes
          end
          --]]
        end
      end
    end
   
    ts = tonumber(ts)
		if not ts then ts = tonumber(line:match('^(%S*) '))  end
  end
  if not ts then print ('WARNING, A NO LOG ENTRY FOUND IN', filename) end
  if last_ts<ts then last_ts=ts end

  local n = tonumber(filename:match('files%-(%d+)/'))
  local ip = n+1
  --[[
  print (ip, 'broadcast_bytes', broadcast_bytes, 'get_bytes', get_bytes, 'lte_bytes', lte_bytes)
  for k, v in pairs(get_bytes_from) do 
    print ('\t', 'from', k, ':', v)
  end
  --]]
  total_traffic_on[ip] = {
    broadcast_bytes = broadcast_bytes,
    get_bytes = get_bytes,
    lte_bytes = lte_bytes
  }
  
  f:close()
end

---[[
local files = os.capture('ls ../../ns-3-dce-git/files-*/var/log/*/stdout')
for file in files:gmatch('%S+') do
	process_file(file)
end
--]]

local node_names = {'X', 'A', 'B', 'C', 'D', 'E', 'Y', 'F', 'G', 'H', 'M'}

local function jouls(lte_bytes, up_bytes, get_bytes, broadcast_bytes)
  local ujb =  3 * lte_bytes + 0.8*up_bytes + 0.8*get_bytes + 0.8 * broadcast_bytes
  return (ujb * 8) / 1000000
end

local jouls_clean_get = jouls(2000000, 0, 0, 0)

for k, v in pairs(total_traffic_on) do 
  local up_bytes = total_get_bytes_from[k] or 0
  local get_bytes = v.get_bytes
  local broadcast_bytes = v.broadcast_bytes
  local lte_bytes = v.lte_bytes
  print (node_names[k], '&', lte_bytes, '&', up_bytes, '&', get_bytes, '&', 
    broadcast_bytes, '&',  (get_bytes+lte_bytes)/ 2000000, '&', 
    string.format('%.2f', jouls(lte_bytes, up_bytes, get_bytes, broadcast_bytes)/jouls_clean_get ), ' \\\\' )
end



--for k, v in pairs(total_get_bytes_from) do 
--end

--[[
process_file('../../ns-3-dce-git/files-0/var/log/23976/stdout')
process_file('../../ns-3-dce-git/files-1/var/log/50144/stdout')
process_file('../../ns-3-dce-git/files-2/var/log/49853/stdout')
--]]

