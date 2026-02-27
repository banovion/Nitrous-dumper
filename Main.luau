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
local appendf,tostr,getinfo=appendfile,tostring,debug.getinfo
local hookfunc,ismultihook,newcc=clonefunction(hookfunction),clonefunction(isfunctionhooked),clonefunction(newcclosure)
local checkcall,getncm,rget,nxt=clonefunction(checkcaller),clonefunction(getnamecallmethod),rawget,next
local getrenv_c,getgenv_c=getrenv,getgenv
local blocklist={}
if config.AntiOverflow then
    local bl = {
        appendfile, writefile, hookfunction, isfunctionhooked, newcclosure,
        checkcaller, getnamecallmethod, clonefunction, debug.getinfo,
        appendf, hookfunc, ismultihook, newcc,
        checkcall, getncm, getinfo,
        tostring, tostr, next, nxt, rawget, rget
    }
    for _,fn in nxt, bl do
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
    if ismultihook(f) then return true end
    return false
end


Initialize()


local function Metamethods()
    if FindDumpMethod() ~= "metamethods" and FindDumpMethod() ~= "all" then return end

    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local hook;hook = hookfunc(mt.__namecall, newcc(function(...)
        local args = {select(2, ...)}
        local self = rget({...}, 1)
        if checkcall() then
            for i,v in nxt, args do
                appendf(filename, "Namecall: " .. tostr(i) .. " " .. tostr(v) .. " " .. tostr(self) .. " " .. tostr(getncm()) .. "\n")
            end
            return hook(...)
        end
        return hook(...)
    end))

    local hook2;hook2 = hookfunc(mt.__index, newcc(function(...)
        local args = {select(2, ...)}
        local self = rget({...}, 1)
        if checkcall() then
            for i,v in nxt, args do
                appendf(filename, "Index: " .. tostr(i) .. " " .. tostr(v) .. " " .. tostr(self) .. "\n")
            end
            return hook2(...)
        end
        return hook2(...)
    end))

    local hook3;hook3 = hookfunc(mt.__newindex, newcc(function(...)
        local args = {select(2, ...)}
        local self = rget({...}, 1)
        if checkcall() then
            for i,v in nxt, args do
                appendf(filename, "Newindex: " .. tostr(i) .. " " .. tostr(v) .. " " .. tostr(self) .. "\n")
            end
            return hook3(...)
        end
        return hook3(...)
    end))
end


local function RobloxFunctions()
    if FindDumpMethod() ~= "robloxfunctions" and FindDumpMethod() ~= "all" then return end

    local rf = getrawmetatable(getrenv_c())
    if rf.__index and typeof(rf.__index) == "table" then
        for i,v in nxt, rf.__index do
            if typeof(v) == "table" then
                for a,b in nxt, v do
                    if typeof(b) == "function" and not blocklist[b] and not PreventMultiHook(b) then
                        local orig;orig = hookfunc(b, function(...)
                            if checkcall() then
                                local args = {...}
                                for _,arg in nxt, args do
                                    appendf(filename, getinfo(b).name .. ": " .. tostr(arg) .. "\n")
                                end
                            end
                            return orig(...)
                        end)
                    end
                end
            elseif typeof(v) == "function" and not blocklist[v] and not PreventMultiHook(v) then
                local orig;orig = hookfunc(v, function(...)
                    if checkcall() then
                        local args = {...}
                        for _,arg in nxt, args do
                            appendf(filename, getinfo(v).name .. ": " .. tostr(arg) .. "\n")
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

    for i,v in nxt, getgenv_c() do
        if typeof(v) == "function" and not blocklist[v] and not PreventMultiHook(v) then
            local orig;orig = hookfunc(v, function(...)
                local args = {...}
                for _,arg in nxt, args do
                    appendf(filename, getinfo(v).name .. " " .. tostr(arg) .. "\n")
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
-- checkcaller, tostring, getinfo
-- make renamed funcs less ugly
