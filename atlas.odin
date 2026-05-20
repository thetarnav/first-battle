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
}
