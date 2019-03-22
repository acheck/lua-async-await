local AsyncAwaitLib = require('src.AsyncAwait')
_G.async = AsyncAwaitLib.async
_G.await = AsyncAwaitLib.await

local try = require('libs.tryCatchFinally')

-- replace delay-func of your platform here
local timer_performWithDelay = function(...)
    -- delay-func(...)
end
local function delay(ms)
    return function(waiter)
        timer_performWithDelay(ms, function(_)
            waiter.onSuccess('delay result')
        end)
    end
end

local func_0 = async(function()
    print('[func_0]', 'delay 0.5s start!')
    await(delay(500))
    print('[func_0]', 'delay 0.5s end!')
    return 1000
end)

local func_1 = async(function(...)
    print('args: ',...)
    try{
        function()
            local delayTime = await(func_0())
            print('delay: ',delayTime,'ms')
            await(delay(delayTime))
        end,
        catch = function(e)
            print('ex caught!',e)
        end
    }
end)
local func_2 = async(function(...)
    print('args: ',...)
    return "I'm sync-function"
end)

await(func_2('cwd'))
print('-------------------------------------')
await(func_1('cwd'))
