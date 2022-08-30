import 'package:baby_measure/ml_methods/d2go/d2go_page.dart';
import 'package:baby_measure/ml_methods/google_ml_toolkit/google_ml_toolkit_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // TODO redo this camera part, following: https://pub.dev/packages/camera
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
                MaterialPageRoute(builder: (context) => D2GoPage()),
              ),
            ),
            ElevatedButton(
              child: Text("Run Google ml toolkit method"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoogleMLToolkitPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
