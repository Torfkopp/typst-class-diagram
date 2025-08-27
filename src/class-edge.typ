#import "fletcher/src/utils.typ": *
#import "fletcher/src/marks.typ": *
#import "fletcher/src/coords.typ": default-ctx, find-farthest-intersection, resolve, vector-polar-with-xy-or-uv-length
#import "fletcher/src/edge.typ": interpret-edge-args, interpret-marks-arg, normalize-label-pos


#let get_arrow(arrow, direction, mark-size) = {
  let dash = if arrow in ("Realisation", "Dependency", "R", "D") { "dashed" } else { "solid" }

  let arrow-mark = (
    size: mark-size,
  )

  if arrow in ("Composition", "C") {
    arrow-mark.inherit = "<>"
    arrow-mark.fill = black
  } else if arrow in ("Aggregation", "AG") {
    arrow-mark.inherit = "<>"
  } else if arrow in ("Inheritance", "Realisation", "I", "R") {
    arrow-mark.inherit = "latex"
    arrow-mark.fill = rgb(0,0,0,0)
    arrow-mark.stroke = black
    arrow-mark.size = 50
  } else if arrow in ("NavigableAssociation", "Dependency", "NA", "D") {
    arrow-mark.inherit = "straight"
  } else {
    arrow-mark.inherit = "|"
  }

  let arrow = if direction == right { (none, arrow-mark) } else if direction == left { (arrow-mark, none) } else {
    (arrow-mark, arrow-mark)
  }

  return (arrow, dash)
}

/// A dictionary defining default values for edge labels.
/// The label arguments of fletcher's edges.
/// - text (str): The label text.
/// - side (auto, str): The side of the edge to place the label
/// - pos (percent): The position along the edge
/// - sep (auto, length): The distance from the edge
/// - angle (auto, angle): The rotation angle of the label
/// - anchor (auto, str): The anchor point of the label
/// - fill (auto, colour): The background colour of the label
/// - size (auto, length): The font size of the label
/// - wrapper (auto, func): A wrapper function
///
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

/// Draw a connecting edge in a UML diagram.
/// 
/// --------------------------------------------
/// 
/// `Label-dict`:\
/// A dictionary defining default values for edge labels.
/// Practically the label arguments of fletcher's edges\
/// -text (str): The label text\
/// -side (auto, str): The side of the edge to place the label\
/// -pos (percent): The position along the edge\
/// -sep (auto, length): The distance from the edge\
/// -angle (auto, angle): The rotation angle of the label\
/// -anchor (auto, str): The anchor point of the label\ 
/// -fill (auto, colour): The background colour of the label\
/// -size (auto, length): The font size of the label\
/// -wrapper (auto, func): A wrapper function\
/// --------------------------------------------
/// 
/// - arrow (str): The type of UML edge, one of "Association" (short: "A"), "Navigable Association" ("NA"), "Inheritance" ("I"), "Realisation" ("R"), "Dependency" ("D"), "Aggregation" ("AG"), "Composition" ("C"). Determines the arrow heads and line style.
/// 
/// - direction (direction): The direction of the arrow, left or right for single-headed arrows, top, bottom, or others for double-headed arrows.
/// 
/// - label (str, dict): A centered label for the edge. Either a single string or a `label-dict`.
/// 
/// - mult-left (str, dict): A multiplicity label on the left top ide of the edge. Either a single string or a `label-dict`.
/// 
/// - mult-right (str, dict): A multiplicity label on the right top side of the edge. Either a single string or a `label-dict`.
/// 
/// - desc-left (str, dict): A description label on the left bottom side of the edge. Either a single string or a `label-dict`.
/// 
/// - desc-right (str, dict): A description label on the right bottom side of the edge. Either a single string or a `label-dict`.
///
#let class-edge(
  ..args,
  vertices: (),
  arrow: none,
  mark-size: 15,
  direction: top,
  label: none,
  mult-left: none,
  mult-right: none,
  desc-left: none,
  desc-right: none,
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

  if mult-left != none {
    if type(mult-left) == str { mult-left = (text: mult-left) }
    mult-left.insert("side", mult-left.at("side", default: left))
    mult-left.insert("pos", mult-left.at("pos", default: 15%))
    labels.push(fill-label(mult-left))
  }
  if mult-right != none {
    if type(mult-right) == str { mult-right = (text: mult-right) }
    mult-right.insert("side", mult-right.at("side", default: left))
    mult-right.insert("pos", mult-right.at("pos", default: 85%))
    labels.push(fill-label(mult-right))
  }
  if desc-left != none {
    if type(desc-left) == str { desc-left = (text: desc-left) }
    desc-left.insert("side", desc-left.at("side", default: right))
    desc-left.insert("pos", desc-left.at("pos", default: 15%))
    labels.push(fill-label(desc-left))
  }
  if desc-right != none {
    if type(desc-right) == str { desc-right = (text: desc-right) }
    desc-right.insert("side", desc-right.at("side", default: right))
    desc-right.insert("pos", desc-right.at("pos", default: 85%))
    labels.push(fill-label(desc-right))
  }

  for l in (label, mult-left, mult-right, desc-left, desc-right) {
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

