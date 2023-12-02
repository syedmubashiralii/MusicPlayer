import 'package:flutter/material.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/SongTab.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({Key? key}) : super(key: key);

  @override
  _AlbumsTabState createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  // Main method.
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _searchQuery = ''; // Variable to hold the search query
  List<AlbumModel> filteredAlbums = [];

  // Indicate if application has permission to the library.
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    // (Optinal) Set logging level. By default will be set to 'WARN'.
    //
    // Log will appear on:
    //  * XCode: Debug Console
    //  * VsCode: Debug Console
    //  * Android Studio: Debug and Logcat Console
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);

    // Check and request for permission.
    checkAndRequestPermissions();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );

    // Only call update the UI if application has all required permissions.
    _hasPermission ? setState(() {}) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_hasPermission
            ? noAccessToLibraryWidget()
            : FutureBuilder<List<AlbumModel>>(
                // Default values:
                future: _audioQuery.queryAlbums(
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

                  // Waiting content.
                  if (item.data == null) {
                    return const CircularProgressIndicator();
                  }

                  // 'Library' is empty.
                  if (item.data!.isEmpty) return const Text("Nothing found!");

                  // You can use [item.data!] direct or you can create a:
                  // List<SongModel> AlbumsTab = item.data!;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Search Album...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value
                                  .toLowerCase(); // Convert input to lowercase for case-insensitive search
                              filteredAlbums = item.data!
                                  .where((album) => album.album
                                      .toLowerCase()
                                      .startsWith(_searchQuery))
                                  .toList();

                              debugPrint(
                                  "length :${filteredAlbums.length.toString()}");
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: filteredAlbums.isNotEmpty
                            ? ListView.builder(
                                itemCount: filteredAlbums.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SongsTab(
                                                    id: filteredAlbums[index]
                                                        .id,
                                                    name: filteredAlbums[index]
                                                        .album,
                                                    isalbum: true,
                                                  )));
                                    },
                                    title: Text(filteredAlbums[index].album),
                                    subtitle: Text(
                                        filteredAlbums[index].artist ??
                                            "No Artist"),
                                    trailing:
                                        const Icon(Icons.arrow_forward_rounded),
                                    // This Widget will query/load image.
                                    // You can use/create your own widget/method using [queryArtwork].
                                    leading: QueryArtworkWidget(
                                      id: filteredAlbums[index].id,
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
                                                    name:
                                                        item.data![index].album,
                                                    isalbum: true,
                                                  )));
                                    },
                                    title: Text(item.data![index].album),
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
          const Text("Allow Permissions in Order to Access Musics"),
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
