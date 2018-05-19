--toggle this to turn logging on or off.
isLogAllowed = false --:boolean




--v function(text: string)
function GETAWAYLOG(text)
    ftext = "beastmen getaway"

    if not isLogAllowed then
      return;
    end

  local logText = tostring(text)
  local logContext = tostring(ftext)
  local logTimeStamp = os.date("%d, %m %Y %X")
  local popLog = io.open("GETAWAY.txt","a")
  --# assume logTimeStamp: string
  popLog :write("df_politics_main:  "..logText .. "    : [" .. logContext .. "] : [".. logTimeStamp .. "]\n")
  popLog :flush()
  popLog :close()
end

--# assume global class GET_AWAY_MANAGER
local getaway = {} --# assume getaway: GET_AWAY_MANAGER


--v function(human_faction_name: string) --> GET_AWAY_MANAGER
function getaway.new(human_faction_name)
    local self = {}
    setmetatable(self, {
        __index = getaway
    })

    GETAWAYLOG("Creating a getaway manager for ["..human_faction_name.."] ")
    --# assume self: GET_AWAY_MANAGER
    self.faction_name = human_faction_name;
    self.faction_interface = get_faction(human_faction_name)
    self.force_list = get_faction(human_faction_name):military_force_list()
    self.num_hordes = get_faction(human_faction_name):military_force_list():num_items()
    self.war_list = get_faction(human_faction_name):factions_at_war_with();

    return self

end

--v function(self: GET_AWAY_MANAGER)
function getaway.update_num_hordes(self)
    self.num_hordes = get_faction(self.faction_name):military_force_list():num_items()
end

--v function(self: GET_AWAY_MANAGER)
function getaway.update_war_list(self)
    self.war_list = get_faction(self.faction_name):factions_at_war_with();
end

--v function(self: GET_AWAY_MANAGER, ax: number, ay: number, bx: number, by: number) --> number
function getaway.calc_distance(self, ax, ay, bx, by)
    GETAWAYLOG("2D distance was ["..tostring((((bx - ax) ^ 2 + (by - ay) ^ 2) ^ 0.5)).."]")
	return (((bx - ax) ^ 2 + (by - ay) ^ 2) ^ 0.5);
end;

--v function(self: GET_AWAY_MANAGER, faction: CA_FACTION) --> boolean
function getaway.check_army_proximity_to_player(self, faction)
    GETAWAYLOG(" seeing if we got away from ["..faction:name().."]'s armies ")
    local army_list = faction:military_force_list()
    retval = true --:boolean
    for i = 0, army_list:num_items() - 1 do
        local force_general = army_list:item_at(i):general_character()
        for j = 0, self.num_hordes - 1 do
            local player_character = self.force_list:item_at(j):general_character()
            if self:calc_distance(force_general:logical_position_x(), force_general:logical_position_y(), player_character:logical_position_x(), player_character:logical_position_y()) < 160  then
                retval = false
                break;
            end
        end
    end
    GETAWAYLOG("army check returning ["..tostring(retval).."] ")
    return retval
end

--v function(self: GET_AWAY_MANAGER, faction: CA_FACTION) --> boolean
function getaway.check_region_proximity_to_player(self, faction)
    GETAWAYLOG(" seeing if we got away from ["..faction:name().."]'s regions ")
    local region_list = faction:region_list()
    retval = true 
    for i = 0, region_list:num_items() - 1 do
        local settlement = region_list:item_at(i):settlement()
        for j = 0, self.num_hordes - 1 do
            local player_character = self.force_list:item_at(j):general_character()
            if self:calc_distance(settlement:logical_position_x(), settlement:logical_position_y(), player_character:logical_position_x(), player_character:logical_position_y()) < 160  then
                retval = false
                break;
            end
        end
    end
    GETAWAYLOG("region check returning ["..tostring(retval).."] ")
    return retval

end

--102
--v function(self: GET_AWAY_MANAGER, faction_name: string)
function getaway.got_away(self, faction_name)


    GETAWAYLOG(" ["..self.faction_name.."] got away safely from ["..faction_name.."], triggering their message and peace ")
--[[
    cm:show_message_event(
    self.faction_name,
    "escape_text",
    "factions_screen_name_"..faction_name,
    "escape_detail",
    102
    ]]--
    cm:force_make_peace(faction_name, self.faction_name)
end


--v function(self: GET_AWAY_MANAGER)
function getaway.activate(self)
    GETAWAYLOG("activating the get away manager for ["..self.faction_name.."] ")
    core:add_listener(
        "getaway"..self.faction_name,
        "FactionTurnStart",
        function(context)
           return context:faction():name() == self.faction_name
        end,
        function(context)
            GETAWAYLOG("checking getaway status for ["..self.faction_name.."] ")
            self:update_num_hordes()
            self:update_war_list()
            for x = 0, self.war_list:num_items() - 1 do
                local current_faction = self.war_list:item_at(x)
                if self:check_army_proximity_to_player(current_faction) and self:check_region_proximity_to_player(current_faction) then
                    self:got_away(current_faction:name())
                end
            end
        end,
        true)
end


--v function()
function beastmen_getaway()
    output("beastmen getaway mod is active")
    GETAWAYLOG("starting a session")
    local humans = cm:get_human_factions()
    GETAWAYLOG("1")

    GETAWAYLOG("2")
    for i = 1, #humans do
        GETAWAYLOG("3")
        if get_faction(humans[i]):subculture() == "wh_dlc03_sc_bst_beastmen" then
            GETAWAYLOG("4")
            local manager = getaway.new(humans[i])
            GETAWAYLOG("5")
            manager:activate()
            GETAWAYLOG("6")
            output("BGM success!")
        end
    end
end