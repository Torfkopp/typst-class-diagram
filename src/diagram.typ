#import "draw.typ": draw-diagram
#import "fletcher/src/diagram.typ": interpret-diagram-args, resolve-node-options, measure-node-size, resolve-edge-options, resolve-node-coordinates, resolve-edge-vertices, compute-grid, resolve-node-enclosures, resolve-edges
#import "class-edge.typ": *

/// Draw a diagram containing `node()`s and `edge()`s.
///
/// - ..args (array): Content to draw in the diagram, including nodes and edges.
///
///   The results of `node()` and `edge()` can be _joined_, meaning you can
///   specify them as separate arguments, or in a block:
///
///   ```typ
///   #diagram(
///   	// one object per argument
///   	node((0, 0), $A$),
///   	node((1, 0), $B$),
///   	{
///   		// multiple objects in a block
///   		// can use scripting, loops, etc
///   		node((2, 0), $C$)
///   		node((3, 0), $D$)
///   	},
///   	for x in range(4) { node((x, 1), [#x]) },
///   )
///   ```
///
///   Nodes and edges can also be specified in math-mode.
///
///   ```typ
///   #diagram($
///   	A & B \          // two nodes at (0,0) and (1,0)
///   	C edge(->) & D \ // an edge from (0,1) to (1,1)
///   	node(sqrt(pi), stroke: #1pt) // a node with options
///   $)
///   ```
///
/// - debug (bool, 1, 2, 3): Level of detail for drawing debug information.
///   Level `1` or `true` shows a coordinate grid; higher levels show bounding boxes and
///   anchors, etc.
///
/// - spacing (length, pair of lengths): Gaps between rows and columns. Ensures
///   that nodes at adjacent grid points are at least this far apart (measured as
///   the space between their bounding boxes).
///
///   Separate horizontal/vertical gutters can be specified with `(x, y)`. A
///   single length `d` is short for `(d, d)`.
///
/// - cell-size (length, pair of lengths): Minimum size of all rows and columns.
///   A single length `d` is short for `(d, d)`.
///
/// - node-inset (length, pair of lengths): Default value of
///   #the-param[node][inset].
///
/// - node-outset (length, pair of lengths): Default value of
///   #the-param[node][outset].
///
/// - node-shape (rect, circle, function): Default value of
///   #the-param[node][shape].
///
/// - node-stroke (stroke, none): Default value of #the-param[node][stroke].
///
///   The default stroke is folded with the stroke specified for the node. For
///   example, if `node-stroke` is `1pt` and #the-param[node][stroke] is `red`,
///   then the resulting stroke is `1pt + red`.
///
/// - node-fill (paint): Default value of #the-param[node][fill].
///
/// - edge-stroke (stroke): Default value of #the-param[edge][stroke]. By
///   default, this is chosen to match the thickness of mathematical arrows such
///   as $A -> B$ in the current font size.
///
///   The default stroke is folded with the stroke specified for the edge. For
///   example, if `edge-stroke` is `1pt` and #the-param[edge][stroke] is `red`,
///   then the resulting stroke is `1pt + red`.
///
/// - node-corner-radius (length, none): Default value of
///   #the-param[node][corner-radius].
///
/// - edge-corner-radius (length, none): Default value of
///   #the-param[edge][corner-radius].
///
/// - node-defocus (number): Default value of #the-param[node][defocus].
///
/// - label-sep (length): Default value of #the-param[edge][label-sep].
///
/// - label-size (length): Default value of #the-param[edge][label-size].
///
/// - label-wrapper (function): Default value of
///   #the-param[edge][label-wrapper].
///
/// - mark-scale (percent): Default value of #the-param[edge][mark-scale].
///
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///   the illusion of crossing over other objects. See
///   #the-param[edge][crossing-fill].
///
/// - crossing-thickness (number): Default thickness of the occlusion made by
///   crossing connectors. See #param[edge][crossing-thickness].
///
/// - axes (pair of directions): The orientation of the diagram's axes.
///
///   This defines the elastic coordinate system used by nodes and edges. To make
///   the $y$ coordinate increase up the page, use `(ltr, btt)`. For the matrix
///   convention `(row, column)`, use `(ttb, ltr)`.
///
///   #stack(
///   	dir: ltr,
///   	spacing: 1fr,
///   	fletcher.diagram(
///   		axes: (ltr, ttb),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->"),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ltr, ttb)`),
///   	),
///   	fletcher.diagram(
///   		axes: (ltr, btt),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->"),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ltr, btt)`),
///   	),
///   	fletcher.diagram(
///   		axes: (ttb, ltr),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->", bend: -20deg),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ttb, ltr)`),
///   	),
///   )
///
/// - render (function): After the node sizes and grid layout have been
///   determined, the `render` function is called with the following arguments:
///   - `grid`: a dictionary of the row and column widths and positions;
///   - `nodes`: an array of nodes (dictionaries) with computed attributes
///    (including size and physical coordinates);
///   - `edges`: an array of connectors (dictionaries) in the diagram; and
///   - `options`: other diagram attributes.
///
///   This callback is exposed so you can access the above data and draw things
///   directly with CeTZ.
#let diagram(
	..args,
	debug: false,
	axes: (ltr, ttb),
	spacing: 3em,
	cell-size: 0pt,
	edge-stroke: 0.048em,
	node-stroke: none,
	edge-corner-radius: 2.5pt,
	node-corner-radius: none,
	node-inset: 6pt,
	node-outset: 0pt,
	node-shape: auto,
	node-fill: none,
	node-defocus: 0.2,
	label-sep: 0.4em,
	label-size: 1em,
	label-wrapper: edge => box(
		[#edge.label],
		inset: .2em,
		radius: .2em,
		fill: edge.label-fill,
	),
	mark-scale: 100%,
	crossing-fill: white,
	crossing-thickness: 5,
	render: (grid, nodes, edges, options) => {
		cetz.canvas(draw-diagram(grid, nodes, edges, debug: options.debug))
	},
) = {

	let spacing = as-pair(spacing).map(as-length)
	let cell-size = as-pair(cell-size).map(as-length)

	let options = (
		debug: int(debug),
		axes: axes,
		spacing: spacing,
		cell-size: cell-size,
		node-inset: node-inset,
		node-outset: node-outset,
		node-shape: node-shape,
		node-stroke: node-stroke,
		node-fill: node-fill,
		node-corner-radius: node-corner-radius,
		edge-corner-radius: edge-corner-radius,
		node-defocus: node-defocus,
		label-sep: label-sep,
		label-size: label-size,
		label-wrapper: label-wrapper,
		edge-stroke: as-stroke(edge-stroke),
		mark-scale: mark-scale,
		crossing-fill: crossing-fill,
		crossing-thickness: crossing-thickness,
	)

	let (nodes, edges) = interpret-diagram-args(args)

	box(context {
		let options = options

		options.em-size = 1em.to-absolute()
		options.spacing = options.spacing.map(length.to-absolute)
		options.cell-size = options.cell-size.map(length.to-absolute)

		let nodes = nodes.map(node => {
			node = resolve-node-options(node, options)
			node = measure-node-size(node)
			node
		})
		let edges = edges.map(
			edge => if edge.at("labels", default: none) == none { 
				resolve-edge-options(edge, options) } 
				else { resolve-class-edge-options(edge, options) }
		)
		// let edges = edges.map(edge => resolve-class-edge-options(edge, options))

		// PHASE 1: Resolve uv coordinates where possible


		let dummy-edge-anchors = edges
			.filter(edge => edge.name != none)
			.map(edge => (str(edge.name), (anchors: k => NAN_COORD)))
			.to-dict()


		let ctx = default-ctx + (target-system: "uv") + (nodes: dummy-edge-anchors)

		// try resolving node uv coordinates. this resolves to NaN coords if the
		// resolution fails (e.g., if the coords depend on physical lengths)
		let (ctx, nodes) = resolve-node-coordinates(
			nodes, ctx: ctx)


		// nodes and edges whose uv coordinates can be resolved without knowing the grid
		let rects-affecting-grid = nodes
			.filter(node => not is-nan-vector(node.pos.uv))
			.map(node => (center: node.pos.uv, size: node.size))

		let vertices-affecting-grid = (edges
			.map(edge => resolve-edge-vertices(ctx, edge, nodes))
			.join() + ()) // coerce none to ()
			.filter(vert => not is-nan-vector(vert))


		// PHASE 2: Determine elastic grid (row/column sizes) and resolve xy coordinates

		// determine diagram's elastic grid layout
		let grid = compute-grid(rects-affecting-grid, vertices-affecting-grid, options)

		let dummy-edge-anchors = edges
			.filter(edge => edge.name != none)
			.map(edge => (str(edge.name), (anchors: k => (0pt, 0pt))))
			.to-dict()


		let ctx = default-ctx + (target-system: "xyz", grid: grid) + (nodes: dummy-edge-anchors)

		// PHASE 3: With the grid defined, fully resolve xy coordinates for all nodes and edges

		// we run multiple passes so that anchors on enclose nodes
		// have a chance to resolve
		// (a better way would be to resolve coordinates and enclose nodes together)
		for i in range(5) {
			ctx.prev.pt = (0, 0)

			// now with grid determined, compute final (physical) coordinates for nodes and edges
			(ctx, nodes) = resolve-node-coordinates(nodes, ctx: ctx)

			// resolve enclosing nodes
			nodes = resolve-node-enclosures(nodes, ctx)

			(ctx, edges) = resolve-edges(grid, edges, nodes, ctx)
		}

		render(grid, nodes, edges, options)
	})
}
