local reactor = peripheral.wrap("back")

function table_sort(tosort)
  local temp = {}
  for key in pairs(tosort) do
    table.insert(temp, key)
  end
  table.sort(temp)
  
  for i = 0, #temp do
    temp[i] = tosort[temp[i]]
  end
  
  return temp
end

function get_rods()
  local rods = {}
  for r = 0, reactor.controlRodCount() - 1 do
    rods[reactor.getControlRod(r).name()] = r
  end
  
  return rods
end

function getn_keyed(tab)
  local x = 0
  for _, _ in pairs(tab) do
    x = x + 1
  end
  
  return x
end

function updateGroup(groups, grouping, row, id)
  groups[grouping][row] = id
  return groups
end

function writeline(...)
  local x, y = term.getCursorPos()
  local toPrint = ""
  for i = 1, #arg do
    toPrint = toPrint..arg[i]
  end
  
  term.write(toPrint.."")
  term.setCursorPos(x, y + 1)
end

function get_groupings()
  local rods = get_rods()
  local groups = {}
  
  for rod, id in pairs(rods) do
    local grouping = string.match(rod, "(%d+)")
    local temp = {}
	
	if (groups[grouping] == nil) then
	  groups[grouping] = {}
	end
	
	groups[grouping][rod] = id
  end
  
  return groups
end

function rf_delta()
  buff_a = reactor.battery().stored()
  sleep(0.05)
  buff_b = reactor.battery().stored()
  return buff_b - buff_a
end

function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

function startup()
  clear()
  writeline("Starting Up NucleBrain.")
  
  reactor.setAllControlRodLevels(100)
  writeline("Control Rods Engaged At: "..reactor.getControlRod(0).level().."% Insertion.")
  
  reactor.setActive(true)
  writeline("Reactor Online.")
  
  local b = reactor.battery().stored()
  writeline("Startup Complete.")
  
  sleep(0.25)
  return b
end

function shutdown()
  clear()
  writeline("Shutting Down NucleBrain.")
  
  reactor.setAllControlRodLevels(100)
  writeline("Control Rods Disengaged.")
  
  reactor.setActive(false)
  writeline("Reactor Disabled.\n Have a nice day.")
  
  sleep(0.5)
  clear()
end

function avgControlRodLevel()
  n = reactor.controlRodCount()
  avg = 0
  for r = 0, n - 1 do
    avg = avg + reactor.getControlRod(r).level()
  end
  
  return math.floor(avg / n)
end

function status()
  if (reactor.active()) then
    return "On"
  end
  
  return "Off"
end

function gui()
  clear()
  writeline("-----NucleBrain V1.0.0-----")
  writeline("Reactor Status: "..status())
  writeline("RF Output: "..reactor.battery().producedLastTick().." RF/t")
  writeline("Average Insertion: "..avgControlRodLevel().."%")
  writeline("Fuel Cons.: "..reactor.fuelTank().burnedLastTick().." mB/t")
  writeline("Quit: 'x', Toggle Power: 't'")
end

function handleEvents()
  repeat
    local _, key = os.pullEvent()
    
    if key == keys.t then
      reactor.setActive(not reactor.active())
	  
	  sleep(0.15)
    end
      
  until key == keys.x
end

--Main Code--
----Declare Globals----
local buffer = startup()
local groups = get_groupings()
local keys = {}
local groupKeys = {}

function init()
  groups = get_groupings()

  for group, rods in pairs(groups) do
    for rod in pairs(rods) do
      table.insert(keys, rod)
    end
    
    table.insert(groupKeys, group)
  end
end

function main()
  init()
  local isStartup = true --This keeps other groups from eroniously firing prematurely
  local hotGroup = 1
  
  while true do
	gui()
	local x = 0
    for rod, id in pairs(groups[groupKeys[hotGroup]]) do
      level = reactor.getControlRod(id).level()
	  
      if (rf_delta() > 0 and level < 100) then
        reactor.getControlRod(id).setLevel(level + 1)
      elseif (level > 0) then
        reactor.getControlRod(id).setLevel(level - 1)
      end
	  
	  x = x + 1
	  
      if (x >= getn_keyed(groups[groupKeys[(hotGroup)]]) and not isStartup) then
        if (level <= 0 and rf_delta() <= 0) or level >= 100 then
          hotGroup = hotGroup + 1
        end
	  elseif isStartup then
	    isStartup = false
      end
    end
	
	sleep(0.1)
	
	if hotGroup > getn_keyed(groups) then
	  hotGroup = 1
	end
  end
end

parallel.waitForAny(main, handleEvents)
shutdown()
