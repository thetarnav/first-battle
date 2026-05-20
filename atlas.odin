package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
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
    .Heavy_Enemy = {{0, 0}, {7, 7}},
    .Rider_Enemy = {{7, 0}, {7, 10}},
    .Infantry_Player = {{14, 0}, {7, 7}},
    .Archer_Player = {{21, 0}, {7, 7}},
    .Infantry_Enemy = {{28, 0}, {7, 7}},
    .Archer_Enemy = {{35, 0}, {7, 7}},
    .Rider_Player = {{42, 0}, {7, 10}},
    .Heavy_Player = {{49, 0}, {7, 7}},
}
