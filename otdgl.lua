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

local function rgb2col(r, g, b)
	r, g, b = r or 0, g or 0, b or 0

	local d_black = r * r + g * g + b * b
	local dist, best_col = d_black, colors_black

	local d_red = (255 - r) ^ 2 + g ^ 2 + b ^ 2
	if d_red < dist then
		dist, best_col = d_red, colors_red
	end

	local d_lime = r ^ 2 + (255 - g) ^ 2 + b ^ 2
	if d_lime < dist then
		dist, best_col = d_lime, colors_lime
	end

	local d_blue = r ^ 2 + g ^ 2 + (255 - b) ^ 2
	if d_blue < dist then
		dist, best_col = d_blue, colors_blue
	end

	local d_yellow = (255 - r) ^ 2 + (255 - g) ^ 2 + b ^ 2
	if d_yellow < dist then
		dist, best_col = d_yellow, colors_yellow
	end

	local d_cyan = r ^ 2 + (255 - g) ^ 2 + (255 - b) ^ 2
	if d_cyan < dist then
		dist, best_col = d_cyan, colors_cyan
	end

	local d_purple = (255 - r) ^ 2 + g ^ 2 + (255 - b) ^ 2
	if d_purple < dist then
		dist, best_col = d_purple, colors_purple
	end

	local d_white = (255 - r) ^ 2 + (255 - g) ^ 2 + (255 - b) ^ 2
	if d_white < dist then
		best_col = colors_white
	end

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
	return (px * iz + 1) * 0.5 * W, (py * iz + 1) * 0.5 * H
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

local solidColorTextures = {}

local function getSolidTexture(color)
	if not solidColorTextures[color] then
		solidColorTextures[color] = {
			width = 1,
			height = 1,
			get_pixel = function(_, x, y)
				if color == colors.white then
					return 255, 255, 255
				elseif color == colors.orange then
					return 255, 165, 0
				elseif color == colors.magenta then
					return 255, 0, 255
				elseif color == colors.lightBlue then
					return 173, 216, 230
				elseif color == colors.yellow then
					return 255, 255, 0
				elseif color == colors.lime then
					return 0, 255, 0
				elseif color == colors.pink then
					return 255, 192, 203
				elseif color == colors.gray then
					return 128, 128, 128
				elseif color == colors.lightGray then
					return 192, 192, 192
				elseif color == colors.cyan then
					return 0, 255, 255
				elseif color == colors.purple then
					return 128, 0, 128
				elseif color == colors.blue then
					return 0, 0, 255
				elseif color == colors.brown then
					return 139, 69, 19
				elseif color == colors.green then
					return 0, 128, 0
				elseif color == colors.red then
					return 255, 0, 0
				else
					return 0, 0, 0
				end
			end,
		}
	end
	return solidColorTextures[color]
end

local function fillTexturedTri(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z, u0x, u0y, u1x, u1y, u2x, u2y, tex)
	if p1y < p0y then
		p0x, p0y, p0z, p1x, p1y, p1z, u0x, u0y, u1x, u1y = p1x, p1y, p1z, p0x, p0y, p0z, u1x, u1y, u0x, u0y
	end
	if p2y < p0y then
		p0x, p0y, p0z, p2x, p2y, p2z, u0x, u0y, u2x, u2y = p2x, p2y, p2z, p0x, p0y, p0z, u2x, u2y, u0x, u0y
	end
	if p2y < p1y then
		p1x, p1y, p1z, p2x, p2y, p2z, u1x, u1y, u2x, u2y = p2x, p2y, p2z, p1x, p1y, p1z, u2x, u2y, u1x, u1y
	end

	if p0y == p2y then
		return
	end

	local w0, w1, w2 = 1 / p0z, 1 / p1z, 1 / p2z
	local uw0, vw0 = u0x * w0, u0y * w0
	local uw1, vw1 = u1x * w1, u1y * w1
	local uw2, vw2 = u2x * w2, u2y * w2

	local dX1, dY1 = p1x - p0x, p1y - p0y
	local dX2, dY2 = p2x - p0x, p2y - p0y
	local area = dX1 * dY2 - dX2 * dY1
	if area == 0 then
		return
	end

	local invArea = 1 / area

	local minX = max(1, floor(min(p0x, p1x, p2x) + 0.5))
	local maxX = min(W, floor(max(p0x, p1x, p2x) + 0.5))
	local minY = max(1, floor(min(p0y, p1y, p2y) + 0.5))
	local maxY = min(H, floor(max(p0y, p1y, p2y) + 0.5))

	for y = minY, maxY do
		for x = minX, maxX do
			local vx, vy = x - p0x + 0.5, y - p0y + 0.5
			local s = (vx * dY2 - vy * dX2) * invArea
			local t = (vy * dX1 - vx * dY1) * invArea

			if s >= 0 and t >= 0 and s + t <= 1 then
				local u = 1 - s - t
				local z = u * p0z + s * p1z + t * p2z
				local w = u * w0 + s * w1 + t * w2
				local iz = 1 / w

				if z < zb[y][x] then
					zb[y][x] = z

					local u_coord = (u * uw0 + s * uw1 + t * uw2) * iz
					local v_coord = (u * vw0 + s * vw1 + t * vw2) * iz

					local texX = floor(u_coord * (tex.width - 1) + 0.5)
					local texY = floor(v_coord * (tex.height - 1) + 0.5)
					local r, g, b = tex.get_pixel(tex, texX, texY)

					fb[y][x] = rgb2col(r, g, b)
				end
			end
		end
	end
end

local function fillSolidTri(x0, y0, z0, x1, y1, z1, x2, y2, z2, color)
	local tex = getSolidTexture(color)
	fillTexturedTri(x0, y0, z0, x1, y1, z1, x2, y2, z2, 0, 0, 0, 0, 0, 0, tex)
end

local otdgl = {}
local vertex_pool, proj_pool = {}, {}

function otdgl.newModel(data)
	vertex_pool[data] = {}
	proj_pool[data] = {}
	return data
end

function otdgl.setPartColor(model, name, col)
	for i = 1, #model.parts do
		local p = model.parts[i]
		if p.name == name then
			model.materials[p.material] = { type = "color", value = col }
			return
		end
	end
	error("Part not found: " .. name)
end

function otdgl.setPartTexture(model, name, tex)
	for i = 1, #model.parts do
		local p = model.parts[i]
		if p.name == name then
			model.materials[p.material] = { type = "texture", texture = tex }
			return
		end
	end
	error("Part not found: " .. name)
end

function otdgl.render(model, transform, opts)
	clearBuffers()

	local world = vertex_pool[model] or {}
	local projected = proj_pool[model] or {}

	for i, v in ipairs(model.vertices) do
		world[i] = transform(v)
	end

	for i, w in ipairs(world) do
		local sx, sy = project(w[1], w[2], w[3])
		projected[i] = { sx, sy, w[3] }
	end

	for _, part in ipairs(model.parts) do
		local mat = model.materials[part.material]

		for fi, face in ipairs(part.faces) do
			local v1, v2, v3 = world[face[1]], world[face[2]], world[face[3]]
			local p1, p2, p3 = projected[face[1]], projected[face[2]], projected[face[3]]

			local ax, ay, az = v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]
			local bx, by, bz = v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]
			local nx, ny, nz = vec_cross(ax, ay, az, bx, by, bz)
			local cx = (v1[1] + v2[1] + v3[1]) / 3
			local cy = (v1[2] + v2[2] + v3[2]) / 3
			local cz = (v1[3] + v2[3] + v3[3]) / 3
			local dot = nx * -cx + ny * -cy + nz * -cz

			if dot > 0 then
				if mat.type == "color" then
					fillSolidTri(p1[1], p1[2], p1[3], p2[1], p2[2], p2[3], p3[1], p3[2], p3[3], mat.value)
				else
					local uv = part.uvs[fi]
					fillTexturedTri(
						p1[1],
						p1[2],
						p1[3],
						p2[1],
						p2[2],
						p2[3],
						p3[1],
						p3[2],
						p3[3],
						uv[1][1],
						uv[1][2],
						uv[2][1],
						uv[2][2],
						uv[3][1],
						uv[3][2],
						mat.texture
					)
				end
			end
		end
	end

	term_drawPixels(0, 0, fb)
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

function otdgl.Clear()
	clearBuffers()
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
		1,
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

return otdgl
