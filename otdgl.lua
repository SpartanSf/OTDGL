local Bitmap = require("lua-bitmap")
local util = require("otdgl_util")

local floor, max, min, huge = math.floor, math.max, math.min, math.huge
local cos, sin, tan, rad = math.cos, math.sin, math.tan, math.rad
local term_write, term_getSize, term_setGraphicsMode, term_drawPixels =
    term.write, term.getSize, term.setGraphicsMode, term.drawPixels
local require, pairs, ipairs, error = require, pairs, ipairs, error
term_setGraphicsMode(1)

local W, H = term_getSize(1)
local W1, H1 = W - 1, H - 1

local colors_black, colors_red, colors_lime, colors_blue, colors_yellow, colors_cyan, colors_purple, colors_white =
    colors.black, colors.red, colors.lime, colors.blue, colors.yellow, colors.cyan, colors.purple, colors.white

local colorMap = {
    [colors.white]   = {255, 255, 255},
    [colors.orange]  = {255, 165, 0},
    [colors.magenta] = {255, 0, 255},
    [colors.lightBlue] = {173, 216, 230},
    [colors.yellow]  = {255, 255, 0},
    [colors.lime]    = {0, 255, 0},
    [colors.pink]    = {255, 192, 203},
    [colors.gray]    = {128, 128, 128},
    [colors.lightGray] = {192, 192, 192},
    [colors.cyan]    = {0, 255, 255},
    [colors.purple]  = {128, 0, 128},
    [colors.blue]    = {0, 0, 255},
    [colors.brown]   = {139, 69, 19},
    [colors.green]   = {0, 128, 0},
    [colors.red]     = {255, 0, 0},
    [colors.black]   = {0, 0, 0},
}

local function rgb2col(r, g, b)
    r, g, b = r or 0, g or 0, b or 0
    local best_col, min_dist = colors.black, r*r + g*g + b*b

    local dist = (255-r)^2 + g^2 + b^2
    if dist < min_dist then best_col, min_dist = colors.red, dist end

    dist = r^2 + (255-g)^2 + b^2
    if dist < min_dist then best_col, min_dist = colors.lime, dist end

    dist = r^2 + g^2 + (255-b)^2
    if dist < min_dist then best_col, min_dist = colors.blue, dist end

    dist = (255-r)^2 + (255-g)^2 + b^2
    if dist < min_dist then best_col, min_dist = colors.yellow, dist end

    dist = r^2 + (255-g)^2 + (255-b)^2
    if dist < min_dist then best_col, min_dist = colors.cyan, dist end

    dist = (255-r)^2 + g^2 + (255-b)^2
    if dist < min_dist then best_col, min_dist = colors.purple, dist end

    dist = (255-r)^2 + (255-g)^2 + (255-b)^2
    if dist < min_dist then best_col, min_dist = colors.white, dist end

    return best_col
end

local function vec_sub(a, b)
    return a[1] - b[1], a[2] - b[2], a[3] - b[3]
end

local function vec_dot(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function vec_cross(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

local projMatrix = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }

local function project(x, y, z)
    local px = projMatrix[1] * x + projMatrix[4] * y + projMatrix[7] * z
    local py = projMatrix[2] * x + projMatrix[5] * y + projMatrix[8] * z
    local pz = projMatrix[3] * x + projMatrix[6] * y + projMatrix[9] * z

    local iz = 1 / pz
    local sx = (px * iz + 1) * 0.5 * W
    local sy = (1 - (py * iz + 1) * 0.5) * H
    return sx, sy, pz  
end

local fb, zb = {}, {}
local clearColor = colors_black
for y = 1, H do
    fb[y] = {}
    zb[y] = {}
    for x = 1, W do
        fb[y][x] = clearColor
        zb[y][x] = huge
    end
end

local function clearBuffers()
    for y = 1, H do
        local fb_row, zb_row = fb[y], zb[y]
        for x = 1, W do
            fb_row[x] = clearColor
            zb_row[x] = huge
        end
    end
end

local function displayBuffers()
    term_drawPixels(0, 0, fb)
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local solidColorTextures = {}

local function getSolidTexture(color)
    if not solidColorTextures[color] then
        solidColorTextures[color] = {
            is_solid = true,
            color = color,
            get_pixel = function(_, x, y)
                return colorMap[color][1], colorMap[color][2], colorMap[color][3]
            end
        }
    end
    return solidColorTextures[color]
end

local fillSolidTri, fillTexturedTri

function fillTexturedTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z, u0x, u0y, u1x, u1y, u2x, u2y, tex)
    if not tex then
        if not r then
            return fillTexturedTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z, u0x, u0y, u1x, u1y, u2x, u2y, Bitmap.from_file("otdgl/assets/missing.bmp"), true)
        else
            return fillSolidTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z, colors.purple)
        end
    end

    if p1y < p0y then
        p0x, p0y, p0z, p1x, p1y, p1z = p1x, p1y, p1z, p0x, p0y, p0z
        u0x, u0y, u1x, u1y = u1x, u1y, u0x, u0y
    end
    if p2y < p0y then
        p0x, p0y, p0z, p2x, p2y, p2z = p2x, p2y, p2z, p0x, p0y, p0z
        u0x, u0y, u2x, u2y = u2x, u2y, u0x, u0y
    end
    if p2y < p1y then
        p1x, p1y, p1z, p2x, p2y, p2z = p2x, p2y, p2z, p1x, p1y, p1z
        u1x, u1y, u2x, u2y = u2x, u2y, u1x, u1y
    end

    if p0y == p2y then return end

    local z0, z1, z2 = p0z, p1z, p2z
    local w0, w1, w2 = 1/z0, 1/z1, 1/z2

    local uw0, vw0 = u0x * w0, u0y * w0
    local uw1, vw1 = u1x * w1, u1y * w1
    local uw2, vw2 = u2x * w2, u2y * w2

    local dX1, dY1 = p1x - p0x, p1y - p0y
    local dX2, dY2 = p2x - p0x, p2y - p0y
    local area = dX1 * dY2 - dX2 * dY1
    if area == 0 then return end
    local invArea = 1 / area

    local minX = max(1, floor(min(p0x, p1x, p2x) + 0.5))
    local maxX = min(W, floor(max(p0x, p1x, p2x) + 0.5))
    local minY = max(1, floor(min(p0y, p1y, p2y) + 0.5))
    local maxY = min(H, floor(max(p0y, p1y, p2y) + 0.5))

    local s_step = dY2 * invArea
    local t_step = -dY1 * invArea
    local dz_dx = (z1 - z0) * s_step + (z2 - z0) * t_step
    local dw_dx = (w1 - w0) * s_step + (w2 - w0) * t_step
    local dA_dx = (uw1 - uw0) * s_step + (uw2 - uw0) * t_step
    local dB_dx = (vw1 - vw0) * s_step + (vw2 - vw0) * t_step

    local const_z1 = z1 - z0
    local const_z2 = z2 - z0
    local const_w1 = w1 - w0
    local const_w2 = w2 - w0
    local const_A1 = uw1 - uw0
    local const_A2 = uw2 - uw0
    local const_B1 = vw1 - vw0
    local const_B2 = vw2 - vw0

    for y = minY, maxY do
        local vy = y - p0y + 0.5
        local vx0 = minX - p0x + 0.5

        local s_val = (vx0 * dY2 - vy * dX2) * invArea
        local t_val = (vy * dX1 - vx0 * dY1) * invArea

        local z_val = z0 + s_val*const_z1 + t_val*const_z2
        local w_val = w0 + s_val*const_w1 + t_val*const_w2
        local A_val = uw0 + s_val*const_A1 + t_val*const_A2
        local B_val = vw0 + s_val*const_B1 + t_val*const_B2

        local zb_row = zb[y]
        local fb_row = fb[y]

        for x = minX, maxX do
            if s_val >= 0 and t_val >= 0 and s_val + t_val <= 1 then
                if z_val < zb_row[x] then
                    zb_row[x] = z_val

                    if tex.is_solid then
                        fb_row[x] = tex.color
                    else
                        local u_coord = clamp(A_val / w_val, 0, 1)
                        local v_coord = clamp(B_val / w_val, 0, 1)

                        local texX = floor(u_coord * (tex.width - 1) + 0.5)
                        local texY = floor(v_coord * (tex.height - 1) + 0.5)
                        local r, g, b = tex.get_pixel(tex, texX, texY)
                        fb_row[x] = rgb2col(r, g, b)
                    end
                end
            end

            s_val = s_val + s_step
            t_val = t_val + t_step
            z_val = z_val + dz_dx
            w_val = w_val + dw_dx
            A_val = A_val + dA_dx
            B_val = B_val + dB_dx
        end
    end
end

function fillSolidTri(x0, y0, z0, x1, y1, z1, x2, y2, z2, color)
    local tex = getSolidTexture(color)
    fillTexturedTri(x0, y0, z0, x1, y1, z1, x2, y2, z2, 0, 0, 0, 0, 0, 0, tex)
end

local otdgl = {}
local models = {}

local Model = {}
Model.__index = Model

function Model:setIdentity()
    self.matrix = {1,0,0,0,1,0,0,0,1}
    self.translation = {0,0,0}
end

function Model:translatef(x, y, z)
    self.translation[1] = self.translation[1] + x
    self.translation[2] = self.translation[2] + y
    self.translation[3] = self.translation[3] + z
end

function Model:rotatef(angle, x, y, z)
    angle = rad(angle)
    local mag = math.sqrt(x*x + y*y + z*z)
    if mag == 0 then return end
    x, y, z = x/mag, y/mag, z/mag

    local c = cos(angle)
    local s = sin(angle)
    local t = 1 - c

    local R = {
        t*x*x + c,    t*x*y - z*s, t*x*z + y*s,
        t*x*y + z*s,  t*y*y + c,   t*y*z - x*s,
        t*x*z - y*s,  t*y*z + x*s, t*z*z + c
    }

    local new_mat = {}
    local m = self.matrix
    for i = 0, 2 do
        for j = 0, 2 do
            new_mat[i*3 + j + 1] = 
                R[i*3+1]*m[j+1] + R[i*3+2]*m[j+4] + R[i*3+3]*m[j+7]
        end
    end
    self.matrix = new_mat
end

function Model:setPartColor(name, col)
    for i = 1, #self.data.parts do
        local p = self.data.parts[i]
        if p.name == name then
            self.materials[p.material] = { type = "color", value = col }
            return
        end
    end
    error("Part not found: " .. name)
end

function Model:setPartTexture(name, tex)
    for i = 1, #self.data.parts do
        local p = self.data.parts[i]
        if p.name == name then
            self.materials[p.material] = { type = "texture", texture = tex }
            return
        end
    end
    error("Part not found: " .. name)
end

function Model:render()
    local world = self.world_vertices
    local projected = self.projected_vertices

    for i, v in ipairs(self.data.vertices) do
        local x, y, z = v[1], v[2], v[3]
        local m = self.matrix
        local tx = m[1]*x + m[2]*y + m[3]*z + self.translation[1]
        local ty = m[4]*x + m[5]*y + m[6]*z + self.translation[2]
        local tz = m[7]*x + m[8]*y + m[9]*z + self.translation[3]
        world[i] = {tx, ty, tz}
        projected[i] = {project(tx, ty, tz)}  
    end

    for _, part in ipairs(self.data.parts) do
        local mat = self.materials[part.material]

        for fi, face in ipairs(part.faces) do
            local v1, v2, v3 = world[face[1]], world[face[2]], world[face[3]]
            local p1, p2, p3 = projected[face[1]], projected[face[2]], projected[face[3]]

            local ax, ay, az = vec_sub(v2, v1)
            local bx, by, bz = vec_sub(v3, v1)
            local nx, ny, nz = vec_cross(ax, ay, az, bx, by, bz)
            local dot = nx * -v1[1] + ny * -v1[2] + nz * -v1[3]

            if dot > 0 then
                if mat.type == "color" then
                    fillSolidTri(p1[1], p1[2], p1[3], p2[1], p2[2], p2[3], p3[1], p3[2], p3[3], mat.value)
                else
                    local uv = part.uvs[fi]
                    fillTexturedTri(
                        p1[1], p1[2], p1[3],
                        p2[1], p2[2], p2[3],
                        p3[1], p3[2], p3[3],
                        uv[1][1], uv[1][2],
                        uv[2][1], uv[2][2],
                        uv[3][1], uv[3][2],
                        mat.texture
                    )
                end
            end
        end
    end
end

function otdgl.newModel(data)
    for k,v in pairs(data) do print(k) end

    local model = setmetatable({
        data = data,
        matrix = {1,0,0,0,1,0,0,0,1},
        translation = {0,0,0},
        world_vertices = {},
        projected_vertices = {},
        materials = {}
    }, Model)

    for k, v in pairs(data.materials) do
        print(k)
        model.materials[k] = v
    end

    for i = 1, #data.vertices do
        model.world_vertices[i] = {0,0,0}
        model.projected_vertices[i] = {0,0,0}
    end

    return model
end

function otdgl.clear()
    clearBuffers()
end

function otdgl.display()
    displayBuffers()
end

otdgl.MODELVIEW, otdgl.PROJECTION = 0, 1
otdgl.CULL_FACE, otdgl.BACK = 0x0B44, 0x0405

local matrixMode = otdgl.MODELVIEW
local MVstack, Pstack =
    { { { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 } } }, { { { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 } } }
local cullEnabled = true

function otdgl.Init()
    clearBuffers()
end

function otdgl.ClearColor(r, g, b)
    clearColor = rgb2col(r * 255, g * 255, b * 255)
end

function otdgl.MatrixMode(m)
    matrixMode = m
end

function otdgl.LoadIdentity()
    local stk = matrixMode == otdgl.MODELVIEW and MVstack or Pstack
    stk[#stk] = { { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 } }
end

function otdgl.PushMatrix()
    local stk = matrixMode == otdgl.MODELVIEW and MVstack or Pstack
    local top = stk[#stk]
    stk[#stk + 1] = {
        { top[1][1], top[1][2], top[1][3], top[1][4], top[1][5], top[1][6], top[1][7], top[1][8], top[1][9] },
        { top[2][1], top[2][2], top[2][3] },
    }
end

function otdgl.PopMatrix()
    local stk = matrixMode == otdgl.MODELVIEW and MVstack or Pstack
    if #stk > 1 then
        stk[#stk] = nil
    end
end

function otdgl.Translatef(x, y, z)
    local stk = matrixMode == otdgl.MODELVIEW and MVstack or Pstack
    local t = stk[#stk][2]
    t[1], t[2], t[3] = t[1] + x, t[2] + y, t[3] + z
end

function otdgl.Rotatef(angle, x, y, z)
    local stk = matrixMode == otdgl.MODELVIEW and MVstack or Pstack
    local mat = stk[#stk][1]
    angle = rad(angle)

    local mag = math.sqrt(x * x + y * y + z * z)
    if mag == 0 then
        return
    end
    x, y, z = x / mag, y / mag, z / mag

    local c = cos(angle)
    local s = sin(angle)
    local t = 1 - c

    local R = {
        t * x * x + c,
        t * x * y - z * s,
        t * x * z + y * s,
        t * x * y + z * s,
        t * y * y + c,
        t * y * z - x * s,
        t * x * z - y * s,
        t * y * z + x * s,
        t * z * z + c,
    }

    local new_mat = {}
    for i = 0, 2 do
        for j = 0, 2 do
            new_mat[i * 3 + j + 1] = R[i * 3 + 1] * mat[j + 1] + R[i * 3 + 2] * mat[j + 4] + R[i * 3 + 3] * mat[j + 7]
        end
    end
    stk[#stk][1] = new_mat
end

function otdgl.Perspective(fov, aspect, near, far)
    local f = 1 / tan(rad(fov) / 2)
    projMatrix = {
        f / aspect,
        0,
        0,
        0,
        f,
        0,
        0,
        0,
        -1,  
    }
end

function otdgl.GetCurrentTransform()
    local top = MVstack[#MVstack]
    return function(v)
        local x, y, z = v[1], v[2], v[3]
        local m = top[1]
        local tx = m[1] * x + m[2] * y + m[3] * z + top[2][1]
        local ty = m[4] * x + m[5] * y + m[6] * z + top[2][2]
        local tz = m[7] * x + m[8] * y + m[9] * z + top[2][3]
        return { tx, ty, tz }
    end
end

function otdgl.LookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ)
    local eye = {eyeX, eyeY, eyeZ}
    local center = {centerX, centerY, centerZ}
    local up = {upX, upY, upZ}

    local fx, fy, fz = center[1]-eye[1], center[2]-eye[2], center[3]-eye[3]
    local flen = math.sqrt(fx*fx + fy*fy + fz*fz)
    if flen == 0 then return end
    fx, fy, fz = fx/flen, fy/flen, fz/flen

    local ulen = math.sqrt(upX*upX+upY*upY+upZ*upZ)
    if ulen == 0 then return end
    local ux, uy, uz = upX/ulen, upY/ulen, upZ/ulen

    local rx, ry, rz = vec_cross(fx, fy, fz, ux, uy, uz)
    local rlen = math.sqrt(rx*rx+ry*ry+rz*rz)
    if rlen == 0 then return end
    rx, ry, rz = rx/rlen, ry/rlen, rz/rlen

    ux, uy, uz = vec_cross(rx, ry, rz, fx, fy, fz)

    local R = {
        rx, ry, rz,
        ux, uy, uz,
        fx, fy, fz
    }

    local T = {
        -(R[1]*eye[1] + R[2]*eye[2] + R[3]*eye[3]),
        -(R[4]*eye[1] + R[5]*eye[2] + R[6]*eye[3]),
        -(R[7]*eye[1] + R[8]*eye[2] + R[9]*eye[3])
    }

    MVstack[#MVstack] = { R, T }
end

function otdgl.newModelFromPath(path)
    local modelFile = fs.open(path, "r")
    local mfdat = textutils.unserialise(modelFile.readAll())
    local modelData = util.decodeModel(mfdat)
    modelFile.close()
    return otdgl.newModel(modelData)
end

function otdgl.newModelFromFile(data)
    return otdgl.newModel(util.decodeModel(textutils.unserialise(data)))
end

function otdgl.encodeModel(model)
    return textutils.serialise(util.encodeModel(model), {compact = true})
end

return otdgl