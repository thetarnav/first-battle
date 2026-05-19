package first_battle

ATLAS_TEXTURE :: "atlas.png"

Atlas_Slice :: enum u8 {
    Heavy,
    Rider,
    Archer,
    Base,
}

atlas_rects: [Atlas_Slice]Rect = {
    .Heavy    = {{0, 0}, {7, 7}},
    .Rider    = {{7, 0}, {7, 10}},
    .Archer   = {{14, 0}, {7, 7}},
    .Base     = {{21, 0}, {7, 7}},
}
