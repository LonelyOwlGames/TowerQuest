return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.10.1",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 48,
  height = 49,
  tilewidth = 64,
  tileheight = 64,
  nextlayerid = 10,
  nextobjectid = 96,
  properties = {},
  tilesets = {
    {
      name = "dungeon",
      firstgid = 1,
      class = "",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      columns = 25,
      image = "Tileset.png",
      imagewidth = 1600,
      imageheight = 832,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 64,
        height = 64
      },
      properties = {},
      wangsets = {},
      tilecount = 325,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 48,
      height = 49,
      id = 1,
      name = "floor",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 35, 36, 35, 71, 35, 35, 35, 49, 247, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 237, 238, 238, 238, 238, 238, 238, 238, 244, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 294, 294, 294, 294, 294, 294, 294, 294, 294, 0, 35, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 262, 263, 263, 263, 263, 263, 263, 263, 269, 0, 0, 26, 252, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 220, 27, 28, 26, 0, 26, 26, 28, 220, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 35, 35, 35, 36, 36, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 26, 27, 28, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 182, 211, 183, 28, 185, 211, 186, 0, 36, 35, 36, 36, 35, 36, 35, 36, 36, 36, 35, 36, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 209, 0, 0, 0, 0, 26, 28, 28, 27, 26, 27, 27, 28, 26, 27, 28, 28, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 36, 233, 234, 235, 36, 36, 0, 26, 28, 27, 27, 28, 27, 26, 26, 26, 26, 26, 27, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 258, 259, 260, 26, 26, 0, 26, 27, 26, 27, 26, 27, 27, 26, 26, 26, 28, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 26, 26, 26, 27, 26, 28, 27, 26, 26, 27, 28, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 36, 36, 36, 36, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 36, 35, 26, 35, 35, 35, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 26, 26, 26, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 28, 26, 27, 28, 26, 0, 35, 36, 36, 26, 0, 0, 0, 0, 0, 28, 35, 35, 36, 36, 36, 26, 26, 278, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 28, 28, 28, 26, 26, 26, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 0, 0, 0, 26, 26, 26, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 28, 28, 27, 28, 27, 26, 36, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 26, 26, 26, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 28, 27, 28, 27, 28, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 0, 36, 35, 36, 35, 35, 35, 36, 0, 35, 35, 35, 252, 35, 36, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 0, 28, 28, 28, 26, 27, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 252, 28, 26, 26, 28, 27, 27, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 35, 36, 35, 35, 0, 0, 26, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 26, 28, 26, 28, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 28, 26, 0, 0, 26, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 0, 26, 28, 26, 26, 27, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 26, 28, 26, 28, 35, 35, 26, 0, 0, 0, 0, 26, 26, 26, 26, 26, 26, 26, 0, 26, 26, 26, 26, 26, 26, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 26, 28, 27, 28, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 26, 26, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 0, 35, 35, 35, 35, 0, 0, 35, 36, 36, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 36, 35, 35, 35, 35, 35, 35, 36, 35, 0, 0, 0, 0, 28, 36, 26, 26, 28, 26, 0, 0, 33, 26, 33, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 0, 0, 26, 27, 28, 27, 26, 28, 28, 28, 26, 0, 0, 0, 0, 26, 0, 27, 26, 26, 26, 0, 0, 26, 33, 26, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 35, 36, 28, 26, 27, 27, 27, 27, 27, 26, 27, 36, 36, 35, 35, 27, 0, 0, 0, 0, 0, 0, 0, 33, 26, 33, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 26, 28, 135, 135, 135, 28, 26, 26, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 33, 26, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 135, 135, 135, 0, 0, 0, 0, 0, 252, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33, 26, 33, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 35, 35, 26, 26, 26, 35, 35, 35, 0, 35, 26, 35, 0, 0, 0, 137, 36, 137, 35, 137, 26, 33, 26, 137, 35, 137, 35, 137, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 27, 26, 27, 0, 0, 0, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 27, 26, 26, 0, 0, 0, 26, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 36, 36, 35, 35, 36, 35, 26, 0, 0, 0, 0, 0, 183, 94, 185, 0, 0, 0, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 119, 0, 0, 0, 0, 26, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 35, 36, 252, 0, 0, 0, 0, 0, 36, 252, 35, 0, 0, 0, 0, 0, 144, 0, 0, 0, 0, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 27, 28, 0, 0, 0, 0, 0, 26, 278, 26, 0, 0, 0, 0, 0, 169, 0, 0, 0, 0, 26, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 28, 26, 26, 36, 36, 36, 0, 0, 26, 26, 26, 0, 0, 0, 0, 186, 194, 182, 0, 0, 0, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 33, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 28, 27, 28, 28, 28, 0, 0, 0, 26, 0, 0, 0, 0, 0, 26, 27, 27, 0, 0, 0, 26, 0, 134, 135, 135, 135, 135, 135, 135, 135, 135, 0, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 28, 27, 27, 26, 26, 0, 0, 0, 26, 0, 0, 0, 0, 0, 27, 28, 28, 0, 0, 0, 26, 0, 536870947, 33, 27, 33, 27, 33, 27, 33, 28, 0, 26, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 536870947, 33, 28, 33, 28, 33, 28, 33, 27, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 252, 0, 0, 35, 36, 36, 36, 252, 36, 35, 35, 35, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 26, 26, 27, 26, 26, 26, 27, 28, 26, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 36, 35, 27, 26, 26, 26, 27, 28, 27, 26, 27, 35, 35, 26, 36, 35, 35, 35, 36, 35, 36, 35, 36, 36, 26, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 26, 26, 27, 27, 28, 26, 27, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 26, 26, 26, 27, 27, 27, 27, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 48,
      height = 49,
      id = 2,
      name = "wall",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        3, 3, 1, 2, 46, 199, 2, 1, 222, 223, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 0, 0, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 0, 1, 97, 2, 279, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        2, 2, 1, 4, 2, 1, 2, 2, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 279, 4, 1, 97, 3, 2, 2, 3, 3, 97, 2, 2, 279, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 1, 208, 0, 210, 1, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 1, 1, 0, 4, 1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 3, 4, 2, 3, 279, 3, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 97, 1, 0, 3, 97, 4, 4, 2, 4, 3, 0, 3, 4, 3, 4, 3, 0, 1, 3, 1, 4, 3, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4, 3, 96, 4, 0, 4, 0, 0, 0, 4, 0, 1, 3, 96, 3, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 3, 1, 4, 0, 0, 0, 3, 1, 4, 0, 1, 2, 3, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 4, 4, 3, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 2, 304, 1, 1, 2, 3, 4, 2, 3, 97, 4, 0, 2, 97, 2, 4, 4, 1, 1, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4, 3, 4, 0, 4, 4, 3, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 279, 2, 1, 2, 0, 1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 2, 1, 0, 1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 96, 3, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 2, 0, 1, 0, 0, 1, 2, 1, 4, 1, 3, 3, 2, 2, 2, 3, 2, 0, 2, 1, 1, 1, 2, 3, 4, 4, 1, 3, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 2, 1, 0, 3, 4, 1, 1, 97, 1, 2, 3, 97, 2, 3, 1, 0, 0, 1, 0, 3, 0, 0, 0, 0, 3, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 3, 1, 2, 2, 2, 3, 3, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 4, 3, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 97, 1, 0, 4, 0, 0, 0, 0, 2, 3, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 4, 4, 2, 2, 4, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 2, 1, 4, 0, 0, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 4, 127, 0, 0, 0, 126, 4, 1, 3, 2, 0, 1, 4, 0, 2, 87, 97, 87, 97, 87, 0, 0, 0, 87, 97, 87, 97, 87, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 3, 3, 2, 2, 0, 4, 3, 3, 3, 3, 0, 0, 0, 4, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 3, 4, 304, 3, 96, 4, 2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 96, 2, 0, 2, 2, 2, 1, 4, 1, 0, 4, 2, 0, 0, 2, 118, 0, 120, 3, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 2, 143, 0, 145, 4, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 97, 279, 3, 4, 3, 0, 0, 0, 4, 0, 0, 3, 168, 0, 170, 3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 2, 2, 0, 0, 1, 0, 0, 0, 2, 0, 1, 0, 54, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 3, 0, 1, 0, 0, 0, 4, 0, 0, 0, 3, 0, 4, 0, 54, 0, 0, 0, 0, 0, 0, 0, 0, 0, 55, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 4, 4, 0, 4, 4, 2, 4, 97, 3, 0, 2, 97, 1, 1, 3, 1, 0, 2, 3, 0, 4, 59, 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 59, 4, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 4, 0, 1, 1, 0, 3, 3, 2, 2, 1, 1, 2, 0, 3, 2, 1, 3, 1, 1, 3, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 0, 1, 1, 304, 96, 3, 1, 2, 96, 3, 4, 0, 4, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 3, 3, 1, 1, 2, 4, 3, 2, 2, 4, 4, 3, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 1, 2, 1, 2, 2, 4, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 9,
      name = "entities",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 88,
          name = "door",
          type = "",
          shape = "rectangle",
          x = 640,
          y = 256,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 9,
          visible = true,
          properties = {
            ["isDoor"] = true,
            ["isDoorLocked"] = false,
            ["isDoorOpen"] = false,
            ["tileReplaceId"] = 35
          }
        },
        {
          id = 93,
          name = "door",
          type = "",
          shape = "rectangle",
          x = 832,
          y = 384,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 9,
          visible = true,
          properties = {
            ["isDoor"] = true,
            ["isDoorLocked"] = false,
            ["isDoorOpen"] = false,
            ["tileReplaceId"] = 35
          }
        },
        {
          id = 94,
          name = "door",
          type = "",
          shape = "rectangle",
          x = 896,
          y = 1344,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 9,
          visible = true,
          properties = {
            ["isDoor"] = true,
            ["isDoorLocked"] = true,
            ["isDoorOpen"] = false,
            ["tileReplaceId"] = 35
          }
        },
        {
          id = 92,
          name = "Player",
          type = "",
          shape = "rectangle",
          x = 407.333,
          y = 216.667,
          width = 17.3333,
          height = 17.3333,
          rotation = 0,
          visible = false,
          properties = {}
        },
        {
          id = 95,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = 384,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 311,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
