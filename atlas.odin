package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Dust_Cloud,
    Win_Enemy,
    Win_Player,
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
    Sound_On,
    Sound_Off,
    Reset,
}

atlas_rects: [Atlas_Slice]Rect = {
    .Dust_Cloud = {{0, 0}, {7, 7}},
    .Win_Enemy = {{7, 0}, {60, 35}},
    .Win_Player = {{67, 0}, {60, 35}},
    .Title    = {{0, 35}, {87, 26}},
    .Border_B = {{87, 35}, {2, 6}},
    .Border_T = {{89, 35}, {2, 6}},
    .Border_R = {{91, 35}, {6, 2}},
    .Border_L = {{97, 35}, {6, 2}},
    .Border_TR = {{103, 35}, {6, 6}},
    .Border_BR = {{109, 35}, {6, 6}},
    .Border_BL = {{115, 35}, {6, 6}},
    .Border_TL = {{121, 35}, {6, 6}},
    .Automatic_On_Player = {{0, 61}, {14, 14}},
    .Automatic_Off_Player = {{14, 61}, {14, 14}},
    .Heavy_Player = {{28, 61}, {7, 7}},
    .Rider_Player = {{35, 61}, {7, 10}},
    .Archer_Enemy = {{42, 61}, {7, 7}},
    .Infantry_Enemy = {{49, 61}, {7, 7}},
    .Archer_Player = {{56, 61}, {7, 7}},
    .Infantry_Player = {{63, 61}, {7, 7}},
    .Rider_Enemy = {{70, 61}, {7, 10}},
    .Heavy_Enemy = {{77, 61}, {7, 7}},
    .Corpse_1 = {{84, 61}, {7, 7}},
    .Corpse_2 = {{91, 61}, {7, 7}},
    .Corpse_3 = {{98, 61}, {6, 9}},
    .Play     = {{0, 75}, {30, 12}},
    .Automatic_Off_Enemy = {{30, 75}, {14, 14}},
    .Automatic_On_Enemy = {{44, 75}, {14, 14}},
    .Sound_On = {{58, 75}, {15, 14}},
    .Sound_Off = {{73, 75}, {15, 14}},
    .Reset    = {{88, 75}, {36, 12}},
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

