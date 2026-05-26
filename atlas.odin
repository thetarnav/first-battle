package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Corpse_3,
    Corpse_2,
    Corpse_1,
    Heavy_Enemy,
    Rider_Enemy,
    Infantry_Player,
    Archer_Player,
    Infantry_Enemy,
    Archer_Enemy,
    Rider_Player,
    Heavy_Player,
    Automatic_Off,
    Automatic_On,
    Border_TL,
    Border_BL,
    Border_BR,
    Border_TR,
    Border_L,
    Border_R,
    Border_T,
    Border_B,
}

atlas_rects: [Atlas_Slice]Rect = {
    .Corpse_3 = {{0, 0}, {6, 9}},
    .Corpse_2 = {{6, 0}, {7, 7}},
    .Corpse_1 = {{13, 0}, {7, 7}},
    .Heavy_Enemy = {{20, 0}, {7, 7}},
    .Rider_Enemy = {{27, 0}, {7, 10}},
    .Infantry_Player = {{34, 0}, {7, 7}},
    .Archer_Player = {{41, 0}, {7, 7}},
    .Infantry_Enemy = {{48, 0}, {7, 7}},
    .Archer_Enemy = {{55, 0}, {7, 7}},
    .Rider_Player = {{62, 0}, {7, 10}},
    .Heavy_Player = {{69, 0}, {7, 7}},
    .Automatic_Off = {{76, 0}, {14, 14}},
    .Automatic_On = {{90, 0}, {14, 14}},
    .Border_TL = {{104, 0}, {6, 6}},
    .Border_BL = {{110, 0}, {6, 6}},
    .Border_BR = {{116, 0}, {6, 6}},
    .Border_TR = {{122, 0}, {6, 6}},
    .Border_L = {{128, 0}, {6, 2}},
    .Border_R = {{134, 0}, {6, 2}},
    .Border_T = {{140, 0}, {2, 6}},
    .Border_B = {{142, 0}, {2, 6}},
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

