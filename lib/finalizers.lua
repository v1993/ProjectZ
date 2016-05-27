local finaltab = {};

return {
	create = function(nam, func)
		local tab = {}
		setmetatable(tab, {__gc = func})
		finaltab[nam] = tab
	end;
	delete = function(nam)
		setmetatable(finaltab[nam], {}) -- ВАЖНО: отк. финализатор
		finaltab[nam] = nil
	end
}
