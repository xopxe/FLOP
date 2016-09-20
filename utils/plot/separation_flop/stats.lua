#!/bin/lua

local tonumber, ipairs, pairs, string, floor = tonumber, ipairs, pairs, string, math.floor

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

local stats={}

local deliveryall = io.open('deliveryall.out', 'a')

stats.median = function ( t )
  local temp={}
  local med, low, high

  -- deep copy table so that when we sort it, the original is unchanged
  -- also weed out any non numbers
  for k,v in pairs(t) do
    --if type(v) == 'number' and v>0 then
    if type(v) == 'number' and v==v then
      temp[#temp+1] = v
    end
  end

  table.sort( temp, function(a, b) return a<b end)
  
  if #temp==0 then return nil, nil, nil end
  
  if #temp%2 == 0 then
    med = ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
  else
    med = temp[math.ceil(#temp/2)]
  end
  
  --print ('!!1', #temp/4)
  --print ('!!2', 3*#temp/4)
  --print ('<'..#temp..'>',table.concat(temp, ' | '))

  if #temp%4 == 0 then
    low = ( temp[#temp/4] + temp[#temp/4+1] ) / 2
  else
    low = temp[math.ceil(#temp/4)]
  end
  
  if 3*#temp%4 == 0 then
    high = ( temp[3*#temp/4] + temp[3*#temp/4+1] ) / 2
  else
    high = temp[math.ceil(3*#temp/4)]
  end
  
  return med, low, high
end

stats.avgstd = function(t)
  local avg, std, count = 0, 0, 0
  for _, v in pairs(t) do
    if v==v then
      avg=avg+v
      count=count+1
    end
  end
  avg=avg/count
  for _, v in pairs(t) do
    std=std+(v-avg)^2
  end
  std=math.sqrt(std/count)
  
  return avg, avg-std, avg+std, std
end
stats.avgminmax = function(t)
  local avg, min, max, count = 0, math.huge, -math.huge, 0
  for _, v in pairs(t) do
    if v==v then
      avg=avg+v
      count=count+1
      if v<min then min=v end
      if v>max then max=v end
    end
  end
  avg=avg/count
  return avg, min, max
end



local data = {} --[file] -> {[ts//100]->{X->{}, Y->{}}}


--[[
node1	:	60	sent
node3	:	60	sent
SUBS:
on	node1
	node1	:	22	received
on	node3
	node3	:	42	received
--]]
local n_sent
local arrived = {}
local n_arrvided_st = {}
local delivery_tot = {}
local comlabels = {}

local arrived_m = {}

local process_file = function (filename)
  local f = assert(io.open(filename,'r'))
  local d = {}
  data[filename] = d
  local arrst = {}
  n_arrvided_st[filename] = arrst
  local filenumber = tonumber(filename:match('^(%d+).txt'))
	
  for line in f:lines() do
    local ts
    
    --node1	:	60	sent
    local count = line:match('^%S+\t:\t(%d+)\tsent$')
    n_sent = n_sent or tonumber(count)

    --	node1	:	22	received
    local flow_id, received = line:match('^\t(%S+)\t:\t(%d+)\treceived$')
    if flow_id and received then
      if not arrived[flow_id] then
        arrived[flow_id] = {tonumber(received)/n_sent}
      else
        arrived[flow_id][#arrived[flow_id]+1] = tonumber(received)/n_sent
      end
print('!', filename, flow_id, tonumber(received)/n_sent)
      deliveryall:write(''..tonumber(received)/n_sent .. '\n')
    end
    
    --arrived:	node1#19	1
    local fid, nseq = line:match('^arrived:\t(node%d+)#(%d+)\t1$')
    --print (line, nseq)
    nseq=tonumber(nseq)
    if nseq and nseq>=25 then
      arrst[fid] = (arrst[fid] or 0) + 1
    end
    if nseq then 
      if not arrived_m[fid] then
        arrived_m[fid] =  {}
        for i=1, 60 do arrived_m[fid][i] = 0 end
        arrived_m[#arrived_m+1] = fid
      end    
      arrived_m[fid][nseq] = arrived_m[fid][nseq] + 1
      
      --if nseq%10==5 then 
        local idt = math.floor(nseq/10)
        delivery_tot[fid] = delivery_tot[fid] or {}
        delivery_tot[fid][idt] = delivery_tot[fid][idt] or {}
        delivery_tot[fid][idt][filenumber] = (delivery_tot[fid][idt][filenumber] or 0) + 1
      --end
    end
    
    if filenumber>10  then
      --INV	1262308612.7973	node3	5
      local tsi, nodei, fidi, counti = line:match('^INV\t(%S+)\t(%S+)\t(node%d+)\t(%d+)$')
      tsi, nodei, counti = tonumber(tsi), tonumber(nodei), tonumber(counti)
      if tsi and fidi and counti then
        local fi
        if nodei<=8 and nodei>=4 then 
          fi = io.open('invdump_'..fidi..'_X.out', 'a')
        elseif nodei<=13 and nodei>=9 then 
          fi = io.open('invdump_'..fidi..'_Y.out', 'a')
        end
        if fi then 
          fi:write(tsi..' '.. counti/10 ..'\n')
          fi:close()
        end
      end
    end
    
    -- 1262304604 - 0.5 - 0.5 0.5 0.5 0.5 0.5 - 0.5 0.5 0.5 - 
    local occup = {}
    ts, occup[1], occup[2], occup[3], occup[4], occup[5], occup[6], occup[7], occup[8], occup[9], occup[10], occup[11], occup[12], occup[13]
      = line:match('^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) $')
    ts = tonumber(ts)
    if ts then
      local sumX = 0
      local countX = 0
      for i=4,8 do
        local v=tonumber(occup[i])
        if v then 
          sumX=sumX+v
          countX=countX+1
        end
      end
      local sumY = 0
      local countY = 0
      for i=9,13 do
        local v=tonumber(occup[i])
        if v then 
          sumY=sumY+v
          countY=countY+1
        end
      end
      --print (ts, sumX/countX, sumY/countY)
      --local tsD = math.floor(ts/100)*100+100
      local tsD = math.floor(ts/200)*200 + 100
      if not d[tsD] then
        d[tsD] = { ['X']={sumX/countX}, ['Y']={sumY/countY}}
      else
        d[tsD].X[#d[tsD].X+1] = sumX/countX
        d[tsD].Y[#d[tsD].Y+1] = sumY/countY
      end
      
    end
    
    --LABEL	1262306304	6	1
    local label_rec = {}
    local mid, label
    ts, mid, label = line:match('^LABEL%s(%S+)%s(%S+)%s(%S+)$')
    ts, mid = tonumber(ts), tonumber(mid)
    if ts then
      --print ('@@',ts, mid, label )
      comlabels[ts] = comlabels[ts] or {}
      comlabels[ts][mid] = label
    end
    
  end
  
  f:close()
end

---[[
local filecount = 0
local files = os.capture('ls *.txt')
for file in files:gmatch('%S+') do
	process_file(file)
  filecount = filecount+1
end
--]]




local out = {} -- { [ts] -> {X->{}, Y->{}} }

for f, d in pairs(data) do
  --print('------------', f)
  
  local sv = {}
  for tsd, v in pairs(d) do
    sv[#sv+1]=tsd
  end
  table.sort(sv, function(a, b) return a<b end)
  
  for _, tsd in ipairs (sv) do
    --for tsd, v in pairs(d) do
    local v=d[tsd]
    local x = 0
    for i=1, #v.X do
      x=x+v.X[i]
    end
    x=x/#v.X
  
    local y = 0
    for i=1, #v.Y do
      y=y+v.Y[i]
    end
    y=y/#v.Y

    --print(tsd, x, y)
    if not out[tsd] then
      out[tsd] = {['X']={x}, ['Y']={y}}
    else
      if #v.X>0 then out[tsd].X[#out[tsd].X+1] = x end
      if #v.Y>0 then out[tsd].Y[#out[tsd].Y+1] = y end
    end
    
  end
end


local f
f = io.open('buffocup.out', 'w')
local sv = {}
for tsd, v in pairs(out) do
  sv[#sv+1]=tsd
end
table.sort(sv, function(a, b) return a<b end)
for _, tsd in ipairs (sv) do
  --for tsd, v in pairs(d) do
  local v=out[tsd]
  
  --local medianx, lowx, highx = stats.median(v.X)
  --local mediany, lowy, highy = stats.median(v.Y)    
  --local medianx, lowx, highx = stats.avgstd(v.X)
  --local mediany, lowy, highy = stats.avgstd(v.Y)
  
  local _, lowx, highx = stats.median(v.X)
  local _, lowy, highy = stats.median(v.Y)    
  local medianx, _,_ = stats.avgminmax(v.X)
  local mediany, _,_ = stats.avgminmax(v.Y)
  
    
  --print (tsd, medianx, lowx, highx, mediany, lowy, highy)
  
  if medianx and lowx and highx and mediany and lowy and highy then
    f:write(tsd..' '..medianx..' '..lowx..' '..highx..' '..mediany..' '..lowy..' '..highy..'\n')
    --print (tsd, medianx, lowx, highx, mediany, lowy, highy)
  end
  
end
f:close()

f = io.open('delivery.out', 'w')
--print ('sent', n_sent)
for k, v in pairs(arrived) do
  --local med, low, high = stats.median(v)
  local med, low, high = stats.avgstd(v)

  if med and low and high then
    f:write(k..' '..med..' '..low..' '..high..' '..med-low..'\n')
  end
  --print ('arrived',k, avg, dev)
end
f:close()

f = io.open('community.out', 'w')
--comlabels[ts][mid]=label
local labelsort = {}
for ts, v in pairs(comlabels) do
  labelsort[#labelsort+1] = {ts=ts, labelreg = v}
end
table.sort(labelsort, function(a, b) return a.ts<b.ts end)

local currentlabel =  {} --currentlabel[ts][mid] = label
for i=0, 13 do currentlabel[i]=i end

for i, reg in ipairs(labelsort) do
  currentlabel[reg.ts]=currentlabel[reg.ts] or {}
  for mid, label in pairs(reg.labelreg) do
    print ('@@@@@@@', reg.ts, mid, label)
    currentlabel[reg.ts][mid] = label
  end
  
  f:write(reg.ts)
  for lid=1, 13 do
    local label =  'node'..lid
    f:write(tostring(' '..label))
    local countX, countY = 0,0
    for mid = 4,8 do
      if currentlabel[reg.ts][mid] == label then countX=countX+1 end
    end
    for mid = 9,13 do
      if currentlabel[reg.ts][mid] == label then countY=countY+1 end
    end
    f:write(tostring(' '..countX..' '..countY))
  end
  f:write('\n')

end
f:close()


local avgst = {}
local cntst = {}

--[[
for _, f in pairs(n_arrvided_st) do
  for fid, count in pairs (f) do
    datast[fid] = (datast[fid] or 0) + count
  end
end
for fid, count in pairs (datast) do
  datast[fid] = datast[fid] / (60-25+1)
  print ('ZZZZZ data', fid, datast[fid])
end
--]]

for k, f in pairs(n_arrvided_st) do
  for fid, count in pairs (f) do
    f[fid] = count/(60-25+1)
    cntst[fid] = (cntst[fid] or 0) + 1
    --print ('??', fid, f[fid], cntst[fid])
  end
end


for _, f in pairs(n_arrvided_st) do
  for fid, count in pairs (f) do
    avgst[fid] = (avgst[fid] or 0) + count
  end
end
for k, count in pairs (avgst) do
  local avg = avgst[k] / cntst[k] 
  avgst[k] = avg
  --print ('ZZZZZ', k, avg, avgst[k], cntst[k], avgst[k] / cntst[k])
end
local stdst = {}
for _, f in pairs(n_arrvided_st) do
  for fid, count in pairs (f) do
    stdst[fid] = (stdst[fid] or 0) + (count-avgst[fid])^2
  end
end
for k, count in pairs (stdst) do
  stdst[k] = stdst[k] / cntst[k]
end


f = io.open('delivery_st.out', 'w')
--for k, v in pairs(n_arrvided_st) do
--  f:write(k..' '..v..' '..(v/(60-25+1)/filecount)..'\n')
--end
for k, v in pairs(avgst) do
  f:write('> '..k..' '..v..' '..math.sqrt(stdst[k])..'\n')
end
f:close()

--[[
f = io.open('delivery_m.out', 'w')
--arrived_m[fid][nseq] = (arrived_m[fid][nseq] or 0) + 1
table.sort(arrived_m, function(a, b) return a<b end)
for mid=1,60 do
  local v1 = arrived_m[ arrived_m[1] ]
  local v2 = arrived_m[ arrived_m[2] ]
  print ('----> ', mid, v1[mid]/filecount, v2[mid]/filecount)
  f:write(mid..' '..v1[mid]/filecount..' '..v2[mid]/filecount..'\n')
end
f:close()
--]]

f = io.open('delivery_m.out', 'w')
--arrived_m[fid][nseq] = (arrived_m[fid][nseq] or 0) + 1
table.sort(arrived_m, function(a, b) return a<b end)
for mid=0,5 do
  f:write(10*mid+5)
  for i = 1, 2 do
    local v = arrived_m[arrived_m[i]]
    local vv = {}
    for j = 1,10 do
      vv[j] = v[10*mid + j]/filecount
    end
    --local avg, low, high = stats.median(vv)
    local avg, _, _= stats.avgstd(vv)
    local _, low, high = stats.median(vv)   
    f:write(' '..avg..' '..low..' '..high)
  end
  f:write('\n')
end
f:close()


--delivery_tot[fid][idt][filenumber] = (delivery_tot[fid][idt][filenumber] or 0) + 1
f = io.open('delivery_w.out', 'w')
for idt=0, 5 do
  f:write(''.. idt*10+5 ..' ')
  for _, fid in pairs(delivery_tot) do
    local t = {}
    for _, tots in pairs(fid[idt] or {}) do
      t[#t+1]=2*tots/20
    end
    local avg, low, high = stats.avgstd(t)
    --local _, low, high = stats.median(t) 
    f:write(' '..avg..' '..low..' '..high)
  end
  f:write('\n')
end
f:close()

deliveryall:close()
