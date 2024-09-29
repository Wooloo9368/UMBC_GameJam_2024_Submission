local function defaultStats()
	local default = {
		['Walkspeed'] = 16,
		['Runspeed'] = 26,
		['JumpPower'] = 50,
		['Gravity'] = 196.2,
		['Jumps'] = 0,
		['CurrentCheckpoint'] = 0,
		['EquippedItem'] = nil;
		['Inventory'] = {},
	}
	return default
end

local pStats = {} 
local pStatsMT = {}
local statList = {} 

function pStatsMT:__index(stat)
	return statList[self[1]][stat] 
end

--activates when a stat is changed
function pStatsMT:__newindex(stat, value)
	local plr = self[1]
	statList[plr][stat] = value
end

function pStats:Add(plr)
	local stats = defaultStats()
	statList[plr] = stats
	self[plr] = stats--setmetatable({plr}, pStatsMT)
end

function pStats:Remove(plr)
	pStats[plr] = nil
	statList[plr] = nil
end

return pStats
