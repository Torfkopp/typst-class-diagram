#import "fletcher/src/node.typ": node
#import "fletcher/src/deps.typ": cetz
#import cetz: draw, vector

#let class-node-draw(
  node,
  extrude,
  background: white,
  colour: white,
  stroke: black,
  radius: 0.0,
  title-colour: black,
  attributes: (),
  methods: (),
) = {
  let INLINE_SIDE = 3pt
  let INLINE_TOP = text.size / 2
  let (w, h) = node.size
  let title = node.label.child

  //width of longest word
  let width = 0pt
  for l in ((title,) + attributes + methods) {
    let line_width = measure(l).width
    if line_width > width { width = line_width - w }
  }

  // height based on the number of items
  let line-space = par.leading
  let attribute_height = INLINE_TOP * 2
  for l in attributes { attribute_height += measure(l).height + line-space }

  let method_height = INLINE_TOP * 2
  for l in methods { method_height += measure(l).height + line-space }

  let n_h = -h + 10pt
  let a_h = n_h - attribute_height

  if extrude != none {
    draw.rect(
      (-w - extrude, n_h - attribute_height - method_height - extrude),
      (w + width + extrude, h + extrude),
      name: "outer",
      fill: background,
    )
  }

  draw.rect((-w, n_h - attribute_height - method_height), (w + width, h), name: "outer", stroke: rgb(0, 0, 0, 0))
  draw.rect((-w, n_h), (w + width, h), name: "name", stroke: stroke, fill: colour, radius: (north: radius))
  draw.rect((-w, a_h), (w + width, n_h), name: "attributes", stroke: stroke, fill: background)
  draw.rect(
    (-w, a_h - method_height),
    (w + width, a_h),
    name: "methods",
    stroke: stroke,
    radius: (south: radius),
    fill: background,
  )


  draw.content("name", text(fill: title-colour, weight: "bold", title))

  // Attributes
  let mid_attr = n_h - (attribute_height / 2)
  draw.content((-w + INLINE_SIDE, mid_attr), anchor: "mid-west", [
    #for attr in attributes {
      attr
      linebreak()
    }
  ])

  // Methods
  let mid_methods = a_h - (method_height / 2)
  draw.content((-w + INLINE_SIDE, mid_methods), anchor: "mid-west", [
    #for m in methods {
      m
      linebreak()
    }
  ])
}

#let class-node(
  ..args,
  pos: auto,
  extrude: (0,),
  label: none,
  background: none,
  colour: white,
  title-colour: black,
  stroke: black,
  radius: 0.0,
  attributes: (),
  methods: (),
) = {
  node(
    ..args,
    pos: pos,
    extrude: extrude,
    [#text(fill: rgb(0, 0, 0, 0))[#label]],
    shape: class-node-draw.with(
      background: background,
      colour: colour,
      title-colour: title-colour,
      stroke: stroke,
      radius: radius,
      attributes: attributes,
      methods: methods,
    ),
  )
}
