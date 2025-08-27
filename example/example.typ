#import "../src/diagram.typ": diagram
#import "../src/class-node.typ": class-node
#import "../src/class-edge.typ": class-edge

#set text(size: 10pt)
#set page(height: auto, width: auto, margin: 10mm)

#diagram(
  class-node(
    (1,0),
    name: <pers>,
    label: "Person",
    attributes: (
      "+name: str",
      "+phoneNumber: str",
      "+emailAddress: str",
    ),
    methods: (
      "+purchaseParkingPass()",
    ),
    colour: red.lighten(50%),
    stroke: red
  ),
  class-node(
    (6, 0),
    name: <a>,
    label: "Address",
    attributes: (
      "+street: str",
      "+city: str",
      "+state: str",
      "+postalCode: str",
      "+country: str",
    ),
    methods: (
      "-validate(): bool",
      "+outputAsLabel(): str",
    ),
    colour: blue.lighten(50%),
    stroke: blue
  ),
  class-node(
    (0, 5),
    name: <s>,
    label: "Student",
    attributes: (
      "+studentNumber: int",
      "+averageMark: int"
    ),
    methods: (
      "+isEligibleToEnroll(str): bool",
      "+getSeminarsTaken(): int"
    ),
    colour: orange.lighten(50%),
    stroke: orange
  ),
  class-node(
    (5, 5), 
    name: <prof>,
    label: "Professor",
    attributes: (
      "/salary: int",
      "#staffNumber: int",
      "-yearsOfService: int",
      "+numberOfClasses: int"
    ),
    colour: yellow.lighten(50%),
    stroke: yellow
  ),
  class-edge(<pers.east>, <a.1.75>, arrow: "Navigable Association", direction: right, label: "lives at", mult-left: "0..1", mult-right: "1"),
  class-edge(<pers.south>, (1.275, 3.5), (0.28, 3.5), <s.north>, arrow: "Inheritance", direction: left),
  class-edge(<pers.south>, (1.275, 3.5), (5.023, 3.5), <prof.north>, arrow: "Inheritance", direction: left),
  class-edge(<s.east>, <prof.west>, arrow: "Navigable Association", direction: left, label: (text: "supervises", side: right), mult-left: "0..*", mult-right: "0..5"),
)