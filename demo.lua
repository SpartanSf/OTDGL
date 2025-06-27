local gl = require("otdgl")

gl.Init()
gl.ClearColor(0, 0, 0, 1)

local Bitmap = require("lua-bitmap")

local cube1 = gl.newModelFromPath("otdgl/models/cube.umdl")
local cube2 = gl.newModelFromPath("otdgl/models/pineapple.umdl")

local width, height = term.getSize(1)

local t = 0

local function draw()
    gl.clear()

    gl.MatrixMode(gl.PROJECTION)
    gl.LoadIdentity()
    gl.Perspective(90, width / height, 0.1, 100)

    local orbitRadius = 2.0
    local orbitSpeed = 60
    local spinSpeed = 120

    local angle = math.rad(t * orbitSpeed)
    local x1 = orbitRadius * math.cos(angle)
    local z1 = orbitRadius * math.sin(angle)
    local x2 = orbitRadius * math.cos(angle + math.pi)
    local z2 = orbitRadius * math.sin(angle + math.pi)

    cube1:setIdentity()
    cube1:translatef(x1, 0, z1 - 8)  
    cube1:rotatef(t * spinSpeed, 1, 1, 0)  
    cube1:render()

    cube2:setIdentity()
    cube2:translatef(x2, 0, z2 - 8)  
    cube2:rotatef(t * spinSpeed * 0.8, 0, 1, 1)  
    cube2:render()

    gl.display()

    t = t + 1 / 60
end

function gl.MainLoop(drawFunc)
    while true do
        drawFunc()
        os.queueEvent("fake_event")
        os.pullEvent()
    end
end

gl.MainLoop(draw)