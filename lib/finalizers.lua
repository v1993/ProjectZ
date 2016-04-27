local finaltab = {};

return {
	create = function(nam, func)
		local tab = {}
		setmetatable(tab, {__gc = func})
		finaltab[nam] = tab
	end;
	delete = function(nam)
		finaltab[nam] = nil
	end
}
