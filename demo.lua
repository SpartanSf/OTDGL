local gl = require("otdgl")

gl.Init()
gl.ClearColor(0, 0, 0, 1)

local Bitmap = require("lua-bitmap")

local cube = gl.newModel({
    vertices = { 
        { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 },
        { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 }
    },
    parts = {
        { name = "back", faces = { { 1, 4, 3 }, { 1, 3, 2 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat0" },
        { name = "front", faces = { { 5, 6, 7 }, { 5, 7, 8 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat1" },
        { name = "left", faces = { { 5, 8, 4 }, { 5, 4, 1 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat2" },
        { name = "right", faces = { { 2, 3, 7 }, { 2, 7, 6 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat3" },
        { name = "top", faces = { { 4, 8, 3 }, { 3, 8, 7 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat4" },
        { name = "bottom", faces = { { 1, 2, 6 }, { 1, 6, 5 } }, 
          uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } }, material = "mat5" },
    },
    materials = {
        mat0 = { type = "color", value = colors.red },
        mat1 = { type = "texture", texture = Bitmap.from_file("otdgl/doom2.bmp") },
        mat2 = { type = "color", value = colors.lime },
        mat3 = { type = "color", value = colors.blue },
        mat4 = { type = "color", value = colors.yellow },
        mat5 = { type = "color", value = colors.orange },
    },
})

local width, height = term.getSize(1)

local t = 0
local tGoal = (os.epoch("utc") / 1000) + 1/60
local function draw()
    gl.Clear()
    gl.MatrixMode(gl.PROJECTION)
    gl.LoadIdentity()
    gl.Perspective(90, width / height, 0.1, 100)
    gl.MatrixMode(gl.MODELVIEW)
    gl.LoadIdentity()
    gl.Translatef(0, 0, -4)
    gl.Rotatef(t * 50, 0, 1, 0)
    gl.Rotatef(t * 25, 1, 0, 0)

    local transform_state = gl.GetCurrentTransform()
    local rot = transform_state.rot
    local trans = transform_state.trans
    
    local function transform(v)
        local x, y, z = v[1], v[2], v[3]
        local rx = rot[1]*x + rot[2]*y + rot[3]*z + trans[1]
        local ry = rot[4]*x + rot[5]*y + rot[6]*z + trans[2]
        local rz = rot[7]*x + rot[8]*y + rot[9]*z + trans[3]
        return {rx, ry, rz}
    end
    
    gl.render(cube, transform)
    
    local cTime = os.epoch("utc") / 1000
    if cTime >= tGoal then
        t = t + 1/60
        tGoal = tGoal + 1/60
    end
end

function gl.MainLoop(drawFunc)
    while true do
        drawFunc()
        os.queueEvent("fake_event")
        os.pullEvent()
    end
end

gl.MainLoop(draw)