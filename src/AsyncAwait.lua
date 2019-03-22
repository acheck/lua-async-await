local Awaiter = require('src.Awaiter')
local Task = require('src.Task')
local coroutine = _G.coroutine
local setmetatable = _G.setmetatable
local setfenv = _G.setfenv
local type = _G.type
local DEBUG_MODE = true
local log = DEBUG_MODE and print or function() end
log('DEBUG_MODE OPEN')

local M = {}
local m = {
    __call = function(t,...)
        local params = {...}
        log('async call: ',t,...)
        --return a task
        local func = t.__ori
        return Task.new(function(awaiter)
            local co
			local deferList = {}
            setfenv(func, setmetatable({
				defer = function(func)
					deferList[#deferList+1] = func
				end,
                await = function(p,name)
                    local temp = {}
                    local cache = temp
                    local baseResume = function(...)
                        cache = {...}
                    end
                    local proxyResume = function(...)
                        log("proxyResume",...)
                        return baseResume(...)
                    end
                    name = name or ""
                    if(type(p)=='table' and p.__type=='Task')then
                        log("- await a taskTable -")
                        p = p
                    elseif(type(p)=='function')then
                        log("- await a taskFunction -")
                        p = Task.new(p)
                    else
                        log("?")
                        return p
                    end
                    p:await(Awaiter.new{
                        onSuccess = proxyResume,
                        onError = function(e)
                            --if(onError)then
                            --    onError(e)
                            --end
                            print('???',name,e)
                            --awaiter:onError(e)
                            error(e)
                        end
                    })
                    if(cache~=temp)then
                        return unpack(cache)
                    end
                    baseResume = function(...)
                        coroutine.resume(co,...)
                    end
                    print("yield()")
                    return coroutine.yield()
                end,
            },{__index = _G}))
            co = coroutine.create(function()
                try{
                    function()
                        log("child task start!")
                        local ret = func(unpack(params))
                        log('child task end!','result:(',ret,')')
						
                        awaiter:onSuccess(ret)
                    end,
                    catch = function(ex)
                        print(t.__name, "caught ex", ex)
                        awaiter:onError(ex)
                    end,
					finally = function(ok,ex)
						for i = #deferList,1,-1 do
							deferList[i]()	
						end			
					end
                }
            end)
            coroutine.resume(co)
        end)
    end
}

M.async = function(func)
	log('async')
    return setmetatable({__type = 'asyncFunction', __ori = func}, m)
end

M.await = function(base, onError)
    if(type(base)=='table' and base.__type=='Task')then
        log("- task -")
        base = base
    elseif(type(base)=='function')then
        log("- taskFunction -")
        base = Task.new(base)
    else
        error('must be task or taskFunction')
    end
    base:await(Awaiter.new{
        onSuccess = function(result)
            log('final result: ', result)
        end,
        onError = onError or function(ex)
            printJson("await onError",ex)
        end
    })
end
return M
