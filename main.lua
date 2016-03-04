-- $Name: ProjectZ$
-- $Version: 0.1$
-- $Author: Очинский Валерий$
require 'lib/saver'
require 'timer'
require 'saver'
instead_version "2.3.0"
start = {}
global {x = 0, y = 0, z = 0};
start_game = function()
	cron:start()
end;
main = room {
	nam = 'Давай!';
	obj = {obj {nam = 'ok', dsc = '{Начать игру!}', act = code [[return start_game()]]}};
};

function start ()
	
end


-- Это пишет разработчик...
start.world = 'overworld' -- Игрок заспавнится в этом мире
start.x = 0 -- Стартовые коардинаты
start.y = 0
start.z = 60
