-- this should be copied  in  ns-3-dce-git/"files-N"
-- set this in __N__HERE__ label below
-- This will be done by the installation script.
local N = assert(tonumber(__N__HERE__), 'must set N value before running') 
local n = N + 1

--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local log = require 'lumen.log'

log.format = '%T %m-%s: %l'
--log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'FLOP')
log.setlevel('DETAIL', 'RONG')
log.setlevel('DETAIL', 'SELECTOR')
log.setlevel('ALL', 'HTTP')
log.setlevel('ALL', 'TEST')
--log.setlevel('ALL')

local sched = require 'lumen.sched'

local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

-- Number of chunks the file is split
local number_of_chunks = 20

-- Size of each chunk
local chunk_size = 100000


-- This is the configuration for the flop service
local conf = {
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  
  -- rate of the beakon broadcast
  send_views_timeout =  5,

  -- buffer size
  inventory_size = 10,
  reserved_owns = 50, -- for the messages publishes by the node itself

  protocol = 'flop',
  max_hop_count = math.huge,
  
  -- notification forwarding prameters
  delay_message_emit = 1,
  message_inhibition_window = 1, --10,
  
  -- buffer management parameters
  max_owning_time = math.huge,
  max_ownnotif_transmits = 20,
  max_notif_transmits = 20,
  max_chunk_downloads = 3, -- how many times will allow a chunk to be downloaded
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

io.stdout:setvbuf('line') 
math.randomseed(n)

for k, v in pairs(conf) do
  log('TEST', 'INFO', 'Configuration %s=%s', tostring(k), tostring(v))
end
log('TEST', 'INFO', 'Creating service %s', tostring(n))
local rong = require 'rong'.new(conf)

local send_notification = function(chunk)
  log('TEST', 'INFO', 'NOTIFICATING chunk %s', tostring(chunk))
  local mid= '/N'..chunk..'.chunk' --must be a filename
  conf.attachments[mid] = string.rep('x', chunk_size)
  rong:notificate(
    mid,
    {
      filename = 'file.avi',
      chunk = chunk,
    }  
  )
end

if n==1 then
  local sender = sched.run( function()
    sched.sleep(100)
    for i=1, number_of_chunks do
      send_notification(i)
      sched.sleep(10)
    end
  end)
end

sched.run(function()
  sched.sleep(math.random()) --small random sleep to avoid synchronization
  
  -- initialize subscription
  log('TEST', 'INFO', 'SUBSCRIBING FOR no data')
  local s = rong:subscribe(
    'SUB@'..conf.name, 
    {
      {'filename', '=', 'none' },
    }
  )
  log('TEST', 'INFO', 'SUBSCRIBED FOR no data', 
    tostring(s.filter[1][1]), tostring(s.filter[1][2]), tostring(s.filter[1][3]))
  
  -- consume notifs as they arrive and request the next
  local arrived = {}
  sched.sigrun({s, buff_mode='keep_last'}, function(s, n) 
    local arrived_chunk
    if not arrived[n.id] then 
      log('TEST', 'INFO', 'ARRIVED FOR %s: %s',tostring(s.id), tostring(n.id))
      for k, v in pairs (n.data) do
        log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
        if k=='chunk' then arrived_chunk = v end
      end
      assert(arrived_chunk)
      arrived[n.id] = true
       
      sched.sleep(1)
      log('TEST', 'INFO', 'SUBSCRIBING FOR chunk=%i', arrived_chunk+1)
      local s=rong:update_subscription(
        'SUB@'..conf.name, 
        {
          {'chunk', '=', arrived_chunk+1},
          {'filename', '=', 'file.avi' },
        }
      )
      log('TEST', 'INFO', 'SUBSCRIBED FOR %s%s%s', 
        tostring(s.filter[1][1]),tostring(s.filter[1][2]), tostring(s.filter[1][3]))
    end
  end)

  -- initial sleep before starting
  sched.sleep(100+(n-1)*10)
  
  -- request the first chunk
  log('TEST', 'INFO', 'SUBSCRIBING FOR chunk=%i', 1)
  local s = rong:update_subscription(
    'SUB@'..conf.name, 
    {
      {'chunk', '=', 1},
      {'filename', '=', 'file.avi' },
    }
  )
  log('TEST', 'INFO', 'SUBSCRIBED FOR %s%s%s', 
    tostring(s.filter[1][1]),tostring(s.filter[1][2]), tostring(s.filter[1][3]))
end)

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
