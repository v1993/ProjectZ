actway = function(nam, func)
	return room {
		var {nam = nam};
		var {func = func};
		enter = function(s)
			return stead.call(s, 'func'),true
		end;
		save = function(self, name, h, need)
			if stead.type(self.func) ~= 'function' then
				h:write(stead.string.format('%s = actway(%q, %q)', name, self.nam, func));
			else
				h:write(stead.string.format('%s = actway(%q, stead.eval(%q))', name, self.nam, string.dump(func)));
			end;
		end;
	};
end;
