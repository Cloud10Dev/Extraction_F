Utils = {}

function Utils.Log(msg)
    print(('[extraction_shooter] %s'):format(tostring(msg)))
end

function Utils.GenId(len)
    local chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    local out = {}
    for i = 1, len do
        local r = math.random(1, #chars)
        out[#out+1] = chars:sub(r, r)
    end
    return table.concat(out)
end

math.randomseed(os.time())
