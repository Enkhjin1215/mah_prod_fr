class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) => City(id: json["id"], name: json["name"]);
}

class District {
  final int id;
  final int parent;
  final String name;

  District({required this.id, required this.parent, required this.name});

  factory District.fromJson(Map<String, dynamic> json) => District(id: json["id"], parent: json["parent"], name: json["name"]);
}

class Quarter {
  final int id;
  final int parent;
  final String name;

  Quarter({required this.id, required this.parent, required this.name});

  factory Quarter.fromJson(Map<String, dynamic> json) => Quarter(id: json["id"], parent: json["parent"], name: json["name"]);
}
