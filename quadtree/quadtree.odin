// Code from https://lisyarus.github.io/blog/posts/building-a-quadtree.html
package quadtree

import "core:math"

Vec2 :: [2]f32

Node_Id  :: distinct u32
NIL_NODE :: Node_Id(0xFFFFFFFF)

Quadtree :: struct {
    bbox:         Rect,
    root:         Node_Id,
    nodes:        [dynamic]Node,
    points:       []Point,
    point_ranges: [dynamic]u32,
}

Node :: [2][2]Node_Id

Rect :: struct {
    pos:  Vec2,
    size: Vec2,
}

Point :: struct {
    pos: Vec2,
    idx: int,
}

init :: proc (qt: ^Quadtree, allocator := context.allocator) {
    qt.nodes        = make([dynamic]Node, allocator=allocator)
    qt.points       = {}
    qt.point_ranges = make([dynamic]u32,  allocator=allocator)
    qt.root         = NIL_NODE
    return
}

cleanup :: proc (qt: ^Quadtree) {
    delete(qt.nodes)
    delete(qt.points)
    delete(qt.point_ranges)
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

build :: proc (points: []Vec2, allocator := context.allocator) -> (qt: Quadtree) {
    init(&qt, allocator)
    qt.bbox = bbox_of(points)
    qt.points = make([]Point, len(points), allocator=allocator)
    for &p, i in qt.points {
        p.pos = points[i]
        p.idx = i
    }
    center := middle(qt.bbox.pos, qt.bbox.pos + qt.bbox.size)
    qt.root = build_impl(&qt, qt.bbox, 0, len(points), center)
    append(&qt.point_ranges, u32(len(points)))
    return qt
}

build_impl :: proc (qt: ^Quadtree, bbox: Rect, begin_idx, end_idx: int, center: Vec2) -> Node_Id {
    count := end_idx - begin_idx
    if count <= 0 {
        return NIL_NODE
    }

    node_id := Node_Id(len(qt.nodes))
    append(&qt.nodes, Node{NIL_NODE, NIL_NODE})
    append(&qt.point_ranges, u32(begin_idx))

    if count <= 1 {
        return node_id
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

    qt.nodes[node_id].x.x = build_impl(qt, sw_bbox, begin_idx, split_x_lower, middle(sw_bbox.pos, sw_bbox.pos + sw_bbox.size))
    qt.nodes[node_id].x.y = build_impl(qt, se_bbox, split_x_lower, split_y,   middle(se_bbox.pos, se_bbox.pos + se_bbox.size))
    qt.nodes[node_id].y.x = build_impl(qt, nw_bbox, split_y, split_x_upper,   middle(nw_bbox.pos, nw_bbox.pos + nw_bbox.size))
    qt.nodes[node_id].y.y = build_impl(qt, ne_bbox, split_x_upper, end_idx,   middle(ne_bbox.pos, ne_bbox.pos + ne_bbox.size))

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

node_points :: proc (qt: Quadtree, node_id: Node_Id) -> []Point {
    if node_id == NIL_NODE || node_id >= Node_Id(len(qt.nodes)) {
        return nil
    }
    begin := qt.point_ranges[node_id]
    end   := qt.point_ranges[node_id+1]
    return qt.points[begin:end]
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

    if node_id == NIL_NODE || !intersects(bbox, range) {
        return
    }

    for p in node_points(qt, node_id) {
        if contains(range, p.pos) {
            append(found, p)
        }
    }

    n    := &qt.nodes[node_id]
    half := bbox.size * 0.5
    pos  := bbox.pos

    nw_bbox: Rect = {pos + Vec2{0, half.y}, half}
    ne_bbox: Rect = {pos + half, half}
    sw_bbox: Rect = {pos, half}
    se_bbox: Rect = {pos + Vec2{half.x, 0}, half}

    query(qt, n.x.x, sw_bbox, range, found)
    query(qt, n.x.y, se_bbox, range, found)
    query(qt, n.y.x, nw_bbox, range, found)
    query(qt, n.y.y, ne_bbox, range, found)
}

query_radius :: proc (qt: Quadtree, node_id: Node_Id, bbox: Rect, center: Vec2, radius: f32, found: ^[dynamic]Point) {
    range := Rect{center-radius, radius*2}
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
    if node_id == NIL_NODE {
        return
    }

    for p in node_points(qt, node_id) {
        d := distance_sq(p.pos, target)
        if d < best_dist^ {
            best^ = p
            best_dist^ = d
            found^ = true
        }
    }

    n := &qt.nodes[node_id]
    half := bbox.size * 0.5
    pos  := bbox.pos

    nw_bbox: Rect = {pos + Vec2{0, half.y}, half}
    ne_bbox: Rect = {pos + half, half}
    sw_bbox: Rect = {pos, half}
    se_bbox: Rect = {pos + Vec2{half.x, 0}, half}

    _query_nearest(qt, n.x.x, sw_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.x.y, se_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.y.x, nw_bbox, target, best, best_dist, found)
    _query_nearest(qt, n.y.y, ne_bbox, target, best, best_dist, found)
}
