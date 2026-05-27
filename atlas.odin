package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Title,
    Border_B,
    Border_T,
    Border_R,
    Border_L,
    Border_TR,
    Border_BR,
    Border_BL,
    Border_TL,
    Automatic_On_Player,
    Automatic_Off_Player,
    Heavy_Player,
    Rider_Player,
    Archer_Enemy,
    Infantry_Enemy,
    Archer_Player,
    Infantry_Player,
    Rider_Enemy,
    Heavy_Enemy,
    Corpse_1,
    Corpse_2,
    Corpse_3,
    Play,
    Automatic_Off_Enemy,
    Automatic_On_Enemy,
}

atlas_rects: [Atlas_Slice]Rect = {
    .Title    = {{0, 0}, {87, 26}},
    .Border_B = {{87, 0}, {2, 6}},
    .Border_T = {{89, 0}, {2, 6}},
    .Border_R = {{91, 0}, {6, 2}},
    .Border_L = {{97, 0}, {6, 2}},
    .Border_TR = {{103, 0}, {6, 6}},
    .Border_BR = {{109, 0}, {6, 6}},
    .Border_BL = {{115, 0}, {6, 6}},
    .Border_TL = {{121, 0}, {6, 6}},
    .Automatic_On_Player = {{0, 26}, {14, 14}},
    .Automatic_Off_Player = {{14, 26}, {14, 14}},
    .Heavy_Player = {{28, 26}, {7, 7}},
    .Rider_Player = {{35, 26}, {7, 10}},
    .Archer_Enemy = {{42, 26}, {7, 7}},
    .Infantry_Enemy = {{49, 26}, {7, 7}},
    .Archer_Player = {{56, 26}, {7, 7}},
    .Infantry_Player = {{63, 26}, {7, 7}},
    .Rider_Enemy = {{70, 26}, {7, 10}},
    .Heavy_Enemy = {{77, 26}, {7, 7}},
    .Corpse_1 = {{84, 26}, {7, 7}},
    .Corpse_2 = {{91, 26}, {7, 7}},
    .Corpse_3 = {{98, 26}, {6, 9}},
    .Play     = {{0, 40}, {30, 12}},
    .Automatic_Off_Enemy = {{30, 40}, {14, 14}},
    .Automatic_On_Enemy = {{44, 40}, {14, 14}},
}

PALETTE_COLOR_0 :: Color{0, 0, 0, 0}
PALETTE_COLOR_1 :: Color{68, 21, 10, 255}
PALETTE_COLOR_2 :: Color{135, 86, 75, 255}
PALETTE_COLOR_3 :: Color{124, 94, 86, 255}
PALETTE_COLOR_4 :: Color{195, 163, 138, 255}
PALETTE_COLOR_5 :: Color{246, 214, 189, 255}
PALETTE_COLOR_6 :: Color{68, 50, 44, 123}
PALETTE_COLOR_7 :: Color{32, 57, 79, 255}
PALETTE_COLOR_8 :: Color{78, 73, 95, 255}
PALETTE_COLOR_9 :: Color{129, 98, 113, 255}
PALETTE_COLOR_10 :: Color{179, 131, 99, 255}

