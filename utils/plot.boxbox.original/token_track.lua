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
local history = {}

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
  local n = tonumber(filename:match('files%-(%d+)/'))+1

	local ts
  
  for line in f:lines() do
    local ts, token_id, size
    
    --1262304005 TEST-INFO: Configuration create_token=TOKEN_232489615    
    ts, token_id = line:match('^(%S*) TEST%-INFO: Configuration create_token=(%S*)$')
    ts = tonumber(ts)
    if ts and token_id then
      --print (ts, sid, nid)
      local h = history[token_id] or {}; history[token_id] = h
      h[#h+1] =  {node=n, ev='Created', ts=ts, size=0}
      if first_ts>ts then first_ts=ts end
    else
      
      --1262304505 TRW-DETAIL: Sender sending token TOKEN_232489615, 1 notifs, 77 bytes
      ts, token_id, size = line:match('^(%S*) TRW%-DETAIL: Sender sending token (%S*), (%S*) notifs')
      ts, size = tonumber(ts), tonumber(size)
      if ts and token_id and size then
        --print (ts, sid, nid)
        local h = history[token_id] or {}; history[token_id] = h
        h[#h+1] = {node=n, ev='Offered', ts=ts, size=size}
        
      else
        --1262304604 TRW-DETAIL: Sender handed over token: TOKEN_232489615
        ts, token_id = line:match('^(%S*) TRW%-DETAIL: Sender handed over token: (%S*)$')
        ts = tonumber(ts)
        if ts and token_id then
          --print (ts, token_id)
          local h = history[token_id] or {}; history[token_id] = h
          h[#h+1] = {node=n, ev='Released', ts=ts}
        
        else
          --1262304604 TRW-DETAIL: Receiver parsed token: TOKEN_224037981
          ts, token_id = line:match('^(%S*) TRW%-DETAIL: Receiver parsed token: (%S*)$')
          ts = tonumber(ts)
          if ts and token_id then
            --print (ts, sid, nid)
            local h = history[token_id] or {}; history[token_id] = h
            h[#h+1] = {node=n, ev='Received', ts=ts}
          end
        end
      end
    end
    
		if not ts then ts = tonumber(line:match('^(%S*) '))  end
    if not ts then print ('WARNING, A NO LOG ENTRY FOUND IN', filename, line) end
  end
  
  if ts and last_ts<ts then last_ts=ts end
  
  f:close()
end

---[[
local files = os.capture('ls ../../ns-3-dce-git/files-*/var/log/*/stdout')
for file in files:gmatch('%S+') do
	process_file(file)
end
--]]
  
for _, h in  pairs(history) do
  table.sort(h, function(a, b) return a.ts<b.ts end)  
end



do
  for t_id, h in  pairs(history) do
    print ('TOKEN:', t_id)
    local owner
    local size = 0
    for i, reg in ipairs(h) do
      size = reg.size or size
      local ts = reg.ts - first_ts
      if reg.ev=='Created' or reg.ev == 'Received' or reg.ev == 'Released' then 
        --print (reg.ts, reg.node, reg.ev, size)
        
        ---[[
        if reg.ev == 'Released' and owner == reg.node then 
          print (ts, reg.node, 'Releasing OWNED', size)
        elseif reg.ev == 'Released' and owner == nil then 
          print (ts, reg.node, 'Releasing ORPHAN', size)
        elseif reg.ev == 'Released' then 
          --print (reg.ts, reg.node, 'Releasing', size)
        elseif reg.ev == 'Created' and owner == nil then 
          print (ts, reg.node, 'Created', size)
          owner = reg.node
        elseif reg.ev == 'Received' and owner == nil then 
          print (ts, reg.node, 'Received ORPHAN', size)
        elseif reg.ev == 'Received' then 
          print (ts, reg.node, 'Received', size)
          owner = reg.node
        end
        --]]
      
      end
      
    end
    print ('\n')
    --os.exit(0)
  end
end