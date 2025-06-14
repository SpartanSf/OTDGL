local gl = require("oh3d")

gl.Init()
gl.ClearColor(0, 0, 0, 1)
gl.Enable(gl.CULL_FACE)
gl.CullFace(gl.BACK)
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
		mat1 = { type = "texture", texture = Bitmap.from_file("oh3d/texture.bmp") },
		mat2 = { type = "color", value = colors.lime },
		mat3 = { type = "color", value = colors.blue },
		mat4 = { type = "color", value = colors.yellow },
		mat5 = { type = "color", value = colors.orange },
	},
})

local width, height = term.getSize(1)

local t = 0
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

	gl.DrawModel(cube)

	t = t + 0.03
end

gl.MainLoop(draw)
