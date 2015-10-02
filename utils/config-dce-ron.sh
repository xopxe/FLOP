#!/bin/sh

cant_nodes=$1

aux=$(($cant_nodes-1))

for i in `seq 0 $aux`; do

  mkdir ns-3-dce-git/"files-$i"
  
  n=$(($i+1))
	
	echo "--require 'strict'
--look for packages one folder up.
package.path = package.path .. ';;;../?.lua;../?/init.lua;../../?/init.lua;../../?.lua'

local sched = require 'lumen.sched'
local log = require 'lumen.log'
log.timestampformat = '%s'
--log.setlevel('ALL', 'RONG')
--log.setlevel('ALL', 'RON')
--log.setlevel('ALL', 'RWALK')
--log.setlevel('DETAIL', 'RWALK')
log.setlevel('ALL')

local selector = require 'lumen.tasks.selector'
selector.init({service='luasocket'})


local n = $n

local conf = {
  name = 'rongnode'..n, --must be unique
  protocol_port = 8888,
  listen_on_ip = '10.1.0.'..n, 
  broadcast_to_ip = '10.1.255.255', --adress used when broadcasting
  udp_opts = {
    broadcast	= 1,
    dontroute	= 1,
  },
  send_views_timeout =  6, --5
  
  protocol = 'rwalk',
  
  ---[[
  transfer_port = 0,"  >> ns-3-dce-git/files-$i/"rong-node.lua"
  
  if [ $i = '0' ]; then
    echo "  create_token = 'TOKEN@'..n," >> ns-3-dce-git/files-$i/"rong-node.lua"
  fi
  
  echo "  --]]
  
  --[[
  gamma = 0.99,
  P_encounter = 0.1,
  inventory_size	= 10,	--max number of messages carried
  reserved_owns	= 5,--guaranteed number of slots for own messages in inventory
  delay_message_emit = 1,
  max_owning_time = 60*60*24,	--max time own messages are kept
  max_notif_transmits = math.huge, --max number of transmissions for each notification
  max_ownnotif_transmits = math.huge, --max number of transmissions for each own notification,
  min_n_broadcasts = 0, --see find_replaceable_fifo in ranking.lua
  --]]
}

math.randomseed(n)

local rong = require 'rong'.new(conf)
--[[
local s = rong:subscribe(
  'SUB1@'..conf.name, 
  {
    {'q1', '=', 'A1'},
    {'q2', '=', 'A2'},
  }
)
sched.sigrun({s}, function(a, b) print ('NNN', a, b) end)
--]]

rong:notificate(
  'N1@'..conf.name,
  {
    q = 'X'
  }  
)

sched.loop()"  >> ns-3-dce-git/files-$i/"rong-node.lua"

done
