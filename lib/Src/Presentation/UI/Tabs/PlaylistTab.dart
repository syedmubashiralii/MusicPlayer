import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_player_fyp/Constants.dart';
import 'package:music_player_fyp/Src/Domain/Models/MySongModel.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/SongTab.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistTab extends StatefulWidget {
  const PlaylistTab({Key? key}) : super(key: key);

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  // Main method.
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final String _searchQuery = '';
  bool _hasPermission = false;
  List<Playlist> playlists = [];
  List<SongModel> allsongs = [];
  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);
    checkAndRequestPermissions();
    checkplaylist();
  }

  checkplaylist() async {
    try {
      playlists = [];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String recommendationsString = prefs.getString('playlists') ?? '';
      if (recommendationsString.isNotEmpty) {
        List decodedList = jsonDecode(recommendationsString);
        for (var data in decodedList) {
          playlists.add(Playlist.fromJson(data));
        }
        // playlists = decodedList;

        print("hggcgrec$decodedList");
        allsongs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        setState(() {});
      }
    } catch (e) {
      print("hggexep$e");
    }
  }

  checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );
    _hasPermission ? setState(() {}) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_hasPermission
            ? noAccessToLibraryWidget()
            : playlists.isEmpty
                ? const Center(child: Text('No playlists available'))
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Colors.blueAccent,
                            ),
                            child: const Icon(
                              Icons.music_note_sharp,
                              color: Colors.white,
                            )),
                        title: Text(playlists[index].name ?? ""),
                        subtitle: Text(playlists[index].songIds == null
                            ? "0 songs"
                            : "${playlists[index].songIds!.length.toString()} songs"),
                        onTap: () async {
                          List<SongModel> songsInPlaylist = [];
                          for (var song in allsongs) {
                            if (playlists[index].songIds != null &&
                                playlists[index].songIds!.isNotEmpty) {
                              print("playlists${playlists[index].songIds}");
                              for (var data in playlists[index].songIds!) {
                                if (data == song.id) {
                                  songsInPlaylist.add(song);
                                  // return;
                                }
                              }
                            }
                          }

                          currentplaylist = playlists[index];
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SongsTab(
                                        name: playlists[index].name,
                                        isfromplaylist: true,
                                        playlistsonglist: songsInPlaylist,
                                      ))).then((value) => checkplaylist());
                        },
                        // Add more ListTile properties or onTap functionality
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlaylistDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddPlaylistDialog(BuildContext context) async {
    TextEditingController playlistNameController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Playlist'),
          content: TextField(
            controller: playlistNameController,
            decoration: const InputDecoration(labelText: 'Playlist Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final playlistName = playlistNameController.text;
                if (playlistName.isNotEmpty) {
                  var newPlaylist = Playlist();
                  newPlaylist.name = playlistName;
                  newPlaylist.songIds = <int>[];
                  await createPlaylist(newPlaylist);
                  Navigator.of(context).pop();
                  checkplaylist();
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future createPlaylist(Playlist newplaylist) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Playlist> playlists = [];
    String playlistString = prefs.getString('playlists') ?? '';

    if (playlistString.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(playlistString);
      playlists = decodedList.map((item) => Playlist.fromJson(item)).toList();
    }
    playlists
        .add(Playlist(name: newplaylist.name, songIds: newplaylist.songIds));
    List<Map<String, dynamic>> updatedplaylist =
        playlists.map((model) => model.toJson()).toList();
    String encodedRecommendations = jsonEncode(updatedplaylist);
    prefs.setString('playlists', encodedRecommendations);
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}
