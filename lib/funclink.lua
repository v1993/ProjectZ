funclink = function(funcnam)
	return function(...)
		return stead.eval(funcnam)(...)
	end;
end;
