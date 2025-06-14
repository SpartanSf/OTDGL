term.setGraphicsMode(1)
local Bitmap = require("lua-bitmap")
local colors = colors

local function rgb2col(r, g, b)
	local maxc = math.max(r, g, b)
	if maxc < 32 then
		return colors.black
	end
	if r > g and r > b then
		return colors.red
	end
	if g > r and g > b then
		return colors.lime
	end
	if b > r and b > g then
		return colors.blue
	end
	if r == g and r > b then
		return colors.yellow
	end
	if g == b and g > r then
		return colors.cyan
	end
	if b == r and b > g then
		return colors.purple
	end
	return colors.white
end

local function matMul3(m, v)
	return {
		m[1] * v[1] + m[2] * v[2] + m[3] * v[3],
		m[4] * v[1] + m[5] * v[2] + m[6] * v[3],
		m[7] * v[1] + m[8] * v[2] + m[9] * v[3],
	}
end
local function sub(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end
local function cross(a, b)
	return {
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1],
	}
end
local function dot(a, b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function rotY(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rotX(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end

local W, H = term.getSize(1)
local fovy, aspect, fovx, scaleY, scaleX
do
	fovy = math.rad(90)
	aspect = W / H
	fovx = 2 * math.atan(math.tan(fovy / 2) * aspect)
	scaleY = 1 / math.tan(fovy / 2)
	scaleX = 1 / math.tan(fovx / 2)
end
local function project(v)
	return {
		x = math.floor((v[1] * scaleX / -v[3] + 1) * W / 2),
		y = math.floor((v[2] * scaleY / -v[3] + 1) * H / 2),
		z = -v[3],
	}
end

local fb, zb, clearColor = {}, {}, colors.black
local function clearBuffers()
	for y = 0, H - 1 do
		fb[y], zb[y] = {}, {}
		for x = 0, W - 1 do
			fb[y][x] = clearColor
			zb[y][x] = math.huge
		end
	end
end

local function drawPixel(x, y, col, z)
	if x >= 0 and x < W and y >= 0 and y < H and z < zb[y][x] then
		zb[y][x], fb[y][x] = z, col
	end
end

local function fillSolidTri(p0, p1, p2, col)
	local function edge(a, b, c)
		return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
	end
	local area = edge(p0, p1, p2)
	if area == 0 then
		return
	end
	local minX, maxX = math.max(0, math.min(p0.x, p1.x, p2.x)), math.min(W - 1, math.max(p0.x, p1.x, p2.x))
	local minY, maxY = math.max(0, math.min(p0.y, p1.y, p2.y)), math.min(H - 1, math.max(p0.y, p1.y, p2.y))
	for y = minY, maxY do
		for x = minX, maxX do
			local P = { x = x + 0.5, y = y + 0.5 }
			local w0, w1, w2 = edge(p1, p2, P), edge(p2, p0, P), edge(p0, p1, P)
			if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0) then
				w0, w1, w2 = w0 / area, w1 / area, w2 / area
				local z = 1 / (w0 / p0.z + w1 / p1.z + w2 / p2.z)
				drawPixel(x, y, col, z)
			end
		end
	end
end

local function fillTexturedTri(p0, p1, p2, uv0, uv1, uv2, texture)
	if p1.y < p0.y then
		p0, p1, uv0, uv1 = p1, p0, uv1, uv0
	end
	if p2.y < p0.y then
		p0, p2, uv0, uv2 = p2, p0, uv2, uv0
	end
	if p2.y < p1.y then
		p1, p2, uv1, uv2 = p2, p1, uv2, uv1
	end

	local function prep(p, uv)
		local w = 1 / p.z
		return { x = p.x, y = p.y, z = p.z, w = w, uoz = uv[1] * w, voz = uv[2] * w }
	end
	local V0, V1, V2 = prep(p0, uv0), prep(p1, uv1), prep(p2, uv2)
	local function interp(a, b)
		local tbl, dy = {}, b.y - a.y
		if dy == 0 then
			tbl[a.y] = a
		else
			for y = a.y, b.y do
				local t = (y - a.y) / dy
				tbl[y] = {
					x = a.x + (b.x - a.x) * t,
					z = a.z + (b.z - a.z) * t,
					w = a.w + (b.w - a.w) * t,
					uoz = a.uoz + (b.uoz - a.uoz) * t,
					voz = a.voz + (b.voz - a.voz) * t,
				}
			end
		end
		return tbl
	end

	local E0, E1, E2 = interp(V0, V2), interp(V0, V1), interp(V1, V2)
	local tw, th = texture.width, texture.height
	for y = p0.y, p2.y do
		local L = E0[y]
		local R = (y <= p1.y and E1 or E2)[y]
		if L and R then
			if L.x > R.x then
				L, R = R, L
			end
			local dx = R.x - L.x
			for i = 0, dx do
				local t = (dx == 0 and 0 or i / dx)
				local w = L.w + (R.w - L.w) * t
				local u = (L.uoz + (R.uoz - L.uoz) * t) / w
				local v = (L.voz + (R.voz - L.voz) * t) / w
				local tx, ty = math.floor(u * (tw - 1)), math.floor(v * (th - 1))
				local r, g, b = texture:get_pixel(tx, ty)
				drawPixel(math.floor(L.x + i), y, rgb2col(r, g, b), 1 / w)
			end
		end
	end
end

local oh3d = {}
function oh3d.newModel(data)
	assert(data.vertices and data.parts and data.materials, "Invalid model data")
	return data
end
function oh3d.setPartColor(model, name, col)
	for _, p in ipairs(model.parts) do
		if p.name == name then
			model.materials[p.material] = { type = "color", value = col }
			return
		end
	end
	error("Part not found: " .. tostring(name))
end
function oh3d.setPartTexture(model, name, tex)
	for _, p in ipairs(model.parts) do
		if p.name == name then
			model.materials[p.material] = { type = "texture", texture = tex }
			return
		end
	end
	error("Part not found: " .. tostring(name))
end

function oh3d.render(model, transform, opts)
	opts = opts or {}
	local force = opts.forceRender
	clearBuffers()
	local world, viewDir = {}, { 0, 0, -1 }
	for i, v in ipairs(model.vertices) do
		world[i] = transform(v)
	end

	for _, part in ipairs(model.parts) do
		local mat = model.materials[part.material]
		for fi, face in ipairs(part.faces) do
			local p0, p1, p2 = world[face[1]], world[face[2]], world[face[3]]
			local norm = cross(sub(p1, p0), sub(p2, p0))
			local isFront = dot(norm, viewDir) > 0
			if force or isFront then
				local pp0, pp1, pp2 = project(p0), project(p1), project(p2)
				if mat.type == "color" then
					fillSolidTri(pp0, pp1, pp2, mat.value)
				else
					fillTexturedTri(pp0, pp1, pp2, part.uvs[fi][1], part.uvs[fi][2], part.uvs[fi][3], mat.texture)
				end
			end
		end
	end

	local rows = {}
	for y = 0, H - 1 do
		local r = {}
		for x = 0, W - 1 do
			r[x + 1] = fb[y][x]
		end
		rows[y + 1] = r
	end
	term.drawPixels(0, 0, rows)
end

local ogl = {}
ogl.MODELVIEW, ogl.PROJECTION = 0, 1
ogl.CULL_FACE, ogl.BACK, ogl.FRONT = 0x0B44, 0x0405, 0x0404

local matrixMode = ogl.MODELVIEW
local MVstack, Pstack = { {} }, { {} }
local cullEnabled, cullFace = false, ogl.BACK

local function currentStack()
	return (matrixMode == ogl.MODELVIEW) and MVstack or Pstack
end

function ogl.Init()
	clearBuffers()
end
function ogl.ClearColor(r, g, b, a)
	clearColor = rgb2col(r * 255, g * 255, b * 255)
end
function ogl.Clear()
	clearBuffers()
end
function ogl.ViewportWidth()
	return W
end
function ogl.ViewportHeight()
	return H
end

function ogl.MatrixMode(m)
	matrixMode = m
end
function ogl.LoadIdentity()
	local stk = currentStack()
	stk[#stk] = { { 1, 0, 0, 0, 1, 0, 0, 0, 1 }, { 0, 0, 0 } }
end
function ogl.PushMatrix()
	local stk = currentStack()
	local top = stk[#stk]
	stk[#stk + 1] = {
		{ top[1][1], top[1][2], top[1][3], top[1][4], top[1][5], top[1][6], top[1][7], top[1][8], top[1][9] },
		{ top[2][1], top[2][2], top[2][3] },
	}
end
function ogl.PopMatrix()
	local stk = currentStack()
	assert(#stk > 1, "PopMatrix underflow")
	stk[#stk] = nil
end
function ogl.Translatef(x, y, z)
	local stk = currentStack()
	local t = stk[#stk][2]
	t[1], t[2], t[3] = t[1] + x, t[2] + y, t[3] + z
end
function ogl.Rotatef(anogle, x, y, z)
	local stk = currentStack()
	local mat = stk[#stk][1]
	local R = (x == 1 and rotX(math.rad(anogle))) or (y == 1 and rotY(math.rad(anogle))) or R

	local M = {}
	for r = 0, 2 do
		for c = 0, 2 do
			local sum = 0
			for k = 0, 2 do
				sum = sum + R[r * 3 + k + 1] * mat[k * 3 + c + 1]
			end
			M[r * 3 + c + 1] = sum
		end
	end
	stk[#stk][1] = M
end

function ogl.Enable(cap)
	if cap == ogl.CULL_FACE then
		cullEnabled = true
	end
end
function ogl.Disable(cap)
	if cap == ogl.CULL_FACE then
		cullEnabled = false
	end
end
function ogl.CullFace(face)
	cullFace = face
end

function ogl.NewModel(data)
	return oh3d.newModel(data)
end
function ogl.ColorMaterial(mdl, name, r, g, b)
	oh3d.setPartColor(mdl, name, rgb2col(r * 255, g * 255, b * 255))
end
function ogl.BindTexture(mdl, name, tex)
	oh3d.setPartTexture(mdl, name, tex)
end

function ogl.DrawModel(model)
	local mv = MVstack[#MVstack]
	local mat, trs = mv[1], mv[2]
	local function transform(v)
		local w = matMul3(mat, v)
		return { w[1] + trs[1], w[2] + trs[2], w[3] + trs[3] }
	end
	oh3d.render(model, transform, { forceRender = not cullEnabled })
end

function ogl.Perspective(fovY, aspectArg, zNear, zFar)
	fovy = math.rad(fovY)
	aspect = aspectArg
	fovx = 2 * math.atan(math.tan(fovy / 2) * aspect)
	scaleY = 1 / math.tan(fovy / 2)
	scaleX = 1 / math.tan(fovx / 2)
end

function ogl.MainLoop(drawFunc)
	while true do
		drawFunc()
		sleep(0)
	end
end

for k, v in pairs(ogl) do
	oh3d[k] = v
end
return oh3d