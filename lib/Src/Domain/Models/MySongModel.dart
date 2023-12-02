class Playlist {
  String? name;
  List? songIds;

  Playlist({this.name, this.songIds});

  Playlist.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    songIds = json['songIds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['songIds'] = songIds;
    return data;
  }
}

class MySongModel {
  int? id;

  MySongModel({this.id});

  MySongModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    return data;
  }
}
