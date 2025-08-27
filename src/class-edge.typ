#import "fletcher/src/utils.typ": *
#import "fletcher/src/marks.typ": *
#import "fletcher/src/coords.typ": default-ctx, find-farthest-intersection, resolve, vector-polar-with-xy-or-uv-length
#import "fletcher/src/edge.typ": interpret-edge-args, interpret-marks-arg, normalize-label-pos

#let ALIASES = (
  "Association": ("", "-", ""),
  "Navigable Association": ("<", "-", ">"),
  "Inheritance": ("<|", "-", "|>"),
  "Realisation": ("<|", "--", "|>"),
  "Dependency": ("<", "--", ">"),
  "Aggregation": ("<>", "-", "<>"),
  "Composition": ("<>", "-", "<>"),
)

#let get_arrow(arrow, direction, mark-size) = {
  let dash = if arrow == "Realisation" or arrow == "Dependency" { "dashed" } else { "solid" }

  let arrow-mark = (
    size: mark-size,
  )

  if arrow == "Composition" {
    arrow-mark.inherit = "<>"
    arrow-mark.fill = black
  } else if arrow == "Aggregation" {
    arrow-mark.inherit = "<>"
  } else if arrow == "Inheritance" or arrow == "Realisation" {
    arrow-mark.inherit = "solid"
  } else if arrow == "Navigable Association" or arrow == "Dependency" {
    arrow-mark.inherit = "straight"
  }

  let arrow = if direction == right { (none, arrow-mark) } else if direction == left { (arrow-mark, none) } else {
    (arrow-mark, arrow-mark)
  }

  return (arrow, dash)
}

#let label-dict = (
  text: "text",
  side: auto,
  pos: 50%,
  sep: auto,
  angle: auto,
  anchor: auto,
  fill: auto,
  size: auto,
  wrapper: auto,
)

#let fill-label(dict) = {
  let new-dict = (:)
  for (key, default) in label-dict {
    new-dict.insert(key, dict.at(key, default: default))
  }
  new-dict
}


#let class-edge(
  ..args,
  vertices: (),
  arrow: none,
  mark-size: 15,
  direction: top,
  label: none,
  mult_left: none,
  mult_right: none,
  desc_left: none,
  desc_right: none,
  stroke: auto,
  dash: auto,
  decorations: none,
  extrude: (0,),
  shift: 0pt,
  kind: auto,
  bend: 0deg,
  loop-angle: none,
  corner: none,
  corner-radius: auto,
  marks: (),
  mark-scale: 100%,
  crossing: false,
  crossing-thickness: auto,
  crossing-fill: auto,
  snap-to: (auto, auto),
  name: none,
  layer: 0,
  floating: false,
  post: x => x,
) = {
  let labels = ()

  if mult_left != none {
    if type(mult_left) == str { mult_left = (text: mult_left) }
    mult_left.insert("side", mult_left.at("side", default: left))
    mult_left.insert("pos", mult_left.at("pos", default: 15%))
    labels.push(fill-label(mult_left))
  }
  if mult_right != none {
    if type(mult_right) == str { mult_right = (text: mult_right) }
    mult_right.insert("side", mult_right.at("side", default: left))
    mult_right.insert("pos", mult_right.at("pos", default: 85%))
    labels.push(fill-label(mult_right))
  }
  if desc_left != none {
    if type(desc_left) == str { desc_left = (text: desc_left) }
    desc_left.insert("side", desc_left.at("side", default: right))
    desc_left.insert("pos", desc_left.at("pos", default: 15%))
    labels.push(fill-label(desc_left))
  }
  if desc_right != none {
    if type(desc_right) == str { desc_right = (text: desc_right) }
    desc_right.insert("side", desc_right.at("side", default: right))
    desc_right.insert("pos", desc_right.at("pos", default: 85%))
    labels.push(fill-label(desc_right))
  }

  for l in (label, mult_left, mult_right, desc_left, desc_right) {
    if type(l) == str { l = (text: l) }
    if l != none {
      labels.push(fill-label(l))
    }
  }

  if arrow != none and direction != none {
    (marks, dash) = get_arrow(arrow, direction, mark-size)
  }

  let options = (
    vertices: vertices,
    labels: labels,
    stroke: stroke,
    dash: dash,
    decorations: decorations,
    kind: kind,
    bend: bend,
    loop-angle: pass-none(as-angle)(loop-angle),
    corner: corner,
    corner-radius: corner-radius,
    extrude: extrude,
    shift: shift,
    marks: marks,
    mark-scale: mark-scale,
    crossing: crossing,
    crossing-thickness: crossing-thickness,
    crossing-fill: crossing-fill,
    snap-to: as-pair(snap-to),
    name: pass-none(as-label)(name),
    layer: layer,
    post: post,
    floating: as-bool(floating, message: "`floating` must be boolean"),
  )

  options += interpret-edge-args(args, options)

  // relative coordinate shorthands
  let interpret-coord-str(coord) = {
    if type(coord) != str { return coord }
    let rel = (0, 0)
    let dirs = (
      "t": (0, -1),
      "n": (0, -1),
      "u": (0, -1),
      "b": (0, +1),
      "s": (0, +1),
      "d": (0, +1),
      "l": (-1, 0),
      "w": (-1, 0),
      "r": (+1, 0),
      "e": (+1, 0),
    )
    for char in coord.clusters() {
      rel = vector.add(rel, dirs.at(char))
    }
    (rel: rel)
  }
  options.vertices = options.vertices.map(interpret-coord-str)

  // guess the number of segments
  let n-segments = options.vertices.len() - 1
  if options.corner != none { n-segments += 1 }

  // for label in options.labels {
  //   label.pos = normalize-label-pos(label.pos, n-segments)
  // }

  for i in range(options.labels.len()) {
    options.labels.at(i).pos = normalize-label-pos(options.labels.at(i).pos, n-segments)
  }

  if type(options.shift) != array { options.shift = (options.shift, options.shift) }

  let obj = (
    class: "edge",
    ..options,
    is-crossing-background: false,
  )

  // for the crossing effect, add another edge underneath
  if options.crossing {
    metadata((
      ..obj,
      is-crossing-background: true,
    ))
  }

  metadata(obj)
}


#let resolve-class-edge-options(edge, options) = {
  edge += interpret-marks-arg(edge.marks)

  if edge.stroke == none {
    // hack: for no stroke, it's easier to do the following.
    // then we have the guarantee that edge.stroke is actually
    // a stroke, not possibly none
    edge.extrude = ()
    edge.marks = ()
    edge.stroke = stroke((:))
  }

  edge.stroke = (
    (
      cap: "round",
      dash: edge.dash,
      thickness: 0.048em, // guarantees thickness is a length, not auto
    )
      + stroke-to-dict(options.edge-stroke)
      + stroke-to-dict(map-auto(edge.stroke, (:)))
  )
  edge.stroke.thickness = edge.stroke.thickness.to-absolute()

  edge.extrude = as-array(edge.extrude)
    .map(
      as-number-or-length.with(
        message: "`extrude` must be a number, length, or an array of those",
      ),
    )
    .map(d => {
      if type(d) == length { d.to-absolute() } else { d * edge.stroke.thickness }
    })

  if type(edge.decorations) == str {
    edge.decorations = (
      "wave": cetz.decorations.wave.with(
        amplitude: .12,
        segment-length: .2,
      ),
      "zigzag": cetz.decorations.zigzag.with(
        amplitude: .12,
        segment-length: .2,
      ),
      "coil": cetz.decorations.coil.with(
        amplitude: .15,
        segment-length: .15,
        factor: 140%,
      ),
    ).at(edge.decorations)
  }

  edge.crossing-fill = map-auto(edge.crossing-fill, options.crossing-fill)
  edge.crossing-thickness = map-auto(edge.crossing-thickness, options.crossing-thickness)
  edge.corner-radius = map-auto(edge.corner-radius, options.edge-corner-radius)

  if edge.is-crossing-background {
    edge.stroke = (
      thickness: edge.crossing-thickness * edge.stroke.thickness,
      paint: edge.crossing-fill,
      cap: "round",
    )
    edge.marks = ()
    edge.extrude = edge.extrude.map(e => e / edge.crossing-thickness)
  }

  edge.stroke = as-stroke(edge.stroke)

  if edge.kind == auto {
    if edge.vertices.len() > 2 { edge.kind = "poly" } else if edge.corner != none { edge.kind = "corner" } else if (
      edge.bend != 0deg
    ) { edge.kind = "arc" } else { edge.kind = "line" }
  }

  // Scale marks
  edge.mark-scale *= options.mark-scale
  edge.marks = edge.marks.map(mark => {
    mark.scale *= edge.mark-scale
    mark
  })

  for i in range(edge.labels.len()) {
    edge.labels.at(i).sep = map-auto(edge.labels.at(i).sep, options.label-sep).to-absolute()
    edge.labels.at(i).size = map-auto(edge.labels.at(i).size, options.label-size)

    edge.labels.at(i).fill = map-auto(edge.labels.at(i).fill, edge.labels.at(i).side == center)
    if edge.labels.at(i).fill == true { edge.labels.at(i).fill = edge.crossing-fill }
    if edge.labels.at(i).fill == false { edge.labels.at(i).fill = none }

    edge.labels.at(i).wrapper = map-auto(edge.labels.at(i).wrapper, options.label-wrapper)
  }


  if edge.floating {
    edge.post = x => cetz.draw.floating((edge.post)(x))
  }

  edge
}

