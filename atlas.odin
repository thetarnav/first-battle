package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Automatic_Off,
    Automatic_On,
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
}

atlas_rects: [Atlas_Slice]Rect = {
    .Automatic_Off = {{0, 0}, {14, 14}},
    .Automatic_On = {{14, 0}, {14, 14}},
    .Heavy_Player = {{28, 0}, {7, 7}},
    .Rider_Player = {{35, 0}, {7, 10}},
    .Archer_Enemy = {{42, 0}, {7, 7}},
    .Infantry_Enemy = {{49, 0}, {7, 7}},
    .Archer_Player = {{56, 0}, {7, 7}},
    .Infantry_Player = {{63, 0}, {7, 7}},
    .Rider_Enemy = {{70, 0}, {7, 10}},
    .Heavy_Enemy = {{77, 0}, {7, 7}},
    .Corpse_1 = {{84, 0}, {7, 7}},
    .Corpse_2 = {{91, 0}, {7, 7}},
    .Corpse_3 = {{98, 0}, {6, 9}},
}

PALETTE_COLOR_0 :: Color{0, 0, 0, 0}
PALETTE_COLOR_1 :: Color{15, 42, 63, 255}
PALETTE_COLOR_2 :: Color{32, 57, 79, 255}
PALETTE_COLOR_3 :: Color{246, 214, 189, 255}
PALETTE_COLOR_4 :: Color{195, 163, 138, 255}
PALETTE_COLOR_5 :: Color{153, 117, 119, 255}
PALETTE_COLOR_6 :: Color{129, 98, 113, 255}
PALETTE_COLOR_7 :: Color{78, 73, 95, 255}
PALETTE_COLOR_8 :: Color{181, 99, 70, 255}
PALETTE_COLOR_9 :: Color{86, 45, 36, 255}
PALETTE_COLOR_10 :: Color{128, 95, 88, 255}

