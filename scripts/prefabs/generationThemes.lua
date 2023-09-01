local themes = {}

-- This theme focuses on a grid like dungeon full of jail cells
themes.dungeon = {
    dungeonWidth = 100,
    dungeonHeight = 100,
    rooms = 15,
    spanType = 'last',
    types = {
        { shape = 'square', w = {4, 4}, h = {4, 5}, weight = 10}, -- Square
        { shape = 'square', w = {4, 8}, h = {3, 4}, weight = 10}, -- Horizontal
        { shape = 'square', w = {3, 4}, h = {4, 8}, weight = 10}, -- Vertical
        { shape = 'square', w = {4}, h = {4}, weight = 10 }, -- Square (fixed)
        { shape = 'square', w = {6}, h = {6}, weight = 10 }, -- Square (fixed)
        { shape = 'hallway', type = 'vertical', weight = 100 },
        { shape = 'hallway', type = 'downleft', weight = 100 },
        { shape = 'hallway', type = 'upright', weight = 100 },
        { shape = 'combine', type = 't', offset = {0,0}, weight = 10, combine = {
            { shape = 'square', w = {3, 3}, h = {5, 6} },
            { shape = 'square', w = {5, 6}, h = {4, 4} },
        }}
    }
}

themes.mine = {
    dungeonWidth = 100,
    dungeonHeight = 100,
    rooms = 30,
    spanType = 'center',
    types = {
        { shape = 'cellauto', w = {15, 20}, h = {15, 20}, weight = 90 },
        { shape = 'square', w = {6, 8}, h = {6, 8}, weight = 1 },
        { shape = 'hallway', type = 'vertical', weight = 50 },
    }
}


return themes
