import 'package:flutter/material.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/AlbumTab.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/Artiststab.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/PlaylistTab.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/RecomendationsTab.dart';
import 'package:music_player_fyp/Src/Presentation/UI/Tabs/SongTab.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Music App"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Songs"),
              Tab(text: "Albums"),
              Tab(text: "Artists"),
              Tab(text: "Playlists"),
              Tab(text: "Recommendations"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Content for the "Songs" tab
            SongsTab(),
            // Content for the "Albums" tab
            AlbumsTab(),
            // Content for the "Artists" tab
            ArtistsTab(),
            // Content for the "Playlists" tab
            PlaylistTab(),
            RecommendationsTab(),
          ],
        ),
      ),
    );
  }
}
