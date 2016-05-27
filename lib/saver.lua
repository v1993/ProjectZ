global {world_file_name = (instead_savepath() .. '/tmp_world_default')};
global {world_file_name_tmp = (world_file_name..'.tmp')};
global {world_file_name_tmp2 = (world_file_name..'.tmp2')};
active_size = 4
centre_x = 0
centre_y = 0
centre_z = 0

print_cachesize = function()
	local size = 0;
	for x,y,z in saver:cache_iter_full() do
		size=size+1
	end
	print(size)
end;

change_world = function(world)
	s:cache_sync();
	s:cache_clear();
	world_file_name = (instead_savepath() .. '/tmp_world_'..world);
	world_file_name_tmp = (name..'.tmp');
	world_file_name_tmp2 = (name..'.tmp2');
	s:cache_fill();
end;

table.contains = function(tab, val, isarg)
	if isarg then
		for i=1, tab.n do
			if tab[i] == val then
				return true, i
			end;
		end;
	else
		for i,v in pairs(tab) do
			if v == val then
				return true, i
			end;
		end;
	end;
	return false
end;
saver = obj {
	nam = 'saver';
	cache = {};
	cache_clear = function(s)
		s.cache = {};
	end;
	cache_iter_full = function(s)
		local f = function()
			for x,v1 in pairs(s.cache) do
				for y,v2 in pairs(v1) do
					for z,v3 in pairs(v2) do
						coroutine.yield(x,y,z)
					end;
				end;
			end;
		end;
		return coroutine.wrap(f)
	end;
	cache_iter = function()
		local f = function()
			for x=x-active_size,x+active_size do
				for y=y-active_size,y+active_size do
					for z=z-active_size,z+active_size do
						coroutine.yield(x,y,z)
					end
				end
			end
		end;
		return coroutine.wrap(f)
	end;
	cache_iter_for_fill = function(s)
		local f = function()
			for xl,yl,zl in saver:cache_iter() do
				if not s:cache_exist(xl, yl, zl) then
					coroutine.yield(xl,yl,zl)
				end
			end;
		end;
		return coroutine.wrap(f)
	end;
	cache_clear_unactual = function(s)
--		print('Clearing...')
		for xl, yl, zl in s:cache_iter_full() do
--			print(centre_x, centre_y, centre_z)
--			print(not s:cache_need(xl, yl, zl, centre_x, centre_y, centre_z), xl, yl, zl)
			if not s:cache_need(xl, yl, zl, centre_x, centre_y, centre_z) and s.cache[xl] ~= nil and s.cache[xl][yl] ~= nil then
--				print('Clear '..tostring(xl)..' '..tostring(yl)..' '..tostring(zl))
				s.cache[xl][yl][zl] = nil
			end;
			stead.busy (true)
		end
--		print '..OK!'
	end;
	cache_write = function(s, room, x, y, z)
		if s.cache[x] == nil then
			s.cache[x] = {}
		end
		if s.cache[x][y] == nil then
			s.cache[x][y] = {}
		end
		s.cache[x][y][z] = room
	end;
	cache_sync = function(s, onlyunactual)
--		print('writing!');
		local tab = {};
		for x,y,z in s:cache_iter_full() do
			if not onlyunactual or not s:cache_need(x, y, z, centre_x, centre_y, centre_z) then
--				print(x,y,z)
				table.insert(tab, {x, y, z, saver.cache[x][y][z]})
				stead.busy(true);
			end;
		end;
--		print (#tab)
		s:save_room(stead.unpack(tab));
	end;
	cache_fill = function(s)
--		print('filling!');
		local tab = {};
		for xl, yl, zl in s:cache_iter_for_fill() do
--			print (xl,yl,zl)
			table.insert(tab, {xl, yl, zl})
			stead.busy (true)
		end;
--		print (#tab)
--		print 'Table gen OK, loading!'
		stead.busy(true);
		empty = {s:load(stead.unpack(tab))};
		stead.busy(true);
--		print 'Load ok!'
--		print (#empty)
		for i,k in pairs(empty) do
			if not s:cache_exist(k[1], k[2], k[3]) then
--				print(k[1], k[2], k[3]);
				s:cache_write (stead.ref(generator):new(k[1], k[2], k[3]), k[1], k[2], k[3])
				stead.busy(true);
			end;
		end;
		stead.busy(true);
	end;
	write_sync = function(s, room, x, y, z)
		s:cache_write(room, x, y, z);
		s:save_room({x, y, z, room})
		return room
	end;
	cache_read = function(s, x, y, z)
		return s.cache[x] and s.cache[x][y] and s.cache[x][y][z]
	end;
	read_sync = function(s, x, y, z)
		if not s:cache_exist(x, y, z) then
			s:load({x, y, z})
		end;
		return s:cache_read(x, y, z)
	end;
	cache_need = function(s, x, y, z, xl, yl, zl)
		return (math.abs(x-xl) <= active_size) and (math.abs(y-yl) <= active_size) and (math.abs(z-zl) <= active_size)
	end;
	exsist = function(s, ...)
		local tab = {...};
		local hr = stead.io.open(world_file_name, "r");
		local tables = {};
		openers = {};
		for n,i in pairs(tab) do
			tables[n]=false; --ТУТ: хак для stead.unpack
			table.insert(openers, n, string.format('-- <room %s.%s.%s', i[1], i[2], i[3]))
		end;
		if hr == nil then
			return stead.unpack(tables)
		end;
		for line in hr:lines() do
			local openif, opennum
			if string.sub(line, 1, 2) == '--' then
				openif, opennum = table.contains(openers, line);
			end
			if openif then
				tables[opennum]=true;
			end
		end;
		hr:close();
		return stead.unpack(tables)
	end;
	cache_exist = function(s, x, y, z)
		return not not (s:cache_read(x, y, z))
	end;
	load = function(s, ...)
		local inp = {...};
		local tabs = {s:read(...)};
--		print(tabs);
		local empty = {};
		for i,tfunc in pairs(tabs) do
			if tfunc == '' or tfunc == nil then
				table.insert(empty, inp[i])
			else
--				print(inp[i][1], inp[i][2], inp[i][3])
--				print(tfunc)
				local func = stead.eval(tfunc);
				func()
			end;
		end;
--		print(empty[1][1])
		return stead.unpack (empty)
	end;
	read = function(s, ...)
		stead.busy(true);
--		xt, yt, zt = tostring(x), tostring(y), tostring(z)
		local hr = stead.io.open(world_file_name, "r");
		local tables={};
		local curtab={};
		local readernum = 1;
		local copy=false;
		local tab = {...};
		openers = {};
		closers = {};
		for n,i in pairs(tab) do
			tables[n]=''; --ТУТ: хак для stead.unpack
			table.insert(openers, n, string.format('-- <room %s.%s.%s', i[1], i[2], i[3]))
			table.insert(closers, n, string.format('-- room %s.%s.%s>', i[1], i[2], i[3]))
		end;
		if hr == nil then
			return stead.unpack(tables)
		end;
--		print 'Reading!'
		for line in hr:lines() do
			local openif, opennum, closeif, closenum
			if string.sub(line, 1, 2) == '--' then
				openif, opennum = table.contains(openers, line);
				closeif, closenum = table.contains(closers, line);
			end
			if copy == 'next' then
				copy = true;
			end;
			if openif then
				readernum=opennum;
				copy='next';
			elseif closeif then
				copy = false;
				tables[readernum]=table.concat(curtab);
				curtab = {}
--				print('Table '..readernum..' read!')
			end;
			if copy == true then
				curtab[#curtab+1]=(line..'\n')
			end;
			stead.busy(true);
		end;
		hr:close();
		stead.busy(true);
		return stead.unpack(tables)
	end;
	del = function(s, ...)
		stead.busy(true);
--		xt, yt, zt = tostring(x), tostring(y), tostring(z)
		stead.os.rename(world_file_name, world_file_name_tmp2);
		local hr = stead.io.open(world_file_name_tmp2, "r");
		local hw = stead.io.open(world_file_name_tmp, "w");
		local tab = {...};
		local copy = true;
		openers = {};
		closers = {};
		for n,i in pairs(tab) do
			table.insert(openers, n, string.format('-- <room %s.%s.%s', i[1], i[2], i[3]))
			table.insert(closers, n, string.format('-- room %s.%s.%s>', i[1], i[2], i[3]))
			stead.busy(true);
		end;
		for line in hr:lines() do
			if string.sub(line, 1, 2) == '--' then
				local openif, opennum = table.contains(openers, line);
				local closeif, closenum = table.contains(openers, line);
			end
			if copy == 'next' then
				copy = true;
			end;
			if openif then
				copy=false;
			elseif closeif then
				copy = 'next';
			end;
			if copy == true then
				hw:write(line, '\n');
			end;
			stead.busy(true);
		end;
--				hw:write(line, '\n');

		hw:flush();
		hr:close();
		hw:close();
		stead.os.remove(world_file_name_tmp2);
		stead.os.rename(world_file_name_tmp, world_file_name);
		stead.busy(true);
	end;
	save_room = function(s, ...)
		stead.busy(true);
		local tabs = {...};
		local empty = {};
--		print (#tabs);
		for i,v in pairs({s:exsist(...)}) do
--			print('save:', tabs[i][1], tabs[i][2], tabs[i][3])
			if v then
				table.insert(empty, {tabs[i][1], tabs[i][2], tabs[i][3]})
				stead.busy(true);
			end;
		end;
--		print 'saving'
		if #empty > 0 then
--			print 'del';
			s:del(stead.unpack(empty))
			stead.busy(true);
		end;
		local h = io.open(world_file_name, 'a')
		for k,v in pairs (tabs) do
			local savefunc = savevarcreate(true)
			h:write(string.format('-- <room %s.%s.%s', v[1], v[2], v[3]), '\n');
			h:write(string.format('if saver.cache[%s] == nil then saver.cache[%s]={} end;', v[1], v[1]), '\n')
			h:write(string.format('if saver.cache[%s][%s] == nil then saver.cache[%s][%s]={} end;', v[1], v[2], v[1], v[2]), '\n')
			stead.savemembers(h, v[4], string.format('saver.cache[%s][%s][%s]', v[1], v[2], v[3]), true, savefunc);
			h:write(string.format('-- room %s.%s.%s>', v[1], v[2], v[3]), '\n');
			stead.busy(true);
		end;
		h:flush();
		h:close();
		stead.busy(true);
	end;
	get = function(s, x, y, z)
--		print 'get';
		local reade = s:cache_read (x, y, z);
		if reade ~= nil then
			return reade;
		end;
		stead.busy(true);
--		print_cachesize();
--		print 'reloading';
		centre_x = x;
		centre_y = y;
		centre_z = z;
		s:cache_sync(true);
		stead.busy(true);
--		print 'cache_sync OK';
		s:cache_clear_unactual();
		stead.busy(true);
--		print 'cache_clear OK';
		s:cache_fill();
		stead.busy(true);
--		print 'cache_fill OK';
--		print('collecting')
		collectgarbage('collect')
--		print('OK')
		stead.busy(false);
--		print_cachesize();
		return s:cache_read (x, y, z);
		
	end;
	save = function(s)
		s:cache_sync();
	end;
	var_in_save = function(s, v, n, need)
		local r,f
		local str = ''
--	local need = true;
		if v == nil or stead.type(v) == "userdata" or
				stead.type(v) == "function" then
			if isCode(v) and need then
				if stead.type(stead.functions[v].key_name) == 'string' 
					and stead.functions[v].key_name ~= n then
					str=(str..stead.string.format("%s", stead.functions[v].key_name))
				else
					str=(str..stead.string.format("code %q", stead.functions[v].code))
				end
			elseif stead.type(v) == 'function' and need then
				str=(str..string.format('stead.eval(%q)',  string.dump(v)));
			end
--		if need then
--			error ("Variable "..n.." can not be saved!");
--		end 
			return str
		end

--	if stead.string.find(n, '_') ==  1 or stead.string.match(n,'^%u') then
--		need = true;
--	end

		if stead.type(v) == "string" then
			if not need then 
				return
			end
			str=(str..stead.string.format('%q',v))
			return str;
		end
 	--[[
	if stead.type(v) == "table" then
		if v == _G then return end
		if stead.type(v.key_name) == 'string' and v.key_name ~= n then -- just xref
			if v.auto_allocated and not v.auto_saved then
				v:save(v.key_name, h, false, true); -- here todo
			end
			if need then
				if stead.ref(v.key_name) == nil then
					v.key_name = 'null'
				end
				str=(str..stead.string.format("%s = %s\n", n, v.key_name));
			end
			return
		end
		if v.__visited__ ~= nil then
			return
		end

		v.__visited__ = n;

		if stead.type(v.save) == 'function' then
			v:save(n, h, need);
			return;
		end

		if need then
			str=(str..n.." = {};\n");
		end

		stead.savemembers(h, v, n, need);
		return;
	end
]]--
		if not need then
			return
		end
		return (tostring(v))
	end;
};

stead.savemembers = function(h, s, name, need, func)
--	local need = true
--	local new = new
	local func = func or stead.savevar
	local neednam = true
	local k,v
	if isObject(s) and need then
		h:write(string.format('%s = obj { nam = %s };', name, saver:var_in_save(s.nam, 'nam', true)), '\n')
		neednam = false;
	end;
	
--	print (name);
	for k,v in stead.pairs(s) do
		if k ~= "__visited__" then
			local need2 = false
			if isForSave(k, v, s) then
				need2 = true;
			end
			local varnam;
			if stead.type(k) == 'string' then
				varnam = (stead.string.format("%q",k));
			elseif stead.type(k) == 'number' then
				varnam = (k)
			elseif stead.type(k) == 'table' and stead.type(k.key_name) == 'string' then
				varnam = (k.key_name)
			end
			if varnam == 'nam' and not neednam then
				return
			end;
			if stead.type(k) == 'string' then
				func(h, v, name..'['..stead.string.format("%q",k)..']', need or need2, func);
			elseif stead.type(k) == 'number' then
				func(h, v, name.."["..k.."]", need or need2, func)
			elseif stead.type(k) == 'table' and stead.type(k.key_name) == 'string' then
				func(h, v, name.."["..k.key_name.."]", need or need2, func)
			end
		end
	end
end

savevarcreate = function(optimiz)
	local savedfunctions = {};
	local savedtabs = {};
	local optimiz = optimiz
--	print('It is opts' ,optimiz)
	return function(h, v, n, need, me)
--		print(optimiz)
		local r,f
--	if string.find(n,'trig') ~= nil then
--		print('Saving')
--	end;
--	print(h,v,n,need);
		if v == nil or stead.type(v) == "userdata" or
				stead.type(v) == "function" then
			if isCode(v) and need then
				if stead.type(stead.functions[v].key_name) == 'string' 
					and stead.functions[v].key_name ~= n then
					h:write(stead.string.format("%s=%s\n", n, stead.functions[v].key_name))
				else
					h:write(stead.string.format("%s=code %q\n", n, stead.functions[v].code))
				end
			elseif stead.type(v) == "function" and need then
				if savedfunctions[v] then
					h:write(string.format('%s=%s\n', n, savedfunctions[v]));
				else
					h:write(string.format('%s=stead.eval(%q)\n', n, string.dump(v)));
--					print('It is opts2' ,optimiz)
					if optimiz then
--						print(v,n)
						savedfunctions[v] = n
					end
				end;
			end
--		if need then
--			error ("Variable "..n.." can not be saved!");
--		end 
			return
		end

--	if stead.string.find(n, '_') ==  1 or stead.string.match(n,'^%u') then
--		need = true;
--	end

		if stead.type(v) == "string" then
			if not need then 
				return
			end
			h:write(stead.string.format("%s=%q\n",n,v))
			return;
		end
 	
		if stead.type(v) == "table" then
			if v == _G then return end
			if savedtabs[v] then
				h:write(stead.string.format("%s = %s\n", n, savedtabs[v]));
				return
			end
			if stead.type(v.key_name) == 'string' and v.key_name ~= n then -- just xref
				if v.auto_allocated and not v.auto_saved then
					v:save(v.key_name, h, false, true, me); -- here todo
				end
				if need then
					if stead.ref(v.key_name) == nil then
						v.key_name = 'null'
					end
					h:write(stead.string.format("%s = %s\n", n, v.key_name));
				end
				return
			end
			if v.__visited__ ~= nil then
				return
			end

			v.__visited__ = n;
			
			if stead.type(v.save) == 'function' then
--				print(n)
				v:save(n, h, need, me);
				return;
			end

			if need then
				h:write(n.." = {};\n");
			end
			savedtabs[v] = n
			stead.savemembers(h, v, n, need, me);
			return;
		end
--	if string.find(n, 'trig') ~= nil then
--		print('Saving')
--	end;

		if not need then
			return
		end
	
--	if string.find(n, 'trig') ~= nil then
--		print('Saving2')
--	end;
		h:write(n, " = ",tostring(v))
		h:write("\n") 
	end
end
--stead.savevar2 = savevarcreate()
--stead.savevar = function(...) ; print('Calling stead.savevar: ', ...);print(debug.traceback()); stead.savevar2(...) end
stead.savevar = savevarcreate()
-- Более удобный интерфейс, каскад метатаблиц

world = setmetatable({}, {
	__index = function(_, xloc)
		return setmetatable({}, {
			__index = function(_, yloc)
				return setmetatable({}, {
					__index = function(_, zloc)
						return saver:get(xloc, yloc, zloc)
					end;
					__newindex = function(_, zloc, room)
						return saver:cache_write (room, xloc, yloc, zloc)
					end;
				})
			end;
		})
	end;
})
stead.call = function(v, n, ...)
	if stead.type(v) ~= 'table' then
		error ("Call on non table object:"..stead.tostr(n), 2);
	end
	if v[n] == nil then
		return nil,nil;
	end
	if stead.type(v[n]) == 'string' then
		return v[n];
	end
	if stead.type(v[n]) == 'function' then
		stead.callpush(v, ...)
		local a,b = v[n](v, ...);
		-- boolean, nil
		if stead.type(a) == 'boolean' and b == nil then
			b, a = a, stead.pget()
			if a == nil then
				if stead.cctx().action then
					a = true
				else
					a = b
					b = nil
				end
			end 
		elseif a == nil and b == nil then
			a = stead.pget()
			b = nil
		end
		if a == nil and b == nil and stead.cctx().action then
			a = true
		end
		stead.callpop()
		return a,b
	end
	if stead.type(v[n]) == 'boolean' then
		return v[n]
	end
	return nil
end
-- Ну началось, модификация механизма сохранения/загрузки!


readiter = function(h, size)
	return function()
		return h:read(size) 
	end;
end;

-- copy_file -- угадай, что делает!

copy_file = function(from, to)
	local hfrom = io.open(from, 'r');
	if not hfrom then
		return false
	end;
	local hto = io.open(to, 'w');
	if not hto then
		return error('Can not open target file: '..to)
	end;
--	hto:write(hfrom:read('*a')); -- быстро, но жрёт память
	for data in readiter(hfrom, 268435456) do -- читать блоками по 256МБ
		hto:write(data)
		collectgarbage('collect')
	end;
	hto:flush();
	hto:close();
	hfrom:close();
	return true
end;

listdir = function(dir)
	local list = {};
	for f in stead.readdir(dir) do
		if f ~= '.' and f ~= '..' then
			table.insert(list, f)
		end
	end
	return list
end;

table.find = function(tab, regexp)
	local otab = {};
	for k,v in pairs(tab) do
		if string.find(v, regexp) ~= nil then
			table.insert(otab, v);
		end;
	end;
	return otab
end;

world_save = function(name)
	source_files = table.find(listdir(instead_savepath()), 'tmp_world_');
	target_files = {};
	for k,filename in ipairs(source_files) do
		table.insert(target_files, instead_savepath()..'/'..filename:gsub('tmp', ({string.match(name, "(.-)([^\\/]-%.?([^%.\\/]*))$")})[2]))
		source_files[k]=(instead_savepath()..'/'..filename)
	end;
	for k,from in ipairs(source_files) do
		local to = target_files[k]
		copy_file(from, to)
	end
end;

world_load  = function(name)
	local prefix = ({string.match(name, "(.-)([^\\/]-%.?([^%.\\/]*))$")})[2];
	
	source_files = table.find(listdir(instead_savepath()), prefix..'_world_');
	target_files = {};
	for k,filename in ipairs(source_files) do
		table.insert(target_files, instead_savepath()..'/'..filename:gsub(prefix, 'tmp'))
		source_files[k]=(instead_savepath()..'/'..filename)
	end;
	for k,from in ipairs(source_files) do
		local to = target_files[k]
		copy_file(from, to)
	end
end

stead.game_save = function(self, name, file) 
	local h;
	local func = savevarcreate(true)
	if file ~= nil then
		file:write(stead.string.format("%s.pl = %q\n", name, stead.deref(self.pl)));
		stead.savemembers(file, self, name, false, func);
		return nil, true
	end

	if not isEnableSave() then
		return nil, false
	end

	if name == nil then
		return nil, false
	end
	h = stead.io.open(name,"wb");
	if not h then
		return nil, false
	end
	local n
	if stead.type(stead.savename) == 'function' then
		n = stead.savename()
	end
	if stead.type(n) == 'string' and n ~= "" then
		h:write("-- $Name: "..n:gsub("\n","\\n").."$\n");
	end
--	stead.savevar(setmetatable({}, {__index = function() return function() end end}), '', '', false, true) -- Стереть функции
	stead.do_savegame(self, h, func);
	h:flush();
	h:close();
	if name ~= 'game' then
		world_save(name) -- Занимается копированием файлов
	end;
	game.autosave = false; -- we have only one try for autosave
	game.restart_game = false
	return nil;
end
game.save = stead.game_save
stead.game_load = function(self, name)
	if name == nil then
		return nil, false
	end
	world_load(name);
	local f, err = loadfile(name);
	if f then
		local i,r = f();
		if r then
			return nil, false
		end
		i, r = stead.do_ini(self, true);
		if not stead.started then
			game:start()
			stead.started = true
		end
		return i, r
	end
	return nil, false
end
game.load = stead.game_load

stead.do_savegame = function(s, h, func)
	stead.busy(true)
	local func = func or savevarcreate(true)
	local function save_object(key, value, h)
		stead.busy(true)
--		print(func)
		func(h, value, key, false, func);
	end
	local function save_var(key, value, h)
		stead.busy(true)
		func(h, value, key, isForSave(key, value, _G), func)
	end
	local forget = game.scriptsforget
	local i,v
	for i,v in stead.ipairs(s._scripts) do
		h:write(stead.string.format("stead.gamereset(%q,%s)\n", 
			v, stead.tostr(forget)))
		forget = nil
	end
	save_object('allocator', allocator, h); -- always first!
	for_each_object(save_object, h);
	save_object('game', s, h);
	for_everything(save_var, h);
--	save_object('_G', _G, h);
	stead.clearvar(_G);
	stead.busy(false)
end
