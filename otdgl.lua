local floor, max, min, huge = math.floor, math.max, math.min, math.huge
local cos, sin, tan, rad = math.cos, math.sin, math.tan, math.rad
local term_write, term_getSize, term_setGraphicsMode, term_drawPixels = 
      term.write, term.getSize, term.setGraphicsMode, term.drawPixels
local require, pairs, ipairs, error = require, pairs, ipairs, error
term_setGraphicsMode(1)

local W, H = term_getSize(1)
local W1, H1 = W - 1, H - 1

local colors_black, colors_red, colors_lime, colors_blue, 
      colors_yellow, colors_cyan, colors_purple, colors_white = 
      colors.black, colors.red, colors.lime, colors.blue,
      colors.yellow, colors.cyan, colors.purple, colors.white

local function rgb2col(r, g, b)
    r, g, b = r or 0, g or 0, b or 0

    local d_black = r*r + g*g + b*b
    local dist, best_col = d_black, colors_black

    local d_red    = (255-r)^2 +   g^2 +   b^2
    if d_red    < dist then dist, best_col = d_red,    colors_red    end

    local d_lime   =   r^2 + (255-g)^2 +   b^2
    if d_lime   < dist then dist, best_col = d_lime,   colors_lime   end

    local d_blue   =   r^2 +   g^2 + (255-b)^2
    if d_blue   < dist then dist, best_col = d_blue,   colors_blue   end

    local d_yellow = (255-r)^2 + (255-g)^2 +   b^2
    if d_yellow < dist then dist, best_col = d_yellow, colors_yellow end

    local d_cyan   =   r^2 + (255-g)^2 + (255-b)^2
    if d_cyan   < dist then dist, best_col = d_cyan,   colors_cyan   end

    local d_purple = (255-r)^2 +   g^2 + (255-b)^2
    if d_purple < dist then dist, best_col = d_purple, colors_purple end

    local d_white  = (255-r)^2 + (255-g)^2 + (255-b)^2
    if d_white  < dist then                best_col = colors_white end

    return best_col
end

local huge_neg = -huge

local function vec_sub(a, b)
    return a[1]-b[1], a[2]-b[2], a[3]-b[3]
end

local function vec_dot(a, b)
    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
end

local function vec_cross(ax, ay, az, bx, by, bz)
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx
end

local function matMul3(m, x, y, z)
    return 
        m[1]*x + m[2]*y + m[3]*z,
        m[4]*x + m[5]*y + m[6]*z,
        m[7]*x + m[8]*y + m[9]*z
end

local projMatrix = {1,0,0, 0,1,0, 0,0,1}
local function project(x, y, z)
    local px = projMatrix[1]*x + projMatrix[4]*y + projMatrix[7]*z
    local py = projMatrix[2]*x + projMatrix[5]*y + projMatrix[8]*z
    local pz = projMatrix[3]*x + projMatrix[6]*y + projMatrix[9]*z
    local iz = 1/pz
    return (px*iz + 1)*0.5*W, (1 - py*iz)*0.5*H, pz
end

local function rotX(c, s)
    return {1,0,0, 0,c,-s, 0,s,c}
end

local function rotY(c, s)
    return {c,0,s, 0,1,0, -s,0,c}
end

local fb, zb = {}, {}
local clearColor = colors_black
for y=1,H do
    fb[y] = {}
    zb[y] = {}
    for x=1,W do
        zb[y][x] = huge
    end
end

local function clearBuffers()
    for y=1,H do
        local fb_row, zb_row = fb[y], zb[y]
        for x=1,W do
            fb_row[x] = clearColor
            zb_row[x] = huge
        end
    end
end

local function fillSolidTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z, col)

    if p1y < p0y then
        p0x, p0y, p0z, p1x, p1y, p1z = p1x, p1y, p1z, p0x, p0y, p0z
    end
    if p2y < p0y then
        p0x, p0y, p0z, p2x, p2y, p2z = p2x, p2y, p2z, p0x, p0y, p0z
    end
    if p2y < p1y then
        p1x, p1y, p1z, p2x, p2y, p2z = p2x, p2y, p2z, p1x, p1y, p1z
    end

    local a01 = p0y - p1y
    local b01 = p1x - p0x
    local c01 = p0x*p1y - p1x*p0y

    local a12 = p1y - p2y
    local b12 = p2x - p1x
    local c12 = p1x*p2y - p2x*p1y

    local a20 = p2y - p0y
    local b20 = p0x - p2x
    local c20 = p2x*p0y - p0x*p2y

    local minX = max(1, floor(min(p0x, p1x, p2x)))
    local maxX = min(W, floor(max(p0x, p1x, p2x)))
    local minY = max(1, floor(p0y))
    local maxY = min(H, floor(p2y))

    local area = a01*(p2x-p0x) + b01*(p2y-p0y) + c01
    if area == 0 then return end
    local inv_area = 1/area

    for y = minY, maxY do
        local zb_row = zb[y]
        local fb_row = fb[y]
        for x = minX, maxX do
            local w0 = a01*x + b01*y + c01
            local w1 = a12*x + b12*y + c12
            local w2 = a20*x + b20*y + c20

            if w0 >= 0 and w1 >= 0 and w2 >= 0 then
                local z = (p0z*w0 + p1z*w1 + p2z*w2) * inv_area
                if z < zb_row[x] then
                    zb_row[x] = z
                    fb_row[x] = col
                end
            end
        end
    end
end

local function fillTexturedTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z,
                              uv0x, uv0y, uv1x, uv1y, uv2x, uv2y, tex)

    if p1y < p0y then
        p0x, p0y, p0z, p1x, p1y, p1z, uv0x, uv0y, uv1x, uv1y = 
        p1x, p1y, p1z, p0x, p0y, p0z, uv1x, uv1y, uv0x, uv0y
    end
    if p2y < p0y then
        p0x, p0y, p0z, p2x, p2y, p2z, uv0x, uv0y, uv2x, uv2y = 
        p2x, p2y, p2z, p0x, p0y, p0z, uv2x, uv2y, uv0x, uv0y
    end
    if p2y < p1y then
        p1x, p1y, p1z, p2x, p2y, p2z, uv1x, uv1y, uv2x, uv2y = 
        p2x, p2y, p2z, p1x, p1y, p1z, uv2x, uv2y, uv1x, uv1y
    end

    local w0, w1, w2 = 1/p0z, 1/p1z, 1/p2z
    local u0, v0 = uv0x*w0, uv0y*w0
    local u1, v1 = uv1x*w1, uv1y*w1
    local u2, v2 = uv2x*w2, uv2y*w2

    local v0 = {x=p0x, y=p0y, z=p0z, w=w0, u=u0, v=v0}
    local v1 = {x=p1x, y=p1y, z=p1z, w=w1, u=u1, v=v1}
    local v2 = {x=p2x, y=p2y, z=p2z, w=w2, u=u2, v=v2}

    local texw, texh = tex.width - 1, tex.height - 1
    local get_pixel = tex.get_pixel

    local y_start = floor(max(1, v0.y))
    local y_end = floor(min(H, v2.y))

    for y = y_start, y_end do
        local t = (y - v0.y) / (v2.y - v0.y)
        local A = {
            x = v0.x + (v2.x - v0.x)*t,
            w = v0.w + (v2.w - v0.w)*t,
            u = v0.u + (v2.u - v0.u)*t,
            v = v0.v + (v2.v - v0.v)*t
        }

        local B
        if y < v1.y then
            t = (y - v0.y) / (v1.y - v0.y)
            B = {
                x = v0.x + (v1.x - v0.x)*t,
                w = v0.w + (v1.w - v0.w)*t,
                u = v0.u + (v1.u - v0.u)*t,
                v = v0.v + (v1.v - v0.v)*t
            }
        else
            t = (y - v1.y) / (v2.y - v1.y)
            B = {
                x = v1.x + (v2.x - v1.x)*t,
                w = v1.w + (v2.w - v1.w)*t,
                u = v1.u + (v2.u - v1.u)*t,
                v = v1.v + (v2.v - v1.v)*t
            }
        end

        if A.x > B.x then A, B = B, A end
        local x0 = max(1, floor(A.x))
        local x1 = min(W, floor(B.x))
        if x0 > x1 then goto continue end

        local dx = x1 - x0
        local dw = (B.w - A.w) / dx
        local du = (B.u - A.u) / dx
        local dv = (B.v - A.v) / dx

        local w, u, v = A.w, A.u, A.v
        local zb_row = zb[y]
        local fb_row = fb[y]

        for x = x0, x1 do
            local inv_w = 1/w

            local tx_val = max(0, min(1, (u * inv_w)))
            local ty_val = max(0, min(1, (v * inv_w)))

            local tx = floor(tx_val * texw)
            local ty = floor(ty_val * texh)
            local r, g, b = get_pixel(tex, tx, ty)

            if not r then
                r, g, b = 0, 0, 0  
            end

            local z_val = inv_w

            if z_val < zb_row[x] then
                zb_row[x] = z_val
                fb_row[x] = rgb2col(r, g, b)
            end

            w = w + dw
            u = u + du
            v = v + dv
        end
        ::continue::
    end
end

local oh3d = {}
local vertex_pool, proj_pool = {}, {}

function oh3d.newModel(data)

    vertex_pool[data] = {}
    proj_pool[data] = {}
    return data
end

function oh3d.setPartColor(model, name, col)
    for i = 1, #model.parts do
        local p = model.parts[i]
        if p.name == name then
            model.materials[p.material] = { type = "color", value = col }
            return
        end
    end
    error("Part not found: "..name)
end

function oh3d.setPartTexture(model, name, tex)
    for i = 1, #model.parts do
        local p = model.parts[i]
        if p.name == name then
            model.materials[p.material] = { type = "texture", texture = tex }
            return
        end
    end
    error("Part not found: "..name)
end

function oh3d.render(model, transform, opts)
    clearBuffers()
    local world = vertex_pool[model] or {}
    local projected = proj_pool[model] or {}

    for i, v in ipairs(model.vertices) do
        world[i] = transform(v)
    end

    for i, w in ipairs(world) do
        projected[i] = {project(w[1], w[2], w[3])}
    end

    for pi = 1, #model.parts do
        local part = model.parts[pi]
        local mat = model.materials[part.material]

        for fi = 1, #part.faces do
            local face = part.faces[fi]
            local v1, v2, v3 = world[face[1]], world[face[2]], world[face[3]]

            local ax, ay, az = vec_sub(v2, v1)
            local bx, by, bz = vec_sub(v3, v1)
            local nx, ny, nz = vec_cross(ax, ay, az, bx, by, bz)

            local faceX = (v1[1] + v2[1] + v3[1]) / 3
            local faceY = (v1[2] + v2[2] + v3[2]) / 3
            local faceZ = (v1[3] + v2[3] + v3[3]) / 3

            local viewDirX = v1[1]  
            local viewDirY = v1[2]
            local viewDirZ = v1[3]

            if nx*viewDirX + ny*viewDirY + nz*viewDirZ < 0 then
                local p1, p2, p3 = projected[face[1]], projected[face[2]], projected[face[3]]

                if mat.type == "color" then
                    fillSolidTri(
                        p1[1], p1[2], p1[3],
                        p2[1], p2[2], p2[3],
                        p3[1], p3[2], p3[3],
                        mat.value
                    )
                elseif mat.type == "texture" then
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

    term_drawPixels(0, 0, fb)
end

local ogl = {}
ogl.MODELVIEW, ogl.PROJECTION = 0, 1
ogl.CULL_FACE, ogl.BACK = 0x0B44, 0x0405

local matrixMode = ogl.MODELVIEW
local MVstack, Pstack = { { {1,0,0,0,1,0,0,0,1}, {0,0,0} } }, { { {1,0,0,0,1,0,0,0,1}, {0,0,0} } }
local cullEnabled = true

function ogl.getMVstack()
    return MVstack
end

function ogl.Init()
    clearBuffers()
end

function ogl.ClearColor(r, g, b)
    clearColor = rgb2col(r*255, g*255, b*255)
end

function ogl.Clear()
    clearBuffers()
end

function ogl.MatrixMode(m)
    matrixMode = m
end

function ogl.LoadIdentity()
    local stk = matrixMode == ogl.MODELVIEW and MVstack or Pstack
    stk[#stk] = { {1,0,0,0,1,0,0,0,1}, {0,0,0} }
end

function ogl.PushMatrix()
    local stk = matrixMode == ogl.MODELVIEW and MVstack or Pstack
    local top = stk[#stk]
    stk[#stk+1] = {
        {top[1][1], top[1][2], top[1][3], top[1][4], top[1][5], top[1][6], top[1][7], top[1][8], top[1][9]},
        {top[2][1], top[2][2], top[2][3]}
    }
end

function ogl.PopMatrix()
    local stk = matrixMode == ogl.MODELVIEW and MVstack or Pstack
    if #stk > 1 then stk[#stk] = nil end
end

function ogl.Translatef(x, y, z)
    local stk = matrixMode == ogl.MODELVIEW and MVstack or Pstack
    local t = stk[#stk][2]
    t[1], t[2], t[3] = t[1]+x, t[2]+y, t[3]+z
end

function ogl.Rotatef(angle, x, y, z)
    local stk = matrixMode == ogl.MODELVIEW and MVstack or Pstack
    local mat = stk[#stk][1]
    angle = rad(angle)
    local c, s = cos(angle), sin(angle)
    local R

    if x > 0 then
        R = {1,0,0, 0,c,-s, 0,s,c}
    elseif y > 0 then
        R = {c,0,s, 0,1,0, -s,0,c}
    else
        R = {c,-s,0, s,c,0, 0,0,1}
    end

    local new_mat = {}
    for i=1,9 do new_mat[i] = mat[i] end

    for i=0,2 do
        for j=0,2 do
            local sum = 0
            for k=0,2 do
                sum = sum + R[i*3+k+1] * mat[k*3+j+1]
            end
            new_mat[i*3+j+1] = sum
        end
    end
    stk[#stk][1] = new_mat
end

function ogl.Perspective(fov, aspect, near, far)
    local f = 1 / tan(rad(fov)/2)
    projMatrix = {
        f/aspect, 0, 0,
        0, f, 0,
        0, 0, (far+near)/(near-far)
    }
end

for k,v in pairs(ogl) do
    oh3d[k] = v
end

return oh3d