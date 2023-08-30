local themes = {}

-- This theme focuses on a grid like dungeon full of jail cells
themes.dungeon = {
    types = {
        -- { shape = 'square', w = {4, 4}, h = {4, 5} }, -- Square
        -- { shape = 'square', w = {4, 8}, h = {3, 4} }, -- Horizontal
        { shape = 'square', w = {3, 4}, h = {4, 8} }, -- Vertical
        { shape = 'square', w = {4}, h = {4} }, -- Square (fixed)
        { shape = 'square', w = {6}, h = {6} }, -- Square (fixed)
        { shape = 'hallway', type = 'vertical' },
        { shape = 'hallway', type = 'downleft' },
        { shape = 'hallway', type = 'upright' },
        -- { shape = 'combine', type = 't', offset = {0,0}, combine = {
            -- { shape = 'square', w = {3, 3}, h = {5, 6} },
            -- { shape = 'square', w = {5, 6}, h = {4, 4} },
        -- }}
    }
}


return themes
