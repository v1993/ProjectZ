-- $Name: ProjectZ$
-- $Version: 0.1$
-- $Author: Очинский Валерий$
instead_version "2.3.0"
global {x = 0, y = 0, z = 0};
main = room {
	nam = 'Давай!';
	obj = {obj {nam = 'ok', dsc = '{Начать игру!}', act = code [[walk (actor_room)]]}};
};

function start ()
	local actor_roomf = function()
		if saver:exist(x, y, z) then
--[[
			local v = {};
			v.enter = function(s)
				saver:save_room(s, x, y, z)
				if saver:exist(x, y, z) then
					s = saver:load(x, y, z)
				else
					s = saver:new(x, y, z)
				end;
			end;
			]]--
			return saver:new(x, y, z)
		else
			return saver:load(x, y, z)
		end;
	end;
	actor_room = actor_roomf();
end


