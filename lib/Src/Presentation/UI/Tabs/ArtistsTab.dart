import 'package:flutter/material.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/SongTab.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({Key? key}) : super(key: key);

  @override
  _ArtistsTabState createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _searchQuery = ''; // Variable to hold the search query
  List<ArtistModel> filteredArtists = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);
    checkAndRequestPermissions();
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
            : FutureBuilder<List<ArtistModel>>(
                // Default values:
                future: _audioQuery.queryArtists(
                  sortType: null,
                  orderType: OrderType.ASC_OR_SMALLER,
                  uriType: UriType.EXTERNAL,
                  ignoreCase: true,
                ),
                builder: (context, item) {
                  // Display error, if any.
                  if (item.hasError) {
                    return Text(item.error.toString());
                  }
                  if (item.data == null) {
                    return const CircularProgressIndicator();
                  }
                  if (item.data!.isEmpty) return const Text("Nothing found!");
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Search Artists...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value
                                  .toLowerCase(); // Convert input to lowercase for case-insensitive search

                              filteredArtists = item.data!
                                  .where((artist) => artist.artist
                                      .toLowerCase()
                                      .startsWith(_searchQuery))
                                  .toList();
                              if (_searchQuery == "") {
                                filteredArtists = [];
                              }

                              debugPrint(
                                  "length :${filteredArtists.length.toString()}");
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: filteredArtists.isNotEmpty
                            ? ListView.builder(
                                itemCount: filteredArtists.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SongsTab(
                                                    id: filteredArtists[index]
                                                        .id,
                                                    name: filteredArtists[index]
                                                        .artist,
                                                    isalbum: false,
                                                  )));
                                    },
                                    title: Text(
                                      filteredArtists[index].artist,
                                      style:
                                          const TextStyle(color: Colors.green),
                                    ),
                                    subtitle: Text(
                                        filteredArtists[index].artist ??
                                            "No Artist"),
                                    trailing:
                                        const Icon(Icons.arrow_forward_rounded),
                                    // This Widget will query/load image.
                                    // You can use/create your own widget/method using [queryArtwork].
                                    leading: QueryArtworkWidget(
                                      id: filteredArtists[index].id,
                                      type: ArtworkType.AUDIO,
                                      artworkBorder: BorderRadius.zero,
                                      keepOldArtwork: true,

                                      //If the artwork or the song has no illustration
                                      nullArtworkWidget: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: Colors.blueAccent,
                                          ),
                                          child: const Icon(
                                            Icons.music_note_sharp,
                                            color: Colors.white,
                                          )),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: item.data!.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SongsTab(
                                                    id: item.data![index].id,
                                                    name: item
                                                        .data![index].artist,
                                                    isalbum: false,
                                                  )));
                                    },
                                    title: Text(item.data![index].artist),
                                    subtitle: Text(item.data![index].artist ??
                                        "No Artist"),
                                    trailing:
                                        const Icon(Icons.arrow_forward_rounded),
                                    // This Widget will query/load image.
                                    // You can use/create your own widget/method using [queryArtwork].
                                    leading: QueryArtworkWidget(
                                      id: item.data![index].id,
                                      type: ArtworkType.AUDIO,
                                      artworkBorder: BorderRadius.zero,
                                      keepOldArtwork: true,

                                      //If the artwork or the song has no illustration
                                      nullArtworkWidget: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: Colors.blueAccent,
                                          ),
                                          child: const Icon(
                                            Icons.music_note_sharp,
                                            color: Colors.white,
                                          )),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
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
