import 'package:baby_measure/ml_methods/d2go/d2go_page.dart';
import 'package:baby_measure/ml_methods/rectangle_detector.dart';
import 'package:baby_measure/ml_methods/google_pose/google_pose_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];
const List<String> imageNames = [
  "wood6.jpg",
  "vertical_boy.jpg",
  "b6.jpg",
  "g1.jpg",
  "g2.jpg",
  "g4.jpg",
  "g6.jpg",
  "g7.jpg",
  "b1.jpg",
  "b2.jpg",
  "b3.jpg",
  "b4.jpg",
  "b5.jpg",
  "b7.jpg",
  "b8.jpg",
  "b9.jpg",
  "b10.jpg",
  "b11.jpg",
  "b12.jpg",
  "b13.jpg",
  "b14.jpg",
  "b15.jpg",
  "b16.jpg",
  "b17.jpg",
  "b18.jpg",
  "g3.jpg",
  "g5.jpg",
  "g8.jpg",
  "g9.jpg",
  "g10.jpg",
  "g11.jpg",
  "g12.jpg",
  "g13.jpg",
  "g14.jpg",
  "g15.jpg",
  "g16.jpg",
  "wood1.jpg",
  "wood2.jpg",
  "wood3.jpg",
  "wood4.jpg",
  "wood5.jpg",
  "wood7.jpg",
  "wood8.jpg",
  "wood9.jpg",
  "wood10.jpg",
  "wood11.jpg",
  "wood12.jpg",
  "wood13.jpg",
  "vertical_girl.jpg",
  "horizontal_girl.jpg",
  "horizontal_boy.jpg",
  "paper_both.jpg",
  "horizontal_both.jpg",
  "vertical_both.jpg",
];
const List<String> modelNames = [
  "d2go_kp.ptl",
  "d2go_mask.ptl",
  "d2go.ptl",
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // NOTICE can redo this camera part, following: https://pub.dev/packages/camera
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: ${e.code}, Message: ${e.description}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final rectangleDetector = RectangleDetector();

  @override
  void dispose() {
    rectangleDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const Text(
              'Welcome to the baby measurement app. Below are machine learning methods to run...',
            ),
            ElevatedButton(
              child: Text("Run DensePose d2go method"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => D2GoPage(rectangleDetector),
                ),
              ),
            ),
            ElevatedButton(
              key: const ValueKey('page_google_button'),
              child: Text("Run Google ml toolkit method"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GooglePosePage(rectangleDetector),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
