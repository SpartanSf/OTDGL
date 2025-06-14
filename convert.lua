function convertToOh3dModel(triangles)
    local vertices = {}
    local vertexMap = {}
    local partsByColor = {}

    local function addVertex(v)
        local key = table.concat(v, ",")
        if vertexMap[key] then return vertexMap[key] end
        table.insert(vertices, v)
        local idx = #vertices
        vertexMap[key] = idx
        return idx
    end

    for _, tri in ipairs(triangles) do
        local v1 = {tri.x1, tri.y1, tri.z1}
        local v2 = {tri.x2, tri.y2, tri.z2}
        local v3 = {tri.x3, tri.y3, tri.z3}

        local i1 = addVertex(v1)
        local i2 = addVertex(v2)
        local i3 = addVertex(v3)

        local face = {i1, i2, i3}
        local color = tri.c or colors.white

        if not partsByColor[color] then
            partsByColor[color] = {}
        end
        table.insert(partsByColor[color], face)
    end

    local partIndex = 0
    local parts = {}
    local materials = {}

    for color, faces in pairs(partsByColor) do
        local name = "part" .. partIndex
        local matName = "mat" .. partIndex
        partIndex = partIndex + 1

        local uvs = {}
        for _ = 1, #faces do
            table.insert(uvs, {{0,1}, {1,1}, {1,0}})
        end

        table.insert(parts, {
            name = name,
            faces = faces,
            uvs = uvs,
            material = matName,
        })

        materials[matName] = {
            type = "color",
            value = color,
        }
    end

    return {
        vertices = vertices,
        parts = parts,
        materials = materials,
    }
end

local args = {...}

local dataInFile = fs.open(args[1], "r")
local dataIn = dataInFile.readAll()
dataInFile.close()

local dataOh3dModel = convertToOh3dModel(textutils.unserialise(dataIn))

local dataOutFile = fs.open(args[2], "w")
dataOutFile.write(textutils.serialise(dataOh3dModel, {compact = true}))
dataOutFile.close()