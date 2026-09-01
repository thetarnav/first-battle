package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Reset,
    Sound_Off,
    Sound_On,
    Automatic_On_Enemy,
    Automatic_Off_Enemy,
    Play,
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
    Automatic_Off_Player,
    Automatic_On_Player,
    Border_TL,
    Border_BL,
    Border_BR,
    Border_TR,
    Border_L,
    Border_R,
    Border_T,
    Border_B,
    Title,
    Win_Player,
    Win_Enemy,
}

atlas_rects: [Atlas_Slice]Rect = {
    .Reset    = {{0, 0}, {36, 12}},
    .Sound_Off = {{36, 0}, {15, 14}},
    .Sound_On = {{51, 0}, {15, 14}},
    .Automatic_On_Enemy = {{66, 0}, {14, 14}},
    .Automatic_Off_Enemy = {{80, 0}, {14, 14}},
    .Play     = {{94, 0}, {30, 12}},
    .Corpse_3 = {{0, 14}, {6, 9}},
    .Corpse_2 = {{6, 14}, {7, 7}},
    .Corpse_1 = {{13, 14}, {7, 7}},
    .Heavy_Enemy = {{20, 14}, {7, 7}},
    .Rider_Enemy = {{27, 14}, {7, 10}},
    .Infantry_Player = {{34, 14}, {7, 7}},
    .Archer_Player = {{41, 14}, {7, 7}},
    .Infantry_Enemy = {{48, 14}, {7, 7}},
    .Archer_Enemy = {{55, 14}, {7, 7}},
    .Rider_Player = {{62, 14}, {7, 10}},
    .Heavy_Player = {{69, 14}, {7, 7}},
    .Automatic_Off_Player = {{76, 14}, {14, 14}},
    .Automatic_On_Player = {{90, 14}, {14, 14}},
    .Border_TL = {{104, 14}, {6, 6}},
    .Border_BL = {{110, 14}, {6, 6}},
    .Border_BR = {{116, 14}, {6, 6}},
    .Border_TR = {{122, 14}, {6, 6}},
    .Border_L = {{0, 28}, {6, 2}},
    .Border_R = {{6, 28}, {6, 2}},
    .Border_T = {{12, 28}, {2, 6}},
    .Border_B = {{14, 28}, {2, 6}},
    .Title    = {{16, 28}, {87, 26}},
    .Win_Player = {{0, 54}, {60, 35}},
    .Win_Enemy = {{60, 54}, {60, 35}},
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

