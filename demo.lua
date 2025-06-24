local gl = require("otdgl")

gl.Init()
gl.ClearColor(0, 0, 0, 1)

local Bitmap = require("lua-bitmap")

local cube = gl.newModel({
    vertices = { { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 }, { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, {
        -1,
        1,
        1,
    } },
    parts = {
        { name = "back", faces = { { 1, 2, 3 }, { 1, 3, 4 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat0" },
        { name = "front", faces = { { 6, 5, 8 }, { 6, 8, 7 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat1" },
        { name = "left", faces = { { 5, 1, 4 }, { 5, 4, 8 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat2" },
        { name = "right", faces = { { 2, 6, 7 }, { 2, 7, 3 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat3" },
        { name = "top", faces = { { 4, 3, 7 }, { 4, 7, 8 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat4" },
        { name = "bottom", faces = { { 5, 6, 2 }, { 5, 2, 1 } }, uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, {
            { 0, 1 },
            { 1, 0 },
            { 0, 0 },
        } }, material = "mat5" },
    },
    materials = {
        mat0 = { type = "color", value = colors.red },
        mat1 = { type = "texture", texture = Bitmap.from_file("otdgl/texture3.bmp") },
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

    -- Create transform function using current matrix state
    local function transform(v)
        local x, y, z = v[1], v[2], v[3]
        local mat = gl.GetCurrentMatrix()
        local tx = gl.GetCurrentTranslation()
        
        -- Apply rotation
        local rx = mat[1]*x + mat[2]*y + mat[3]*z
        local ry = mat[4]*x + mat[5]*y + mat[6]*z
        local rz = mat[7]*x + mat[8]*y + mat[9]*z
        
        -- Apply translation
        return {rx + tx[1], ry + tx[2], rz + tx[3]}
    end
    
    -- Render the cube with the current transform
    gl.render(cube, transform)
    
	local cTime = os.epoch("utc") / 1000

	if cTime >= tGoal then
		t = t + 1/60
		tGoal = tGoal + 1/60
	end
end

-- Main loop implementation
local function MainLoop(drawFunc)
    while true do
        drawFunc()
        os.queueEvent("fake_event")
        os.pullEvent()
    end
end

gl.MainLoop = MainLoop
gl.GetCurrentMatrix = function()
	local stack = gl.getMVstack()
    return stack[#stack][1]
end
gl.GetCurrentTranslation = function()
	local stack = gl.getMVstack()
    return stack[#stack][2]
end

gl.MainLoop(draw)