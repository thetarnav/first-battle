// Code from https://lisyarus.github.io/blog/posts/building-a-quadtree.html
package quadtree

import "core:math"

Vec2 :: [2]f32

Node_Id  :: distinct u32

Quadtree :: struct {
    bbox:   Rect,
    root:   Node_Id,
    nodes:  [dynamic]Node,
    points: []Point,
}

Node :: struct {
    children:    [2][2]Node_Id,
    point_begin: int,
    point_end:   int,
}

Rect :: struct {
    pos:  Vec2,
    size: Vec2,
}

Point :: struct {
    pos: Vec2,
    idx: int,
}

init :: proc (qt: ^Quadtree, allocator := context.allocator) {
    qt ^= {}
    qt.nodes  = make([dynamic]Node, allocator=allocator)
    return
}

cleanup :: proc (qt: ^Quadtree) {
    delete(qt.nodes)
    delete(qt.points)
}

middle :: proc (a, b: Vec2) -> Vec2 {
    return (a + b) * 0.5
}

bbox_of :: proc (points: []Vec2) -> (box: Rect) {
    box.pos  = math.F32_MAX
    box.size = math.F32_MIN
    for p in points {
        if p.x < box.pos.x  {box.pos.x  = p.x}
        if p.y < box.pos.y  {box.pos.y  = p.y}
        if p.x > box.size.x {box.size.x = p.x}
        if p.y > box.size.y {box.size.y = p.y}
    }
    box.size -= box.pos
    return
}

MAX_DEPTH :: 64

build :: proc (points: []Vec2, allocator := context.allocator) -> (qt: Quadtree) {
    init(&qt, allocator)
    qt.bbox = bbox_of(points)
    qt.points = make([]Point, len(points), allocator=allocator)
    for &p, i in qt.points {
        p.pos = points[i]
        p.idx = i
    }
    center := middle(qt.bbox.pos, qt.bbox.pos + qt.bbox.size)
    qt.root = build_impl(&qt, qt.bbox, 0, len(points), center, 0)
    return qt
}

build_impl :: proc (qt: ^Quadtree, bbox: Rect, begin_idx, end_idx: int, center: Vec2, depth: int) -> Node_Id {

    count := end_idx - begin_idx
    if count <= 0 {
        return {} // empty
    }

    node, node_id := node_add(qt)
    node.point_begin = begin_idx
    node.point_end   = end_idx

    if count == 1 || depth >= MAX_DEPTH {
        return node_id // leaf node
    }

    split_y       := partition(qt.points[:], begin_idx, end_idx, center.y, true)
    split_x_lower := partition(qt.points[:], begin_idx, split_y, center.x, false)
    split_x_upper := partition(qt.points[:], split_y, end_idx, center.x, false)

    half := bbox.size * 0.5
    pos := bbox.pos

    nw_bbox: Rect = {pos + Vec2{0, half.y}, half}
    ne_bbox: Rect = {pos + half, half}
    sw_bbox: Rect = {pos, half}
    se_bbox: Rect = {pos + Vec2{half.x, 0}, half}

    node.children.x.x = build_impl(qt, sw_bbox, begin_idx, split_x_lower, middle(sw_bbox.pos, sw_bbox.pos + sw_bbox.size), depth + 1)
    node.children.x.y = build_impl(qt, se_bbox, split_x_lower, split_y,   middle(se_bbox.pos, se_bbox.pos + se_bbox.size), depth + 1)
    node.children.y.x = build_impl(qt, nw_bbox, split_y, split_x_upper,   middle(nw_bbox.pos, nw_bbox.pos + nw_bbox.size), depth + 1)
    node.children.y.y = build_impl(qt, ne_bbox, split_x_upper, end_idx,   middle(ne_bbox.pos, ne_bbox.pos + ne_bbox.size), depth + 1)

    return node_id
}

partition :: proc (points: []Point, begin, end: int, threshold: f32, by_y: bool) -> int {
    i := begin
    for j in begin..<end {
        val := by_y ? points[j].pos.y : points[j].pos.x
        if val < threshold {
            points[i], points[j] = points[j], points[i]
            i += 1
        }
    }
    return i
}

node_get :: proc (qt: Quadtree, node_id: Node_Id) -> (n: ^Node, ok: bool) {
    idx := int(node_id-1)
    if idx < 0 || idx >= len(qt.nodes) do return
    return &qt.nodes[idx], true
}
node_add :: proc (qt: ^Quadtree) -> (n: ^Node, id: Node_Id) {
    append_nothing(&qt.nodes)
    id = Node_Id(len(qt.nodes))
    n, _ = node_get(qt^, id)
    return
}

node_points :: proc (qt: Quadtree, n: ^Node) -> []Point {
    return qt.points[n.point_begin:n.point_end]
}

contains :: proc (rect: Rect, point: Vec2) -> bool {
    return point.x >= rect.pos.x &&
           point.x <= rect.pos.x + rect.size.x &&
           point.y >= rect.pos.y &&
           point.y <= rect.pos.y + rect.size.y
}

intersects :: proc (rect: Rect, range: Rect) -> bool {
    return !(range.pos.x > rect.pos.x + rect.size.x  ||
             range.pos.x + range.size.x < rect.pos.x ||
             range.pos.y > rect.pos.y + rect.size.y  ||
             range.pos.y + range.size.y < rect.pos.y)
}

query :: proc (qt: Quadtree, node_id: Node_Id, bbox: Rect, range: Rect, found: ^[dynamic]Point) {

    n, ok := node_get(qt, node_id)
    if !ok do return

    if !intersects(bbox, range) do return

    for p in node_points(qt, n) {
        if contains(range, p.pos) {
            append(found, p)
        }
    }

    half  := bbox.size * 0.5
    pos   := bbox.pos

    nw_bbox: Rect = {pos + Vec2{0, half.y}, half}
    ne_bbox: Rect = {pos + half, half}
    sw_bbox: Rect = {pos, half}
    se_bbox: Rect = {pos + Vec2{half.x, 0}, half}

    query(qt, n.children.x.x, sw_bbox, range, found)
    query(qt, n.children.x.y, se_bbox, range, found)
    query(qt, n.children.y.x, nw_bbox, range, found)
    query(qt, n.children.y.y, ne_bbox, range, found)
}

query_radius :: proc (qt: Quadtree, node_id: Node_Id, bbox: Rect, center: Vec2, radius: f32, found: ^[dynamic]Point) {
    range := Rect{center - radius, radius * 2}
    query(qt, node_id, bbox, range, found)
}

distance_sq :: proc (a, b: Vec2) -> f32 {
    dx := a.x - b.x
    dy := a.y - b.y
    return dx*dx + dy*dy
}

query_nearest :: proc (qt: Quadtree, target: Vec2) -> (best: Point, found: bool) {
    best_dist: f32 = math.F32_MAX
    _query_nearest(qt, qt.root, qt.bbox, target, &best, &best_dist, &found)
    return
}

_query_nearest :: proc (qt: Quadtree, node_id: Node_Id, bbox: Rect, target: Vec2, best: ^Point, best_dist: ^f32, found: ^bool) {

    n, ok := node_get(qt, node_id)
    if !ok do return

    for p in node_points(qt, n) {
        d := distance_sq(p.pos, target)
        if d < best_dist^ {
            best^      = p
            best_dist^ = d
            found^     = true
        }
    }

    half := bbox.size * 0.5
    pos  := bbox.pos

    nw_bbox: Rect = {pos + Vec2{0, half.y}, half}
    ne_bbox: Rect = {pos + half, half}
    sw_bbox: Rect = {pos, half}
    se_bbox: Rect = {pos + Vec2{half.x, 0}, half}

    _query_nearest(qt, n.children.x.x, sw_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.children.x.y, se_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.children.y.x, nw_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.children.y.y, ne_bbox, target, best, best_dist, found)
}
