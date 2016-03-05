local name = (instead_savepath() .. '/world');
local name_tmp = (name..'.tmp')
local name_tmp2 = (name..'.tmp2')
active_size = 100
table.contains = function(tab, val, isarg)
	if isarg then
		for i=1, tab.n do
			if tab[i] == val then
				return true, i
			end;
		end;
	else
		for i in pairs(tab) do
			if tab[i] == val then
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
	cache_write = function(s, room, x, y, z)
		if s.cache[x] == nil then
			s.cache[x] = {}
		end
		if s.cache[x][y] == nil then
			s.cache[x][y] = {}
		end
		s.cache[x][y][z] = room
	end;
	write_sync = function(s, room, x, y, z)
		s:cache_write(room, x, y, z);
		s:save_room(x, y, z, room)
	end;
	cache_read = function(s, x, y, z)
		return s.cache[x][y][z]
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
	cache_exist = function(s, x, y, z)
		return not (s:cache_read(x, y, z))
	end;
	load = function(s, ...)
		local tabs = {s:read(...)}
		for i,tfunc in tabs do
			local func = stead.eval(tfunc);
			func()
		end;
	end;
	read = function(s, ...)
--		xt, yt, zt = tostring(x), tostring(y), tostring(z)
		local hr = stead.io.open(name, "r");
		local tables={};
		local curtext='';
		local readernum = 1;
		local copy=false;
		local tab = {...};
		openers = {};
		closers = {};
		for n,i in pairs(arg) do
			tables[i]=''; --ТУТ: хак для stead.unpack
			table.insert(openers, i, string.format('-- <room %s.%s.%s', i[1], i[2], i[3]))
			table.insert(closers, i, string.format('-- room %s.%s.%s>', i[1], i[2], i[3]))
		end;
		for line in hr:lines() do
			local openif, opennum = table.contains(openers, line);
			local closeif, closenum = table.contains(openers, line);
			if copy == 'next' then
				copy = true;
			end;
			if openif then
				readernum=opennum;
				copy='next';
			elseif closeif then
				copy = false;
				tables[readernum]=curltext;
				curltext = ''
			end;
			if copy == true then
				curltext = (curltext..line..'\n');
			end;
		end;
		hr:close();
		return stead.unpack(tables)
	end;
	del = function(s, x, y, z)
--		xt, yt, zt = tostring(x), tostring(y), tostring(z)
		stead.os.rename(name, name_tmp2);
		local hr = stead.io.open(name_tmp2, "r");
		local hw = stead.io.open(name_tmp, "w");
		local copy = true;
		for line in hr:lines() do
			if line == string.format('-- <room %s.%s.%s', x, y, z) then
				copy = false;
			elseif line == string.format('-- room %s.%s.%s>', x, y, z) then
				copy = 'wait';
			elseif copy == 'wait' then
				copy = true;
			end;
			if copy == true then
				hw:write(line, '\n');
			end;
		end;
		hw:flush();
		hr:close();
		hw:close();
		stead.os.remove(name_tmp2);
		stead.os.rename(name_tmp, name);
	end;
	save_room = function(s, x, y, z, room)
		
		if s:exist(x, y, z) then
			s:del(x, y, z)
		end;
		local h = io.open(name, 'w')
		h:write(string.format('-- <room %s.%s.%s', x, y, z), '\n');
		stead.savemembers(h, room, string.format('saver.cache[%s][%s][%s]', x, y, z), true);
		h:write(string.format('-- room %s.%s.%s>', x, y, z), '\n');
		h:flush();
		h:close();
	end;
	get = function(s, x, y, z)
		if s:cache_exist(x, y, z) then
			return s:cache_read(x, y, z)
		end;
	end;
	save = function(s)
		if here().place then
			s:save_room(x, y, z, here());
		end;
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
			elseif need then
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

savemembers = function(s, h, self, name)
	local need = true
	local neednam = true
	local k,v
	if isObject(self) and need then
		h:write(string.format('%s = obj { nam = %s };', name, s:var_in_save(self, 'nam', true)), '\n')
		neednam = false;
	end;
	for k,v in stead.pairs(self) do
		if k ~= "__visited__" then
			local varnam;
			if stead.type(k) == 'string' then
				varnam = (stead.string.format("%q",k));
			elseif stead.type(k) == 'number' then
				varnam = (k)
			elseif stead.type(k) == 'table' and stead.type(k.key_name) == 'string' then
				varnam = (k.key_name)
			end
			if varnam == 'nam' or not neednam then
				return
			end;
			if stead.type(k) == 'string' then
				stead.savevar(h, v, name..'['..stead.string.format("%q",k)..']', need);
			elseif stead.type(k) == 'number' then
				stead.savevar(h, v, name.."["..k.."]", need)
			elseif stead.type(k) == 'table' and stead.type(k.key_name) == 'string' then
				stead.savevar(h, v, name.."["..k.key_name.."]", need)
			end
		end
	end
end

stead.savevar = function(h, v, n, need)
	local r,f

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
			h:write(string.format('%s=stead.eval(%q)\n', n, string.dump(v)))
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
		if stead.type(v.key_name) == 'string' and v.key_name ~= n then -- just xref
			if v.auto_allocated and not v.auto_saved then
				v:save(v.key_name, h, false, true); -- here todo
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
			v:save(n, h, need);
			return;
		end

		if need then
			h:write(n.." = {};\n");
		end

		stead.savemembers(h, v, n, need);
		return;
	end

	if not need then
		return
	end
	h:write(n, " = ",tostring(v))
	h:write("\n") 
end

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
						return saver:save_room(xloc, yloc, zloc, room)
					end;
				})
			end;
		})
	end;
})
