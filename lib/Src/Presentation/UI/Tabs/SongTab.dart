import 'dart:convert';

import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';
import 'package:music_player_fyp/Constants.dart';
import 'package:music_player_fyp/Src/Domain/Models/MySongModel.dart';
import 'package:music_player_fyp/main.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:share_plus/share_plus.dart';

class SongsTab extends StatefulWidget {
  final int? id;
  final String? name;
  final bool? isalbum;
  final bool? isfromplaylist;
  final List<SongModel>? playlistsonglist;
  final bool? isfromrecomendation;
  final List<SongModel>? recommendedsonglist;
  const SongsTab(
      {Key? key,
      this.id,
      this.name,
      this.isalbum,
      this.isfromplaylist,
      this.playlistsonglist,
      this.isfromrecomendation,
      this.recommendedsonglist})
      : super(key: key);

  @override
  _SongsTabState createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  // var playlistsBox = Hive.box<Playlist>('playlists');
  // var songsBox = Hive.box<SongModel>('songs');
  // Main method.
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _searchQuery = ''; // Variable to hold the search query
  List<SongModel> filteredSongs = [];
  // Indicate if application has permission to the library.
  List<SongModel> songs = [];
  bool _hasPermission = false;
  bool isMusicPlayerTapped = false;
  final AudioPlayer _player = AudioPlayer();
  AppinioSocialShare appinioSocialShare = AppinioSocialShare();
  @override
  void initState() {
    super.initState();
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _audioQuery.setLogConfig(logConfig);

    checkAndRequestPermissions();
    //Updates the current song playing
    _player.currentIndexStream.listen((index) async {
      if (index != null) {
        _updateCurrentPlayingSongDetails(index);
      }
    });

    //This block of method used if the current playing is the last index in the song queue and changes the  icon button if the song ended
    _player.playerStateStream.listen((playerState) async {
      if (playerState.playing == true) {
        setState(() {
          isPlaying = true;
        });
      }
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _player.dispose();
  }

  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );

    // Only call update the UI if application has all required permissions.
    _hasPermission ? setState(() {}) : null;
  }

  ConcatenatingAudioSource createPlaylist(List<SongModel>? songs) {
    List<AudioSource> sources = [];

    for (var song in songs!) {
      sources.add(AudioSource.uri(Uri.parse(song.uri!)));
    }

    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: sources,
    );
  }

  void _changePlayerVisibility() {
    setState(() {
      isPlayerViewVisible = true;
    });
  }

  void _updateCurrentPlayingSongDetails(int index) {
    setState(() {
      if (songs.isNotEmpty) {
        currentSongTitle = songs[index].title;
        currentIndex = index;
        currentSongID = songs[index].id;
        currentArtist = songs[index].artist! ?? "UnKnown";
        isPlaying = true;
      }
    });
  }

//A stream objecct that holds the duration of songs and the current position
  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration?, DurationState>(
          _player.positionStream,
          _player.durationStream,
          (position, duration) => DurationState(
              position: position, total: duration ?? Duration.zero));
  int currentIndex = 0;
  int currentSongID = 0;
  bool isPlayerViewVisible = false;
  String currentSongTitle = "";
  String currentArtist = "";
  bool isPlaying = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.name != null
          ? AppBar(
              title: Text(widget.name! ?? ""),
            )
          : null,
      body: Center(
        child: !_hasPermission
            ? noAccessToLibraryWidget()
            : FutureBuilder<List<SongModel>>(
                // Default values:
                future: _audioQuery.querySongs(
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
                  List<SongModel> Songslist = [];
                  if (widget.id != null) {
                    for (var song in item.data!) {
                      var id = widget.isalbum! ? song.albumId : song.artistId;
                      if (id == widget.id) {
                        Songslist.add(song);
                      }
                    }
                  } else if (widget.isfromplaylist == true) {
                    Songslist = widget.playlistsonglist!;
                  } else if (widget.isfromrecomendation == true) {
                    Songslist = widget.recommendedsonglist!;
                  } else {
                    Songslist = item.data!;
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Search songs...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value
                                  .toLowerCase(); // Convert input to lowercase for case-insensitive search
                              filteredSongs = Songslist.where((song) => song
                                  .title
                                  .toLowerCase()
                                  .contains(_searchQuery)).toList();
                              debugPrint(
                                  "length :${filteredSongs.length.toString()}");
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: filteredSongs.isNotEmpty
                            ? ListView.builder(
                                itemCount: filteredSongs.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      if (currentSongID !=
                                          filteredSongs[index].id) {
                                        //Store the full list of songs
                                        songs = filteredSongs;
                                        _changePlayerVisibility();
                                        // Play a sound as a one-shot, releasing its resources when it finishes playing.

                                        _updateCurrentPlayingSongDetails(index);

                                        _player.setAudioSource(
                                            createPlaylist(filteredSongs),
                                            initialIndex: index);
                                        saveRecommendationsToPrefs(
                                            filteredSongs[index]);

                                        _player.play();
                                      } else {
                                        setState(() {
                                          isMusicPlayerTapped =
                                              !isMusicPlayerTapped;
                                        });
                                      }
                                    },
                                    title: Text(
                                      filteredSongs[index].title ?? "",
                                      style: TextStyle(
                                          color: currentSongID !=
                                                  filteredSongs[index].id
                                              ? Colors.black
                                              : Colors.blueAccent),
                                    ),
                                    subtitle: Text(
                                        filteredSongs[index].artist ??
                                            "No Artist"),
                                    trailing: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (currentSongID ==
                                                filteredSongs[index].id &&
                                            isPlaying)
                                          const MiniMusicVisualizer(
                                            color: Colors.blueAccent,
                                            width: 4,
                                            height: 15,
                                          ),
                                      ],
                                    ),
                                    // This Widget will query/load image.
                                    // You can use/create your own widget/method using [queryArtwork].
                                    leading: QueryArtworkWidget(
                                      id: filteredSongs[index].id,
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
                                itemCount: Songslist.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () {
                                      if (currentSongID !=
                                          Songslist[index].id) {
                                        //Store the full list of songs
                                        songs = Songslist;
                                        _changePlayerVisibility();
                                        // Play a sound as a one-shot, releasing its resources when it finishes playing.
                                        _updateCurrentPlayingSongDetails(index);
                                        _player.setAudioSource(
                                            createPlaylist(Songslist),
                                            initialIndex: index);
                                        saveRecommendationsToPrefs(
                                            Songslist[index]);
                                        _player.play();
                                      } else {
                                        setState(() {
                                          isMusicPlayerTapped =
                                              !isMusicPlayerTapped;
                                        });
                                      }
                                    },
                                    title: Text(
                                      Songslist[index].title,
                                      style: TextStyle(
                                          color: currentSongID !=
                                                  Songslist[index].id
                                              ? Colors.black
                                              : Colors.blueAccent),
                                    ),
                                    subtitle: Text(
                                        Songslist[index].artist ?? "No Artist"),
                                    trailing: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (currentSongID ==
                                                Songslist[index].id &&
                                            isPlaying)
                                          const MiniMusicVisualizer(
                                            color: Colors.blueAccent,
                                            width: 4,
                                            height: 15,
                                          ),
                                      ],
                                    ),
                                    // This Widget will query/load image.
                                    // You can use/create your own widget/method using [queryArtwork].
                                    leading: QueryArtworkWidget(
                                      id: Songslist[index].id,
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
      floatingActionButton: widget.isfromplaylist == true
          ? FloatingActionButton(
              onPressed: () {
                _showSongListDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : const SizedBox(),
      bottomSheet: isPlayerViewVisible
          ? Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: isMusicPlayerTapped
                  ? MediaQuery.of(context).size.height * 0.1
                  : MediaQuery.of(context).size.height * 0.96,
              child: isMusicPlayerTapped
                  ? Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isMusicPlayerTapped = !isMusicPlayerTapped;
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.hide');
                            });
                          },
                          child: Container(
                            color: Colors.blueAccent,
                            child: ListTile(
                              leading: QueryArtworkWidget(
                                id: currentSongID,
                                keepOldArtwork: true,
                                type: ArtworkType.AUDIO,
                                artworkBorder: BorderRadius.zero,

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
                              title: SizedBox(
                                height: 18,
                                child: currentSongTitle.length > 20
                                    ? Marquee(
                                        text: (currentSongTitle)
                                                .replaceAll('_', ' ') +
                                            ('      '),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        fadingEdgeStartFraction: 0.2,
                                        fadingEdgeEndFraction: 0.2,
                                        scrollAxis: Axis.horizontal,
                                      )
                                    : Text(
                                        currentSongTitle,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        maxLines: 1,
                                      ),
                              ),
                              subtitle: Text(
                                currentArtist ?? "No Artist",
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                              ),
                              trailing: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isPlaying
                                      ? IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              isPlaying = !isPlaying;
                                            });
                                            await _player.pause();
                                          },
                                          icon: const Icon(Icons.pause,
                                              color: Colors.white),
                                        )
                                      : IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              isPlaying = !isPlaying;
                                            });
                                            await _player.play();
                                          },
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                          )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        StreamBuilder<DurationState>(
                            stream: _durationStateStream,
                            builder: (context, snapshot) {
                              final durationState = snapshot.data;
                              final progress =
                                  durationState?.position ?? Duration.zero;
                              final total =
                                  durationState?.total ?? Duration.zero;

                              return IgnorePointer(
                                child: ProgressBar(
                                  thumbGlowRadius: 0,
                                  thumbRadius: 0,
                                  progress: progress,
                                  total: total,
                                  barHeight: 3.0,
                                  timeLabelTextStyle: const TextStyle(
                                      color: Colors.transparent),
                                  baseBarColor: Colors.white,
                                  progressBarColor: Colors.lightBlue,
                                  thumbColor: Colors.transparent,
                                ),
                              );
                            }),
                      ],
                    )
                  : WillPopScope(
                      //Overrides Back button
                      onWillPop: () async {
                        setState(() {
                          isMusicPlayerTapped = !isMusicPlayerTapped;
                        });
                        return false;
                      },
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isMusicPlayerTapped =
                                              !isMusicPlayerTapped;
                                        });
                                      },
                                      icon: const Icon(
                                          Icons.expand_more_outlined,
                                          size: 30,
                                          color: Colors.blueAccent)),
                                  IconButton(
                                      onPressed: () async {
                                        List<Playlist> playlists = [];

                                        String recommendationsString =
                                            prefs.getString('playlists') ?? '';
                                        if (recommendationsString.isNotEmpty) {
                                          List decodedList =
                                              jsonDecode(recommendationsString);
                                          for (var data in decodedList) {
                                            playlists
                                                .add(Playlist.fromJson(data));
                                          }
                                        }
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Playlists'),
                                              content: SizedBox(
                                                width: double.maxFinite,
                                                height: 400,
                                                child: ListView.builder(
                                                  itemCount: playlists.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return ListTile(
                                                      title: Text(
                                                          playlists[index]
                                                                  .name ??
                                                              ""),
                                                      onTap: () {
                                                        // print(songs[
                                                        //     currentIndex]);
                                                        if (!playlists[index]
                                                            .songIds!
                                                            .contains(songs[
                                                                    currentIndex]
                                                                .id)) {
                                                          playlists[index]
                                                              .songIds!
                                                              .add(songs[
                                                                      currentIndex]
                                                                  .id);

                                                          ///update methid calling
                                                          ///
                                                          updatePlaylist(
                                                              playlists[index]);

                                                          var snackBar =
                                                              SnackBar(
                                                            content: Text(
                                                                'Song Added in ${playlists[index].name}'),
                                                          );
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  snackBar);
                                                        } else {
                                                          var snackBar =
                                                              SnackBar(
                                                            content: Text(
                                                                'Song Already in ${playlists[index].name}'),
                                                          );
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  snackBar);
                                                        }
                                                        Navigator.pop(context);
                                                      },
                                                      // Add more ListTile properties or onTap functionality
                                                    );
                                                  },
                                                ),
                                              ),
                                              actions: <Widget>[
                                                ElevatedButton(
                                                  child: const Text('Close'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.library_add,
                                          size: 30, color: Colors.blueAccent)),
                                  IconButton(
                                      onPressed: () async {
                                        debugPrint(songs[0].data);

                                        final result = await Share.shareXFiles(
                                          [XFile(songs[currentIndex].data)],
                                        );

                                        if (result.status ==
                                            ShareResultStatus.success) {
                                          print(
                                              'Thank you for sharing the picture!');
                                        }
                                        // await appinioSocialShare
                                        //     .shareToWhatsapp("Great Song!",
                                        //         filePath:
                                        //             songs[currentIndex].data);
                                      },
                                      icon: const Icon(Icons.share,
                                          size: 30, color: Colors.blueAccent)),
                                ],
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 40, bottom: 10),
                                height: 250,
                                width: 250,
                                child: QueryArtworkWidget(
                                  id: currentSongID,
                                  keepOldArtwork: true,
                                  type: ArtworkType.AUDIO,
                                  artworkBorder: BorderRadius.zero,

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
                                        size: 120,
                                      )),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Text(
                                      currentSongTitle.replaceAll('_', ' '),
                                      style: const TextStyle(
                                          color: Colors.blueGrey, fontSize: 20),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      currentArtist ?? "No Artist",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.blueGrey),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 55,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: StreamBuilder<DurationState>(
                                    stream: _durationStateStream,
                                    builder: (context, snapshot) {
                                      final durationState = snapshot.data;
                                      final progress =
                                          durationState?.position ??
                                              Duration.zero;
                                      final total =
                                          durationState?.total ?? Duration.zero;

                                      return ProgressBar(
                                        onSeek: (duration) {
                                          _player.seek(duration);
                                        },
                                        progress: progress,
                                        total: total,
                                        barHeight: 6.0,
                                        thumbRadius: 8,
                                        timeLabelLocation:
                                            TimeLabelLocation.sides,
                                        timeLabelTextStyle: const TextStyle(
                                            color: Colors.black),
                                        baseBarColor: Colors.blueAccent,
                                        progressBarColor: Colors.blueGrey,
                                        thumbColor: Colors.blueAccent,
                                      );
                                    }),
                              ),
                              const SizedBox(
                                height: 25,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      onPressed: () async {
                                        await _player.seekToPrevious();
                                      },
                                      icon: const Icon(Icons.skip_previous,
                                          size: 40, color: Colors.blueGrey)),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  isPlaying
                                      ? IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              isPlaying = !isPlaying;
                                            });
                                            await _player.pause();
                                          },
                                          icon: const Icon(
                                            Icons.pause,
                                            color: Colors.blueAccent,
                                            size: 40,
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              isPlaying = !isPlaying;
                                            });
                                            await _player.play();
                                          },
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.blueAccent,
                                            size: 40,
                                          )),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  IconButton(
                                      onPressed: () async {
                                        await _player.seekToNext();
                                      },
                                      icon: const Icon(Icons.skip_next,
                                          size: 40, color: Colors.blueGrey)),
                                ],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.06,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            )
          : null,
    );
  }

  Future<List<SongModel>> fetchSongs() async {
    return await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<void> _showSongListDialog(BuildContext context) async {
    List<SongModel> songs = await fetchSongs();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Songs to ${currentplaylist!.name}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.0, // Set height as needed
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(songs[index].title),
                    subtitle: Text(songs[index].artist!),
                    onTap: () {
                      // print(songs[
                      //     currentIndex]);

                      if (!currentplaylist!.songIds!
                          .contains(songs[index].id)) {
                        currentplaylist!.songIds!.add(songs[index].id);
// update methid calling
                        updatePlaylist(currentplaylist!);
                        var snackBar = SnackBar(
                          content:
                              Text('Song Added to ${currentplaylist!.name}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);

                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        var snackBar = SnackBar(
                          content:
                              Text('Song Already in ${currentplaylist!.name}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    // You can add more ListTile properties or UI elements
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  Future updatePlaylist(Playlist newplaylist) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Playlist> playlists = [];
    String playlistString = prefs.getString('playlists') ?? '';

    if (playlistString.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(playlistString);
      playlists = decodedList.map((item) => Playlist.fromJson(item)).toList();
    }
    for (var play in playlists) {
      if (play.name == newplaylist.name) {
        play.songIds = newplaylist.songIds;
      }
    }

    List<Map<String, dynamic>> updatedplaylist =
        playlists.map((model) => model.toJson()).toList();
    String encodedRecommendations = jsonEncode(updatedplaylist);
    prefs.setString('playlists', encodedRecommendations);
  }

  void saveRecommendationsToPrefs(SongModel newSongModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<MySongModel> recommendations = [];
    String recommendationsString = prefs.getString('recommendations') ?? '';

    if (recommendationsString.isNotEmpty) {
      List<dynamic> decodedList = jsonDecode(recommendationsString);
      recommendations =
          decodedList.map((item) => MySongModel.fromJson(item)).toList();
    }
    recommendations.add(MySongModel(id: newSongModel.id));
    List<Map<String, dynamic>> updatedRecommendations =
        recommendations.map((model) => model.toJson()).toList();

    // Convert the list of maps to JSON and save it in SharedPreferences
    String encodedRecommendations = jsonEncode(updatedRecommendations);
    prefs.setString('recommendations', encodedRecommendations);
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

class DurationState {
  DurationState({this.position = Duration.zero, this.total = Duration.zero});
  Duration position, total;
}
