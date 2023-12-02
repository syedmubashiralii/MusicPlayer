// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';

// class AlbumDetailsScreen extends StatefulWidget {
//   final String albumId;

//   const AlbumDetailsScreen({Key? key, required this.albumId}) : super(key: key);

//   @override
//   _AlbumDetailsScreenState createState() => _AlbumDetailsScreenState();
// }

// class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _albumSongs = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadAlbumSongs();
//   }

//   _loadAlbumSongs() async {
//     final album = await _audioQuery.queryAlbums(albumId: widget.albumId);
//     if (album.isNotEmpty) {
//       final albumModel = album.first;
//       final songs = await _audioQuery.queryAudiosFrom(albumModel);

//       setState(() {
//         _albumSongs = songs;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Album Details'),
//       ),
//       body: ListView.builder(
//         itemCount: _albumSongs.length,
//         itemBuilder: (context, index) {
//           final song = _albumSongs[index];
//           return ListTile(
//             title: Text(song.title),
//             subtitle: Text(song.artist ?? 'Unknown Artist'),
//             // Add more song details or actions here as needed.
//           );
//         },
//       ),
//     );
//   }
// }
