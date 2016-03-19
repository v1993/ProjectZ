-- $Name: ProjectZ$
-- $Version: 0.1$
-- $Author: Очинский Валерий$
require 'lib/saver'
require 'lib/actway'
require 'lib/funclink'
require 'timer'
instead_version "2.3.0"
start = {}
global {x = 0, y = 0, z = 0};
--start_game = function()
--	cron:start()
--end;
main = room {
	nam = 'Давай!';
	obj = {obj {nam = 'ok', dsc = '{Начать игру!}', act = code [[return start_game()]]}};
};

stead.room_save = function(self, name, h, need)
	local dsc;
	stead.savemembers(h, self, name, need);
end

stead.obj_save = function(self, name, h, need)
	local dsc;
	stead.savemembers(h, self, name, need);
end

start_game = function()
	x = start.x;
	y = start.y;
	z = start.z;
	lifeon(walker);
	walk(world[x][y][z])
end;

syncwalk = code [[if here().x ~= x or here().y ~= y or here().z ~= z then walk (world[x][y][z]) end;]]

walker = obj {
	nam = 'walker';
	life = code [[syncwalk(); return true,true]];
};

start = {};

-- Это пишет разработчик...
start.world = 'overworld' -- Игрок заспавнится в этом мире
start.x = 0 -- Стартовые коардинаты
start.y = 0
start.z = 60
-- test

testgen = obj {nam = 'testgen'};
generator = 'testgen'
testgen.way = function()
	return {actway('x+1', code [[x=x+1;syncwalk()]]),actway('x-1', code [[x=x-1;syncwalk()]]),actway('y+1', code [[y=y+1;syncwalk()]]),actway('y-1', code [[y=y-1;syncwalk()]]),actway('z+1', code [[z=z+1;syncwalk()]]),actway('z-1', code [[z=z-1;syncwalk()]])};
end;
testgen.new = function(s, x, y, z)
	local v = {};
	v.x=x;
	v.y=y;
	v.z=z;
	v.save = function(self, name, h, need)
		local dsc;
		stead.savemembers(h, self, name, need);
	end;
	v.nam = ('Комната:'..tostring(x)..'.'..tostring(y)..'.'..tostring(z));
	v.dsc = 'test room';
	v.key_name = ('world['..tostring(x)..']['..tostring(y)..']['..tostring(z)..']');
	v.way = s.way();
	return room(v)
end;
