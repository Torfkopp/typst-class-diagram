#import "utils.typ": *
#import "marks.typ": *
#import "coords.typ": uv-to-xy, default-ctx, find-farthest-intersection
#import "edge.typ": find-nodes-for-edge, parametrised-edge

#let DEBUG_COLOR = rgb("f008")
#let DEBUG_COLOR2 = rgb("0f08")

#let draw-debug(objs) = {
	cetz.draw.floating(objs)
}

// Get the arrow head adjustment for a given extrusion distance.
//
// Returns a pair `(from, to)` of distances.
// If `from < 0pt` and `to > 0pt`, the path length of the edge increases.
#let cap-offsets(edge, y) = {
	(0, 1).map(pos => {
		let mark = edge.marks.find(mark => calc.abs(mark.pos - pos) < 1e-3)
		if mark == none { return 0pt }

		let is-tip = (pos == 0) == mark.rev
		let sign = if mark.rev { -1 } else { +1 }

		let x = cap-offset(
			mark + (tip: is-tip),
			sign*y/edge.stroke.thickness,
		)

		let origin = if is-tip { mark.tip-origin } else { mark.tail-origin }
		x -= origin*float(mark.scale)

		sign*x*edge.stroke.thickness
	})
}

#let with-decorations(edge, path) = {
	if edge.decorations == none { return path }

	let has-mark-at(t) = edge.marks.find(mark => calc.abs(mark.pos - t) < 1e-3 ) != none

	let decor = edge.decorations.with(stroke: edge.stroke)

	// TODO: should this be an absolute offset, not 10% the path length?
	let ε = 1e-3 // cetz assertions sometimes fail from floating point errors
	decor = decor.with(
		start: if has-mark-at(0) { 0.1 } else { ε } * 100%,
		stop: if has-mark-at(1) { 0.9 } else { 1 - ε } * 100%,
	)

	decor(path)
}

#let place-class-edge-label-on-curve(label, curve, debug: 0) = {
	
	let curve-point = curve(label.pos.position)
	let curve-point-ε = curve(label.pos.position + 1e-3%)

	let θ = wrap-angle-180(angle-between(curve-point, curve-point-ε))
	let θ-normal = θ + if label.side == right { +90deg } else { -90deg }

	if type(label.angle) == alignment {
		label.angle = θ - (
			right: 0deg,
			top: 90deg,
			left: 180deg,
			bottom: 270deg,
		).at(repr(edge.label-angle))

	} else if label.angle == auto {
		label.angle = θ
		if calc.abs(label.angle) > 90deg {
			label.angle += 180deg
		}
	}

	if label.anchor == auto {
		label.anchor = angle-to-anchor(θ-normal - label.angle)
	}

	let label-pos = (to: curve-point, rel: (θ-normal, -label.sep))

	cetz.draw.content(
		label-pos,
		box(
			{
				set text(label.size)
				box(
					label.text,
					inset: .2em,
					radius: .2em,
					fill: label.fill,
				)
			},
			stroke: if debug >= 2 { DEBUG_COLOR2 + 0.25pt },
		),
		angle: label.angle,
		anchor: if label.anchor != auto { label.anchor },
	)

	if debug >= 2 {
		draw-debug(cetz.draw.circle(
			label-pos,
			radius: 0.75pt,
			stroke: none,
			fill: DEBUG_COLOR2,
		))
	}
	
}


#let draw-class-edge-line(edge, debug: 0) = {
	let (from, to) = edge.final-vertices
	let θ = angle-between(from, to)

	// Draw line(s), one for each extrusion shift
	for shift in edge.extrude {

		let offsets = cap-offsets(edge, shift)
		let points = (from, to).zip(offsets)
			.map(((point, offset)) => {
				// Shift line sideways (for multi-stroke effect)
				point = (rel: (θ + 90deg, shift), to: point)
				// Shift end points lengthways depending on marks
				point = (rel: (θ, offset), to: point)
				point
			})

		let obj = cetz.draw.line(
			..points,
			stroke: edge.stroke,
		)

		with-decorations(edge, obj)
	}

	// Draw marks
	let total-path-len = vector-len(vector.sub(from, to))
	let curve(t) = {
		if calc.abs(total-path-len) > 1e-3pt {
			t = relative-to-float(t, len: total-path-len)
			vector.lerp(from, to, t)
		} else { from }
	}
	let curve = parametrised-edge(edge)

	for mark in edge.marks {
		place-mark-on-curve(mark, curve, stroke: edge.stroke, debug: debug >= 3)
	}

	// Draw label
	// This edge only has a single segment, so don't draw the label unless it's 
	// placed on segment 0. This means that when calling this function for the
	// individual segments of an edge (`draw-edge-polyline`), the `segment` field
	// of `label-pos` must be set to 0.
	for i in range(edge.labels.len()) {
		if edge.labels.at(i) != none and edge.labels.at(i).pos.segment == 0 {

			// Choose label anchor based on edge direction,
			// preferring to place labels above the edge
			if edge.labels.at(i).side == auto {
				// edges are often exactly vertical, but tiny floating point errors make θ unstable
				// so choose 89.5deg to avoid flickering
				edge.labels.at(i).side = if calc.abs(θ) < 89.5deg { left } else { right }
			}

			place-class-edge-label-on-curve(edge.labels.at(i), curve, debug: debug)
		}
	}
}

#let draw-class-edge-arc(edge, debug: 0) = {
	let (from, to) = edge.final-vertices

	// Determine the arc from the stroke end points and bend angle
	let (center, radius, start, stop) = get-arc-connecting-points(from, to, edge.bend)

	let bend-dir = if edge.bend > 0deg { +1 } else { -1 }

	// Draw arc(s), one for each extrusion shift
	for shift in edge.extrude {

		// Adjust arc angles to accommodate for cap offsets
		let (δ-start, δ-stop) = cap-offsets(edge, shift)
			.map(arclen => -bend-dir*arclen/radius*1rad)

		let obj = cetz.draw.arc(
			center,
			radius: radius + shift,
			start: start + δ-start,
			stop: stop + δ-stop,
			anchor: "origin",
			stroke: edge.stroke,
		)

		with-decorations(edge, obj)
	}

	// Draw marks
	let total-path-len = calc.abs(stop - start)/1rad*radius
	// let curve(t) = {
	// 	t = relative-to-float(t, len: total-path-len)
	// 	vector.add(center, vector-polar(radius, lerp(start, stop, t)))
	// }
	let curve = parametrised-edge(edge)

	for mark in edge.marks {
		place-mark-on-curve(mark, curve, stroke: edge.stroke, debug: debug >= 3)
	}

	// Draw label
	for i in range(edge.labels.len()) {
		if edge.labels.at(i) != none and edge.labels.at(i).pos.segment == 0 {

			// Choose label anchor based on edge direction,
			// preferring to place labels above the edge
			if edge.labels.at(i).side == auto {
				// edges are often exactly vertical, but tiny floating point errors make θ unstable
				// so choose 89.5deg to avoid flickering
				edge.labels.at(i).side = if edge.bend > 0deg { left } else { right }
			}

			place-class-edge-label-on-curve(edge.labels.at(i), curve, debug: debug)
		}
	}
}


#let draw-class-edge-polyline(edge, debug: 0) = {

	let verts = edge.final-vertices
	let n-segments = verts.len() - 1

	// angles of each segment
	let θs = range(n-segments).map(i => {
		let (vert, vert-next) = (verts.at(i), verts.at(i + 1))
		assert(vert != vert-next, message: "Adjacent vertices must be distinct.")
		angle-between(vert, vert-next)
	})


	// round corners
	let calculate-rounded-corner(i) = {
		let pt = verts.at(i)
		let Δθ = wrap-angle-180(θs.at(i) - θs.at(i - 1))
		let dir = if Δθ > 0deg { +1 } else { -1 } // +1 if ccw, -1 if cw


		let θ-normal = θs.at(i - 1) + Δθ/2 + 90deg  // direction to center of curvature

		let radius = edge.corner-radius
		// radius *= 90deg/calc.max(calc.abs(Δθ), 45deg) // visual adjustment so that tighter bends have smaller radii
		radius *= 1 + calc.cos(Δθ)
		// skip correcting the corner radius for extruded strokes if there's no stroke at all
		if edge.extrude != () {
			radius += if dir > 0 { calc.max(..edge.extrude) } else { -calc.min(..edge.extrude) }
		}
		radius *= dir // ??? makes math easier or something

		if calc.abs(Δθ) > 179deg {
			// singular line; skip arc
			(
				arc-center: pt,
				arc-radius: 0*radius,
				start: θs.at(i - 1) - 90deg,
				delta: wrap-angle-180(Δθ),
				line-shift: 0*radius, // distance from vertex to beginning of arc
			)
		} else {

			// distance from vertex to center of curvature
			let dist = radius/calc.cos(Δθ/2)

			(
				arc-center: vector.add(pt, vector-polar(dist, θ-normal)),
				arc-radius: radius,
				start: θs.at(i - 1) - 90deg,
				delta: wrap-angle-180(Δθ),
				line-shift: radius*calc.tan(Δθ/2), // distance from vertex to beginning of arc
			)
		}

	}

	let rounded-corners
	if edge.corner-radius != none {
		rounded-corners = range(1, θs.len()).map(calculate-rounded-corner)
	}

	let lerp-scale(t, i) = {
		if type(t) in (int, float) {
			let τ = t*n-segments - i
			if (0 < τ and τ <= 1 or
				i == 0 and τ <= 0 or
				i == n-segments - 1 and 1 < τ) { τ }
		} else  {
			t = as-relative(t)
			let τ = lerp-scale(float(t.ratio), i)
			if τ != none {τ *100% + t.length }
		}
	}

	let debug-stroke = edge.stroke.thickness/4 + DEBUG_COLOR2

	// phase keeps track of how to offset dash patterns
	// to ensure continuity between segments
	let phase = 0pt
	let stroke-with-phase(phase) = stroke-to-dict(edge.stroke) + (
		dash: if type(edge.stroke.dash) == dictionary {
			(array: edge.stroke.dash.array, phase: phase)
		}
	)

	// draw each segment
	for i in range(n-segments) {
		let (from, to) = (verts.at(i), verts.at(i + 1))
		let marks = ()

		let Δphase = 0pt

		if edge.corner-radius == none {

			// add phantom marks to ensure segment joins are clean
			if i > 0 {
				let Δθ = θs.at(i) - θs.at(i - 1)
				marks.push((
					inherit: "bar",
					pos: 0,
					angle: 90deg - Δθ/2,
					hide: true,
				))
			}
			if i < θs.len() - 1 {
				let Δθ = θs.at(i + 1) - θs.at(i)
				marks.push((
					inherit: "bar",
					pos: 1,
					angle: 90deg + Δθ/2,
					hide: true,
				))
			}

			Δphase += vector-len(vector.sub(from, to))

		} else { // rounded corners

			if i > 0 {
				// offset start of segment to give space for previous arc
				let (line-shift,) = rounded-corners.at(i - 1)
				from = vector.add(from, vector-polar(line-shift, θs.at(i)))
			}

			if i < θs.len() - 1 {

				let (arc-center, arc-radius, start, delta, line-shift) = rounded-corners.at(i)
				to = vector.add(to, vector-polar(-line-shift, θs.at(i)))

				Δphase += vector-len(vector.sub(from, to))

				for d in edge.extrude {
					if calc.abs(delta) > 1deg {
						cetz.draw.arc(
							arc-center,
							radius: arc-radius - d,
							start: start,
							delta: delta,
							anchor: "origin",
							stroke: stroke-with-phase(phase + Δphase),
						)
					}

					if debug >= 4 {
						cetz.draw.on-layer(1, cetz.draw.circle(
							arc-center,
							radius: arc-radius - d,
							stroke: debug-stroke,
						))

					}
				}

				Δphase += delta/1rad*arc-radius
			}
		}

		marks = marks.map(resolve-mark)

		// distribute original marks across segments
		marks += edge.marks.map(mark => {
			mark.pos = lerp-scale(mark.pos, i)
			mark
		}).filter(mark => mark.pos != none)

		// If the current segment is the one where the label is placed, keep the
		// label (but change its segment to 0 because `draw-edge-line` will consider
		// this segment a single-segment edge and only draw labels on segment 0).
		// Otherwise, draw no label.
		// for i in range(edge.labels.len()) {
		
		// let label-options = if i == edge.labels.at(i).pos.segment {
		// 		(label-pos: edge.labels.at(i).pos + (segment: 0), label: edge.labels.at(i).text)
		// 	} else {
		// 		(label: none)
		// 	}
		// }
		
		let label-options = if i == edge.labels.at(0).pos.segment {
			(label-pos: edge.labels.at(0).pos + (segment: 0), label: edge.labels.at(0).text)
		} else {
			(label: none)
		}


		draw-class-edge-line(
			edge + (
				kind: "line",
				final-vertices: (from, to),
				marks: marks,
				stroke: stroke-with-phase(phase),
			) + label-options,
			debug: debug,
		)

		phase += Δphase

	}


	if debug >= 4 {
		cetz.draw.line(
			..verts,
			stroke: debug-stroke,
		)
	}
}

#let draw-class-edge(edge, ..args) = {
	let obj = if edge.kind == "line" {
		draw-class-edge-line(edge, ..args)
	} else if edge.kind == "arc" {
		draw-class-edge-arc(edge, ..args)
	} else if edge.kind == "poly" {
		draw-class-edge-polyline(edge, ..args)
	} else { error("Invalid edge kind #0.", edge.kind)
	}
	if edge.layer != 0 { obj = cetz.draw.on-layer(edge.layer, obj)}
	(edge.post)(obj)
}
