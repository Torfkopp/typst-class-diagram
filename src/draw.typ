#import "draw-class-edge.typ": draw-class-edge
#import "fletcher/src/draw.typ": *

#let draw-diagram(
	grid,
	nodes,
	edges,
	debug: 0,
) = {

	for edge in edges {
		let nodes = find-nodes-for-edge(nodes, edge)
		if edge.at("labels", default: none) == none { 
			draw-edge(edge, debug: debug) }
		else { 
			draw-class-edge(edge, debug: debug)
		}
	}

	for node in nodes {
		draw-node(node, debug: debug)
	}

	if debug >= 1 {
		draw-debug-axes(grid, debug: debug >= 2)
	}

}
