#import "/src/diagram.typ": diagram
#import "/src/node.typ": node
#import "/src/edge.typ": edge
#import "/src/class-edge.typ": class-edge
#import "/src/shapes.typ": *

// let labels = (
//       (
//         text: "center",
//         side: left,
//         pos: 50%,
//         sep: 0pt,
//         angle: 0deg,
//         anchor: auto,
//         fill: auto,
//         size: auto,
//         wrapper: auto,
//       ),
//       (
//         text: "multleft",
//         side: left,
//         pos: 15%,
//         sep: 0pt,
//         angle: 0deg,
//         anchor: auto,
//         fill: auto,
//         size: auto,
//         wrapper: auto,
//       ),
//       (
//         text: "multright",
//         side: left,
//         pos: 85%,
//         sep: 0pt,
//         angle: 0deg,
//         anchor: auto,
//         fill: auto,
//         size: auto,
//         wrapper: auto,
//       ),
//       (
//         text: "descleft",
//         side: right,
//         pos: 15%,
//         sep: 0pt,
//         angle: 0deg,
//         anchor: auto,
//         fill: auto,
//         size: auto,
//         wrapper: auto,
//       ),
//       (
//         text: "descright",
//         side: right,
//         pos: 85%,
//         sep: 0pt,
//         angle: 0deg,
//         anchor: auto,
//         fill: auto,
//         size: auto,
//         wrapper: auto,
//       ),
//     )

#diagram(
	spacing: (18mm, 10mm),
  node-stroke: black,
	node(
    (0,0),
    name: <d>,
    [#text(fill: rgb(0,0,0,0))[Person]],
    shape: class-node-draw.with(
      colour: green,
      attributes: (
        "+name: str",
        "+phoneNumber: str",
        "+emailAddress: str",
      ),
      methods: (
        "+purchaseParkingPass()",
      ),
    ),
  ),

  node(
    (6,0.5),
    name: <e>,
    [#text(fill: rgb(0,0,0,0))[Person]],
    // shape: parallelogram,
    shape: class-node-draw.with(),
  ),
	class-edge(<d.east>, <e.west>, arrow: "Composition", label: "Person"),
  // class-edge(<d>, (6,6), (2,6), (1,5), (0,5),  <d.south>, arrow: "Composition", bend: -110deg, loop-angle: 120deg, label: "test", mult_left: "1", mult_right: "2", desc_left: "3", desc_right: "4"),
  class-edge(<d.north>, (0.45, -2), (5.91, -2), <e.north>, arrow: "Inheritance", label: "test", mult_left: "1", mult_right: "2", desc_left: "3", desc_right: "4"),
  //class-edge(<e>, "~>", <e>, bend: -130deg, loop-angle: 120deg, label: "test"),
  // edge(<d.south>, (0.45,4), (5.91,4), <e.south>, label: "test", label-pos: 20%)
)

= TODO
+ #strike[Class boxes]
+ #strike[Arrows]
  - #strike[ARROW HEADS L 117 / L 127]
  - #strike[Mehrere Labels]
+ #strike[Polyline fix]
  -  #strike[First and last segment get mult/ desc]
  -  #strike[One Segment in the middle gets label]
+ Better name than "class-edge"
  - Better names for other stuff as well
+ Clean Up
  - Comments etc.
+ Package Up
  - Minimal Usage of Fletcher
+ Manual
  - Example
