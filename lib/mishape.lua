--[[
https://github.com/kevinfiol/mishape.lua
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
    ['nil'] = function(x) return type(x) == 'nil' end,
    ['function'] = function (x) return type(x) == 'function' end,
    notnil = function (x) return type(x) ~= 'nil' end,
    number = function (x) return type(x) == 'number' end,
    string = function (x) return type(x) == 'string' end,
    boolean = function (x) return type(x) == 'boolean' end,
    table = function (x) return type(x) == 'table' end,
    thread = function (x) return type(x) == 'thread' end,
    userdata = function (x) return type(x) == 'userdata' end,
    array = function (x) return type(x) == 'table' and isArray(x) end,
    object = function (x) return type(x) == 'table' and not isArray(x) end
}

-- aliases
MAP.fn = MAP['function']
MAP.undefined = MAP['nil']
MAP.defined = MAP['notnil']
MAP.bool = MAP['boolean']

local addError = function(res, v_type, x, id)
    if res.ok then res.ok = false end

    local id_str = ''
    if id ~= nil and #id > 0 then
        id_str = ' at ' .. id
    end

    if not MAP.number(x) and not MAP.string(x) then
        x = '[' .. type(x) .. ']'
    end

    table.insert(res.errors, 'Expected ' .. v_type .. ', got: ' .. x .. id_str)
end

local function validate(schema, t, res, map, chain)
    if not MAP.object(t) then
        return addError(res, 'object', t, chain)
    end

    for key, v_type in pairs(schema) do
        local id = key

        if #chain > 0 then
            id = chain .. '.' .. id
        end

        if MAP.fn(v_type) then
            if not v_type(t[key], map) then
                addError(res, key, t[key], id)
            end
        elseif MAP.string(v_type) then
            local pass = false
            for union_type in v_type.gmatch(v_type, '([^|]+)') do
                if map[union_type] == nil then
                    error('[mishape]: ' .. union_type .. ' is not a validator')
                end

                if map[union_type](t[key], MAP) then
                    pass = true
                end
            end

            if not pass then
                addError(res, v_type, t[key], id)
            end
        elseif MAP.object(v_type) then
            validate(schema[key], t[key], res, map, id)
        end
    end

    return res
end

return function(schema, custom_map)
    custom_map = custom_map or {}
    local map = {}

    for k in pairs(MAP) do
        map[k] = MAP[k]
    end

    for k in pairs(custom_map) do
        map[k] = custom_map[k]
    end

    return function(t)
        return validate(schema, t, { ok = true, errors = {} }, map, '')
    end
end
