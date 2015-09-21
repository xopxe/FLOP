-- this should be copied  in  ns-3-dce-git/"files-N"
-- set this in __N__HERE__ label below
-- This will be done by the installation script.
local N = assert(tonumber(__N__HERE__), 'must set N value before running') 
local seed = tonumber(__SEED__HERE__) or N
local n = N + 1

--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local log = require 'lumen.log'

log.format = '%T %m-%s: %l'

--[[
--log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'FLOP')
log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'SELECTOR')
log.setlevel('ALL', 'HTTP')
log.setlevel('ALL', 'TEST')
--log.setlevel('ALL')
--]]
log.setlevel('ALL', 'FLOP')
log.setlevel('ALL', 'RONG')
log.setlevel('ALL', 'SELECTOR')
log.setlevel('ALL', 'HTTP')
log.setlevel('ALL', 'TEST')



-- Number of chunks the file is split
local number_of_chunks = 20

-- Size of each chunk
local chunk_size = 250000

-- Time between consecutive chunks
local interchunk_time = 10

-- How much to wait before giving up and missing a chunk
local interchunk_abort_time = 2*interchunk_time

local pick_server = function(seen_array)
  local lte_s
  local wifi_s = {}
  for i, s in ipairs(seen_array) do
    log('TEST', 'DEBUG', 'Server candidate %i/%i: %s', i, #seen_array, tostring(s.node))
    if s.node=='node1' or s.node=='node7' then
      lte_s = s
    else
      wifi_s[#wifi_s+1] = s
    end
  end
  local ret
  if #wifi_s>0 then
    ret = wifi_s[math.random(#wifi_s)]
  else
    ret = lte_s
  end
  return ret
end

-- This is the configuration for the flop service
local conf = {
  pick_server = pick_server,
  
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  
  -- rate of the beacon broadcast
  send_views_timeout =  20,

  -- buffer size
  inventory_size = 40,
  reserved_owns = 50, -- for the messages publishes by the node itself

  protocol = 'flop',
  max_hop_count = math.huge,
  
  -- notification forwarding prameters
  delay_message_emit = 1,
  message_inhibition_window = 1, --10,
  
  -- buffer management parameters
  max_owning_time = math.huge,
  max_ownnotif_transmits = math.huge, --20,
  max_notif_transmits = math.huge, --20,
  max_chunk_downloads = math.huge, --3, -- how many times will allow a chunk to be downloaded
  max_notifid_tracked = 5000,
  view_skip_list = false,
	ranking_find_replaceable = 'find_fifo_not_on_path',
  min_n_broadcasts = 0,
  
  -- routing parameters
  max_path_count = 3,
  q_decay = 0.999,
  q_reinf = 0.1,
  
  -- timeout before aborting a chunk download
  http_get_timeout = 1,
  
  attachments = {},
  
  -- where the chunks will be served
  http_conf = {
    ip='10.1.0.'..n, 
    port=8080,
  },

  --neighborhood_window = 1, -- for debugging, should be disabled
}


local sched = require 'lumen.sched'
local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

io.stdout:setvbuf('line') 
math.randomseed(seed)

for k, v in pairs(conf) do
  log('TEST', 'INFO', 'Configuration %s=%s', tostring(k), tostring(v))
end
log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)

local send_notification = function(name, chunk)
  local mid= '/'..name..chunk..'.chunk' --must be a filename
  conf.attachments[mid] = string.rep('x', chunk_size)
  log('TEST', 'INFO', 'NOTIFICATING chunk %s: %i bytes', tostring(mid), chunk_size)
  rong:notificate(
    mid,
    {
      filename = name..'.avi',
      chunk = chunk,
    }  
  )
end

-- Node 1 and 6 are cell bases.
if n==1 or n==6 then
  local sender = sched.run( function()
    --sched.sleep(100)
    for i=1, number_of_chunks do
      send_notification('N', i)
      send_notification('M', i)
      --sched.sleep(interchunk_time)
    end
  end)
end

local get_client_task = function(name)
  return function()
    sched.sleep(math.random()) --small random sleep to avoid synchronization
    
    -- initialize subscription
    log('TEST', 'INFO', 'SUBSCRIBING on %s FOR no data', name)
    local s = rong:subscribe(
      'SUB'..name..'@'..conf.name, 
      {
        {'filename', '=', 'none' },
      }
    )
    log('TEST', 'INFO', 'SUBSCRIBED on %s FOR no data', name, 
      tostring(s.filter[1][1]), tostring(s.filter[1][2]), tostring(s.filter[1][3]))
    
    local last_t
    -- consume notifs as they arrive and request the next
    local arrived = {}
    sched.sigrun({s, buff_mode='keep_last', timeout=interchunk_abort_time}, function(sig, n) 
      local arrived_chunk
      if sig then 
        if not arrived[n.id] then 
          log('TEST', 'INFO', 'ARRIVED on %s FOR %s: %s', name, tostring(s.id), tostring(n.id))
          for k, v in pairs (n.data) do
            log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
            if k=='chunk' then arrived_chunk = v end
          end
          assert(arrived_chunk)
          arrived[n.id] = true
           
          --sched.sleep(1)
          log('TEST', 'INFO', 'SUBSCRIBING on %s FOR chunk=%i', name, arrived_chunk+1)
          s=rong:update_subscription(
            'SUB'..name..'@'..conf.name, 
            {
              {'chunk', '=', arrived_chunk+1},
              {'filename', '=', name..'.avi' },
            }
          )
          last_t = sched.get_time()
          log('TEST', 'INFO', 'SUBSCRIBED on %s FOR %s%s%s', name,
            tostring(s.filter[1][1]),tostring(s.filter[1][2]), tostring(s.filter[1][3]))
        end
      else
          arrived_chunk = tonumber(s.filter[1][3])
          if arrived_chunk and arrived_chunk>=1 and sched.get_time()-last_t>=interchunk_abort_time then
            log('TEST', 'INFO', 'MISSED on %s FOR %s: %s with %s', name, tostring(s.id), 
              tostring(s.filter[1][3]), tostring(n))
            --sched.sleep(1)
            log('TEST', 'INFO', 'SUBSCRIBING on %s FOR chunk=%i', name, arrived_chunk+1)
            s=rong:update_subscription(
              'SUB'..name..'@'..conf.name, 
              {
                {'chunk', '=', arrived_chunk+1},
                {'filename', '=', name..'.avi' },
              }
            )
            last_t = sched.get_time()
            log('TEST', 'INFO', 'SUBSCRIBED on %s FOR %s%s%s', name,
              tostring(s.filter[1][1]),tostring(s.filter[1][2]), tostring(s.filter[1][3]))
          end
      end
    end)

    -- initial sleep before starting
    local sleeptime = 0
    if n>=2 and n<=5 then
      sleeptime = 50  +(n-2)*50
    elseif n>=7 and n<=9 then
      sleeptime = 300  +(n-7)*50
    elseif n==10 then
      sleeptime = 50 +(6-2)*50
    end
    if name=='M' then
      sleeptime=450-sleeptime
    end
    log('TEST', 'INFO', 'SLEEPING on %s FOR %s', name, tostring(sleeptime))
    sched.sleep(sleeptime)

    
    -- request the first chunk
    log('TEST', 'INFO', 'SUBSCRIBING on %s FOR chunk=%i', name, 1)
    s = rong:update_subscription(
      'SUB'..name..'@'..conf.name, 
      {
        {'chunk', '=', 1},
        {'filename', '=', name..'.avi' },
      }
    )
    last_t = sched.get_time()
    log('TEST', 'INFO', 'SUBSCRIBED on %s FOR %s%s%s', name,
      tostring(s.filter[1][1]),tostring(s.filter[1][2]), tostring(s.filter[1][3]))
  end
end

sched.run(get_client_task('N'))
sched.run(get_client_task('M'))

-- periodically log internal data
sched.run(function()
  while true do
    sched.sleep(conf.send_views_timeout*20)
       
    for sid, s in pairs(rong.view) do
      local out = {}
      for n, _ in pairs (s.meta.visited) do out[#out+1] = n end
      log('TEST', 'INFO', 'VISITED FOR %s = {%s}', sid, table.concat(out,' '))
      out = {}
      for n, q in pairs (s.meta.q) do out[#out+1] =n..'='..string.format('%.2f',q) end
      log('TEST', 'INFO', 'NODE Qs FOR %s = {%s}', sid, table.concat(out,','))
    end
    
    local taskcount = 0
    for taskd, _ in pairs (sched.tasks) do taskcount=taskcount+1 end
    log('TEST', 'INFO', 'Lua Ram: %i, Lumen: %i tasks', 
      collectgarbage('count')*1024, taskcount)    
  end
end)


sched.loop()
