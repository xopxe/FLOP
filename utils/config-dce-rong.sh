#!/bin/sh

cant_nodes=$1
cant_tokens=$2

aux=$(($cant_nodes-1))

for i in `seq 0 $aux`; do

  mkdir ns-3-dce-git/"files-$i"
  
  n=$(($i+1))
	
	echo "--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../../?.lua;../../?/init.lua'

local sched = require 'lumen.sched'
local log = require 'lumen.log'
log.setlevel('DETAIL', 'RONG')
log.setlevel('ALL', 'TRW')
log.setlevel('ALL', 'TEST')
--log.setlevel('ALL')

local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})

local n = $n
local total_nodes = $cant_nodes

local notifaction_rate = 5    -- secs between notifs

local conf = {
  name = 'node'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 0,
  },
  send_views_timeout =  5, --5
  
  protocol = 'trw',
  ---[[
  transfer_port = 0,"  > ns-3-dce-git/files-$i/"rong-node.lua"
  
  if test $i -le $cant_tokens 
	then
    echo "  create_token = 'TOKEN@'..n," >> ns-3-dce-git/files-$i/"rong-node.lua"
  fi
  
  echo "  token_hold_time = 5,
  --]]

}


math.randomseed(n)

local rong = require 'rong'.new(conf)

local s = rong:subscribe(
  'SUB1@'..conf.name, 
  {
    {'target', '=', 'node'..n },
  }
)
log('TEST', 'INFO', 'SUBSCRIBING FOR target=%s', tostring(s.filter[1][3]))
sched.sigrun({s}, function(s, n) 
  log('TEST', 'INFO', 'ARRIVED FOR %s: %s',tostring(s.id), tostring(n.id))
  for k, v in pairs (n.data) do
    log('TEST', 'INFO', '>>>>> %s=%s',tostring(k), tostring(v))
  end
end)


sched.run( function()
  while true do
    local target
    repeat
      target = 'node'..math.random(total_nodes)
    until target ~= conf.name
    log('TEST', 'INFO', 'NOTIFICATING FOR target=%s: %s', 
      target,'N'..sched.get_time()..'@'..conf.name)
    rong:notificate(
      'N'..sched.get_time()..'@'..conf.name,
      {
        q = 'X',
        target = target,
      }  
    )
    sched.sleep(notifaction_rate)
  end
end)


sched.loop()
"  >> ns-3-dce-git/files-$i/'rong-node.lua'

done
