import 'package:flutter/material.dart';
import 'package:music_player_fyp/Src/Presentation/UI/MainPage.dart';
import 'package:music_player_fyp/main.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class AppTourScreen extends StatefulWidget {
  const AppTourScreen({Key? key}) : super(key: key);

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _pageController = PageController();
  List<String> imagePaths = [
    "assets/images/1.jpeg",
    "assets/images/2.jpeg",
    "assets/images/3.jpeg",
    "assets/images/4.jpeg",
    "assets/images/5.jpeg",
    "assets/images/6.jpeg",
    "assets/images/7.jpeg",
  ];
  int currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.withOpacity(.3),
      appBar: AppBar(
        title: const Text('App Tour'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                child: Text((currentIndex + 1).toString()),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    imagePaths[index],
                    fit: BoxFit.fitHeight, // Adjust the image fit as needed
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: 60,
                ),
                AnimatedSmoothIndicator(
                  activeIndex: currentIndex,
                  count: imagePaths.length,
                  effect: const ScrollingDotsEffect(
                      dotColor: Colors.white,
                      activeDotColor: Colors.blueAccent),
                ),
                TextButton(
                  onPressed: () {
                    prefs.setBool("isapptourshown", true);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "SKIP TOUR",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
