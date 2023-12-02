import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/SongTab.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({Key? key}) : super(key: key);

  @override
  _RecommendationsTabState createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;
  List recommendations = [];
  Set<SongModel> recommendedsong = {};

  @override
  void initState() {
    super.initState();
    checkAndRequestPermissions();
    checkRecommendation();
  }

  void checkRecommendation() async {
    try {
      recommendedsong = {};

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String recommendationsString = prefs.getString('recommendations') ?? '';
      if (recommendationsString.isNotEmpty) {
        List decodedList = jsonDecode(recommendationsString);
        recommendations = decodedList;

        List<SongModel> songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        if (recommendations.isNotEmpty) {
          for (var song in songs) {
            for (var data in recommendations) {
              if (data['id'] == song.id) {
                recommendedsong.add(song);
                // return;
              }
            }
          }
        }
        // recommendations =
        //     decodedList.map((item) => MySongModel.fromJson(item)).toList();
        print("hggcgrec$decodedList");
        print("hggcgrec$recommendedsong");
        setState(() {});
      }
    } catch (e) {
      print("hggexep$e");
    }
  }

  void saveRecommendationsToPrefs(SongModel newSongModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Create a new list containing the existing recommendations along with the new SongModel
    List<SongModel> updatedRecommendations = List.from(recommendations)
      ..add(newSongModel);

    // Convert the updated recommendations list to JSON
    List<SongModel> songListMap =
        updatedRecommendations.map((song) => song).toList();
    String encodedRecommendations = jsonEncode(songListMap);

    // Save the updated recommendations list to SharedPreferences
    prefs.setString('recommendations', encodedRecommendations);
  }

  void checkAndRequestPermissions({bool retry = false}) async {
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
            : recommendations.isEmpty
                ? const Center(
                    child: Text(
                      'No recommendations found!\nListen Songs to get Recommendations',
                      textAlign: TextAlign.center,
                    ),
                  )
                : SongsTab(
                    isfromrecomendation: true,
                    recommendedsonglist: recommendedsong.toList(),
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
