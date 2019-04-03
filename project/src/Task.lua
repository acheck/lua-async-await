local Awaiter = require('src.Awaiter')
local try = require('libs.try_catch_finally').try
local Task
Task = {
    __needRef = true,
    __call = function(t, awaiter)
        if (type(awaiter) == 'table' and awaiter.__type ~= 'Awaiter') then
            t.__ori(Awaiter.new(awaiter))
        end
        t.__ori(awaiter)
    end,
    await = function(t, awaiter)
        try {
            function()
                t.__ori(awaiter)
            end,
            catch = function(ex)
                awaiter:onError(ex)
            end
        }
    end,
    new = function(base)
        if (type(base) == 'table') then
            return base
        elseif (type(base) == 'function') then
            return setmetatable({ __ori = base, __type = 'Task' }, Task)
        else
            error(base)
        end
    end
}
Task.__index = Task
return Task