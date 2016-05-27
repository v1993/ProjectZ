-- $Name: ProjectZ$
-- $Version: 0.1$
-- $Author: Очинский Валерий$
instead_version "2.4.1"
dofile 'lib/savefix.lua'
require 'dbg'
dofile 'lib/saver.lua'
require 'lib/actway'
require 'lib/funclink'
require 'timer'
finpath = instead_savepath();
finalizers = require 'lib/finalizers'
finalizers.create('Remove files', function()
	source_files = table.find(listdir(finpath), 'tmp_world_');
--	print(finpath)
--	print(#source_files)
	for k,filename in ipairs(source_files) do
		os.remove(finpath..'/'..filename)
	end;
end);
table.print = function(tab, rec, pref, basepref)
	local pref = pref or ''
	local basepref = basepref or '	'
	for k,v in pairs(tab) do
		if not rec or type(v) ~= 'table' then
			print(pref..tostring(k),v)
		else
			print(pref..tostring(k)..' ->')
			table.print(v, rec, pref..basepref, basepref)
		end;
	end;
end;

init = function() take (wayd) end
global {x = 0, y = 0, z = 0};
--start_game = function()
--	cron:start()
--end;
wayd = menu {
	nam = 'Дамп путей в терминал';
	menu = function(s)
		table.print(ways(), true)
	end;
};

main = room {
	nam = 'Давай!';
	obj = {obj {nam = 'ok', dsc = '{Начать игру!}', act = code [[return start_game()]]}};
};

trigger = function()
	local v = {};
	v.trigger = true;
	v.nam = "Типа объект"
	v.dsc = function(s) return ("{Что-то} тут есть. И оно "..tostring(s.trig)..'!') end
	v.act = function(s)
		s.trig = not s.trig;
		return "Щёлк!"
	end;
	v = obj(v)
	stead.add_var(v, {trig = false})
	return v
end;

start_game = function()
	x = startset.x;
	y = startset.y;
	z = startset.z;
	lifeon(walker);
	walk(world[x][y][z])
end;

syncwalk = code [[if here().x ~= x or here().y ~= y or here().z ~= z then walk (world[x][y][z]) end;]]

walker = obj {
	nam = 'walker';
	life = code [[syncwalk(); return true,true]];
};

startset = {};

-- Это пишет разработчик...
startset.world = 'overworld' -- Игрок заспавнится в этом мире
startset.x = 0 -- Стартовые коардинаты
startset.y = 0
startset.z = 60
-- test

testgen = obj {nam = 'testgen'};
generator = 'testgen'

testgen.new = function(s, x, y, z)
	local v = {};
	v.x=x;
	v.y=y;
	v.z=z;
	v.nam = ('Комната:'..tostring(x)..'.'..tostring(y)..'.'..tostring(z));
	v.dsc = 'test room';
	v.key_name = ('world['..tostring(x)..']['..tostring(y)..']['..tostring(z)..']');
	v.way = {actway('x+1', code [[x=x+1;syncwalk()]]),actway('x-1', code [[x=x-1;syncwalk()]]),actway('y+1', code [[y=y+1;syncwalk()]]),actway('y-1', code [[y=y-1;syncwalk()]]),actway('z+1', code [[z=z+1;syncwalk()]]),actway('z-1', code [[z=z-1;syncwalk()]])};
	v = room(v)
	put(new[[trigger()]], v)
--	print(x,y,z)
	return v
end;
--debug.sethook(function() table.print(debug.getinfo(2)) end, 'r')
