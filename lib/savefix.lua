stead.phrase_save = function(self, name, h, need, func)
	if need then
		local m = " = phr("
		if isDisabled(self) then
			m = " = _phr("
		end
		h:write(stead.string.format("%s%s%s,%s,%s);\n", 
			name, m, 
			stead.tostring(self.dsc), 
			stead.tostring(self.ans), 
			stead.tostring(self.do_act)));
	end
	stead.savemembers(h, self, name, false, func);
end

stead.menu_save = function(self, name, h, need, func)
	local dsc;
	stead.savemembers(h, self, name, need, func);
end
stead.vroom_save = function(self, name, h, need, func)
	if need then
		local t = stead.string.format("%s = vroom(%s, %q);\n",
			name, stead.tostring(self.nam), 
				stead.deref(self.where))
		h:write(t);
	end
	stead.savemembers(h, self, name, false, func);
end
stead.vobj_save = function(self, name, h, need, func)
	local w = stead.deref(self.where)
	local dsc = self.dsc
	
	if need then
		h:write(stead.string.format("%s  = vobj(%s,%s,%s);\n",
			name, 
			stead.tostring(self.nam), 
			stead.tostring(dsc), 
			stead.tostring(w)));
	end
	stead.savemembers(h, self, name, false, func);
end
stead.player_save = function(self, name, h, need,func)
--	print(func)
	h:write(stead.string.format('%s.where = %q;\n', stead.tostr(name), stead.deref(self.where)));
	stead.savemembers(h, self, name, false, func);
end
stead.allocator_save = function(s, name, h, need, func)
	if s.auto_allocated and not auto then
		return
	end
	if need then
		if s.auto_allocated then -- in current realization always false
			local m = stead.string.format("allocator:new(%s, %s)\n", 
				stead.tostring(s.constructor),
				stead.tostring(s.constructor));
			h:write(m);
		else
			local m = stead.string.format(" = allocator:get(%s, %s)\n",
				stead.tostring(name),
				stead.tostring(s.constructor));
			h:write(name..m);
			if stead.api_atleast(1, 3, 0) then
				m = stead.string.format("stead.check_object(%s, %s)\n",
					stead.tostring(name),
					name);
				h:write(m);
			end
		end
	end
	stead.savemembers(h, s, name, false, func);
	if s.auto_allocated then
		s.auto_saved = true
	end
end
stead.list_save = function(self, name, h, need, func)
--	if self.__modifyed__ or self.__modified__ then -- compat
		h:write(name.." = list({});\n");
		need = true;
--	end
	stead.savemembers(h, self, name, need, func);
end
stead.obj_save = function(self, name, h, need, func)
--	print(func)
	local dsc;
	stead.savemembers(h, self, name, need, func);
end
stead.room_save = function(self, name, h, need, func)
	local dsc;
--	print(func)
	stead.savemembers(h, self, name, need, func);
end
function for_each2(o, n, f, fv, ...)
	local call_list = {}
	local k,v
	if stead.type(o) ~= 'table' then
		return
	end
	if o.__acted2__ == nil then
		o.__acted2__ = {}
	end;
	stead.object = n;

	for k,v in stead.pairs(o) do
		if k ~= '__acted2__' then
			if fv(v) then
				stead.table.insert(call_list, { k = k, v = v });
			end
			if type(v) == 'table' and v ~= _G and not o.__acted2__[v] then
--				print(v)
				o.__acted2__[v] = true
				v.__acted2__ = o.__acted2__
				for_each2(v, n..tostring(k), f, fv, ...)
				v.__acted2__ = nil
			end
		end
	end

	for k, v in stead.ipairs(call_list) do
		f(v.k, v.v, ...);
	end
end
function for_each_object2(f,...)
	for_each2(_G, '_G', f, isObject, ...)
end

function for_each_player2(f,...)
	for_each2(_G, '_G', f, isPlayer, ...)
end

function for_each_room2(f,...)
	for_each2(_G, '_G', f, isRoom, ...)
end

function for_each_list2(f,...)
	for_each2(_G, '_G', f, isList, ...)
end
for_each_object2(function(nam, tab) tab.save = stead.obj_save end)
for_each_list2(function(nam, tab) tab.save = stead.list_save end)
for_each_player2(function(nam, tab) tab.save = stead.player_save end)
for_each_room2(function(nam, tab) tab.save = stead.room_save end)
stead.objects = function(s)
	null = obj {
		nam = 'null';
	}

	input = obj { -- input object
		system_type = true,
		nam = 'input',
	--[[	key = function(s, down, key)
			return
		end, ]]
	--[[	click = function(s, down, mb, x, y, [ px, py ] )
			return
		end ]]
	};

	timer = obj { -- timer calls stead.timer callback 
		nam = 'timer',
		ini = function(s)
			if stead.tonum(s._timer) ~= nil and stead.type(stead.set_timer) == 'function' then
				stead.set_timer(s._timer);
			end
		end,
		get = function(s)
			if stead.tonum(s._timer) == nil then
				return 0
			end
			return stead.tonum(s._timer);
		end,
		stop = function(s)
			return s:set(0);
		end,
		del = function(s)
			return s:set(0);
		end,
		set = function(s, v)
			s._timer = stead.tonum(v);
			if stead.type(stead.set_timer) ~= 'function' then
				return false
			end
			stead.set_timer(v)
			return true
		end,
		--[[ 	callback = function(s)
			end, ]]
	};

	allocator = obj {
		nam = 'allocator',
		get = function(s, n, c)
			if isObject(stead.ref(n)) and stead.api_atleast(1, 3, 0) then -- static?
				return stead.ref(n);
			end
			local v = stead.ref(c);
			if not v then
				error ("Null object in allocator: "..stead.tostr(c));
			end
			v.key_name = n;
			v.save = stead.allocator_save;
			v.constructor = c;
			return v
		end,
		delete = function(s, w)
			w = stead.ref(w);
			if stead.type(w.key_name) ~= 'string' then
				return
			end
			local f = stead.eval(w.key_name..'= nil;');
			if f then
				f();
			end
		end,
		new = function(s, n, key)
			local v = stead.ref(n);
			if stead.type(v) ~= 'table' or stead.type(n) ~= 'string' then
				error ("Error in new.", 2);
			end
			v.save = stead.allocator_save;
			v.constructor = n;
			if key then
				s.objects[key] = v
				v.key_name = stead.string.format('allocator["objects"][%s]', stead.tostring(key));
			else
				local nm = #s.objects + 1 -- here is new index
				stead.table.insert(s.objects, v);
				v.key_name = 'allocator["objects"]['..stead.tostr(nm)..']';
			end
			if stead.api_atleast(1, 3, 0) then
				stead.check_object(v.key_name, v)
			end
			return v
		end,
		objects = {
			save = function(self, name, h, need, func)
				stead.savemembers(h, self, name, true, func);
			end,
		},
	};
--[[
	pl = player {
		nam = "Incognito",
		where = 'main',
		obj = { }
	};]]--

	main = room {
		nam = 'main',
		dsc = 'No main room defined.',
	};
end
stead.objects()
