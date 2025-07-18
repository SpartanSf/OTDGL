local util = require("otdgl_util")

local cubedata = {
    vertices = {
        {  1, -1,  1 },
        { -1, -1,  1 },
        { -1,  1,  1 },
        {  1,  1,  1 },
        {  1, -1, -1 },
        { -1, -1, -1 },
        { -1,  1, -1 },
        {  1,  1, -1 },
    },
    parts = {
        {
            name = "front",
            faces = { { 1, 4, 3 }, { 1, 3, 2 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat0",
        },
        {
            name = "back",
            faces = { { 5, 6, 7 }, { 5, 7, 8 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat1",
        },
        {
            name = "left",
            faces = { { 2, 3, 7 }, { 2, 7, 6 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat2",
        },
        {
            name = "right",
            faces = { { 1, 5, 8 }, { 1, 8, 4 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat3",
        },
        {
            name = "top",
            faces = { { 4, 8, 7 }, { 4, 7, 3 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat4",
        },
        {
            name = "bottom",
            faces = { { 1, 2, 6 }, { 1, 6, 5 } },
            uvs = { { { 0, 1 }, { 1, 1 }, { 1, 0 } }, { { 0, 1 }, { 1, 0 }, { 0, 0 } } },
            material = "mat5",
        },
    },
    materials = {
        mat0 = { type = "color", value = colors.red },
        mat1 = { type = "texture", texture = "otdgl/assets/doom2.bmp" },
        mat2 = { type = "color", value = colors.green },
        mat3 = { type = "color", value = colors.cyan },
        mat4 = { type = "color", value = colors.yellow },
        mat5 = { type = "color", value = colors.orange },
    },
}

local cubeFile = fs.open("otdgl/models/cube.umdl", "w")
cubeFile.write(textutils.serialise(util.encodeModel(cubedata)))
cubeFile.close()