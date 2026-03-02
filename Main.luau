-- Nitrous dumper
-- script not meant to be undetectable btw theres a million billion ways to dtc it itd take forever to patch them all
-- created by @ banov and @ magicchair on discord

if config then table.clear(config) end
local config = {
    ["DumpType"] = "all",  -- types are metamethods, roblox functions (unfin), and executor functions (unfin) and all
    ["NoMultiHook"] = true,
    ["AntiOverflow"] = true -- please enable if you're using all multiple dumptypes at once
}

-- c stack overflow prevention since we hook fucking everything
local Appendfile,Tostring,getinfo=appendfile,tostring,debug.getinfo
local Hookfunction,Isfunctionhooked,Newcclosure=clonefunction(hookfunction),clonefunction(isfunctionhooked),clonefunction(newcclosure)
local Checkcaller,Getnamecallmethod,Rawget,Next=clonefunction(checkcaller),clonefunction(getnamecallmethod),rawget,next
local blocklist={}
if config.AntiOverflow then
    local bl = {
        appendfile, writefile, hookfunction, isfunctionhooked, newcclosure,
        checkcaller, getnamecallmethod, clonefunction, debug.getinfo,
        Appendfile, Hookfunction, Isfunctionhooked, Newcclosure,
        Checkcaller, Getnamecallmethod, getinfo,
        tostring, Tostring, next, Next, rawget, Rawget
    }
    for _,fn in Next, bl do
        if type(fn) == "function" then blocklist[fn] = true end
    end
end

local function Initialize()
    charset, base = "012345678910", "Nitrous"
    for i = 1, 10 do
        base = base .. string.sub(charset,  math.random(#charset),  math.random(#charset))
    end
    filename = base .. ".txt"
    writefile(filename, "")
end


local function FindDumpMethod(): string
    local dt = string.lower(config.DumpType)
    if dt == "all" then
        return "all"
    elseif dt == "metamethods" then
        return "metamethods"
    elseif string.find(dt, "exec") and string.find(dt, "func") then
        return "execfunctions"
    elseif string.find(dt, "robl") and string.find(dt, "func") then
        return "robloxfunctions"
    else
        print("wtf did u put in dumptype")
        return "unknown"
    end
end


local function PreventMultiHook(f)
    if not config.NoMultiHook then return false end
    if Isfunctionhooked(f) then return true end
    return false
end


Initialize()


local function Metamethods()
    if FindDumpMethod() ~= "metamethods" and FindDumpMethod() ~= "all" then return end

    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local hook;hook = Hookfunction(mt.__namecall, Newcclosure(function(...)
        local args = {select(2, ...)}
        local self = Rawget({...}, 1)
        if Checkcaller() then
            for i,v in Next, args do
                Appendfile(filename, "Namecall: " .. Tostring(i) .. " " .. Tostring(v) .. " " .. Tostring(self) .. " " .. Tostring(Getnamecallmethod()) .. "\n")
            end
            return hook(...)
        end
        return hook(...)
    end))

    local hook2;hook2 = Hookfunction(mt.__index, Newcclosure(function(...)
        local args = {select(2, ...)}
        local self = Rawget({...}, 1)
        if Checkcaller() then
            for i,v in Next, args do
                Appendfile(filename, "Index: " .. Tostring(i) .. " " .. Tostring(v) .. " " .. Tostring(self) .. "\n")
            end
            return hook2(...)
        end
        return hook2(...)
    end))

    local hook3;hook3 = Hookfunction(mt.__newindex, Newcclosure(function(...)
        local args = {select(2, ...)}
        local self = Rawget({...}, 1)
        if Checkcaller() then
            for i,v in Next, args do
                Appendfile(filename, "Newindex: " .. Tostring(i) .. " " .. Tostring(v) .. " " .. Tostring(self) .. "\n")
            end
            return hook3(...)
        end
        return hook3(...)
    end))
end


local function RobloxFunctions()
    if FindDumpMethod() ~= "robloxfunctions" and FindDumpMethod() ~= "all" then return end

    local rf = getrawmetatable(getrenv())
    if rf.__index and typeof(rf.__index) == "table" then
        for i,v in Next, rf.__index do
            if typeof(v) == "table" then
                for a,b in Next, v do
                    if typeof(b) == "function" and not blocklist[b] and not PreventMultiHook(b) then
                        local orig;orig = Hookfunction(b, function(...)
                            if Checkcaller() then
                                local args = {...}
                                for _,arg in Next, args do
                                    Appendfile(filename, getinfo(b).name .. ": " .. Tostring(arg) .. "\n")
                                end
                            end
                            return orig(...)
                        end)
                    end
                end
            elseif typeof(v) == "function" and not blocklist[v] and not PreventMultiHook(v) then
                local orig;orig = Hookfunction(v, function(...)
                    if Checkcaller() then
                        local args = {...}
                        for _,arg in Next, args do
                            Appendfile(filename, getinfo(v).name .. ": " .. Tostring(arg) .. "\n")
                        end
                    end
                    return orig(...)
                end)
            end
        end
    end
end


local function ExecutorFunctions()
    if FindDumpMethod() ~= "execfunctions" and FindDumpMethod() ~= "all" then return end

    for i,v in Next, getgenv() do
        if typeof(v) == "function" and not blocklist[v] and not PreventMultiHook(v) then
            local orig;orig = Hookfunction(v, function(...)
                local args = {...}
                for _,arg in Next, args do
                    Appendfile(filename, getinfo(v).name .. " " .. Tostring(arg) .. "\n")
                end
                return orig(...)
            end)
        end
    end
end


Metamethods()
ExecutorFunctions()
RobloxFunctions()

-- todo: add _G and shared support via editing getrenv hook
-- todo: make roblox functions append both library name and function name, i.e task.spawn appends spawn: function address
-- todo: switch to OOP code and heavy overhauls due to ugly unreadable code
-- todo: edit dump types to be able to dump combonations instead of an individual or just all
-- todo: getgc dumping? getreg dumping? (threads and signals), opcode hooking? metatable based dumpers?
-- todo: return names of any robloxfunc/executorfunc that returns a function (maybe upvalues,constants as well)
-- todo: edit checkcaller, tostring, getinfo
-- todo: make renamed funcs less ugly
-- todo: make script not log anything for atleast 1 second after its executed
-- todo: add websocket as an alternative to appendfile, localhost should be significantly faster and prevent superbig files being made
-- todo: sandboxing
-- todo: optimize code due to shit lagging
