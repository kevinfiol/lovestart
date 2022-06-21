--[[
https://github.com/kevinfiol/typeok.lua
MIT License

Copyright (c) 2022 kevinfiol

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local isArray = function (x)
    local is_table = type(x) == 'table'
    if not is_table then
        return false
    end

    local i = 0

    for _ in pairs(x) do
        i = i + 1
        if x[i] == nil then return false end
    end

    return true
end

local MAP = {
    notnil = function (x) return type(x) ~= 'nil' end,
    number = function (x) return type(x) == 'number' end,
    string = function (x) return type(x) == 'string' end,
    boolean = function (x) return type(x) == 'boolean' end,
    table = function (x) return type(x) == 'table' end,
    fn = function (x) return type(x) == 'function' end,
    thread = function (x) return type(x) == 'thread' end,
    userdata = function (x) return type(x) == 'userdata' end,
    array = function (x) return type(x) == 'table' and isArray(x) end,
    object = function (x) return type(x) == 'table' and not isArray(x) end
}

local addError = function(res, v_type, x)
    if res.ok then res.ok = false end

    if not MAP.number(x) and not MAP.string(x) then
        x = '[' .. type(x) .. ']'
    end

    table.insert(res.errors, 'Expected ' .. v_type .. ', got: ' .. x)
end

return function(t, custom_map)
    custom_map = custom_map or {}

    local res = { ok = true, errors = {} }
    local map = {}

    for k in pairs(MAP) do
        map[k] = MAP[k]
    end

    for k in pairs(custom_map) do
        map[k] = custom_map[k]
    end

    for k in pairs(t) do
        local key = k
        local is_multi = string.sub(k, -1) == 's'

        if is_multi then
            key = string.sub(key, 0, -2)
        end

        if map[key] ~= nil then
            local fn = map[key]
            local x = t[k]

            if is_multi then
                if isArray(x) then
                    for _, v in ipairs(x) do
                        if not fn(v, MAP) then
                            addError(res, key, v)
                        end
                    end
                end
            elseif not fn(x, MAP) then
                addError(res, key, x)
            end
        end
    end

    return res
end