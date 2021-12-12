// ignore_for_file: deprecated_member_use

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import '../main.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isWorking = false;
  String result = '';
  CameraController? controller;
  CameraImage? cameraImage;

  loadModelData() async {
    await Tflite.loadModel(
      model: 'assets/models.tflite',
      labels: 'assets/labels.txt',
      isAsset: true,
    );
  }

  initCamera() {
    controller = CameraController(cameras![0], ResolutionPreset.max);
    controller!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller!.startImageStream((imagesFromStream) {
          if (!isWorking) {
            isWorking = true;
            cameraImage = imagesFromStream;
            runModelOnStream();
          }
        });
      });
    });
  }

  runModelOnStream() async {
    if (cameraImage != null) {
      var recognition = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map(
          (value) {
            return value.bytes;
          },
        ).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.4,
        asynch: true,
      );
      result = '';
      // ignore: avoid_function_literals_in_foreach_calls
      recognition!.forEach((element) {
        result += element['label'] +
            ' ' +
            (element['confidence'] as double).toStringAsFixed(2) +
            '\n\n';
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    loadModelData();
  }

  @override
  void dispose() async {
    super.dispose();
    controller?.dispose();
    await Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 300,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset('assets/tf.jpeg'),
                  ),
                ),
                Center(
                  child: FlatButton(
                    onPressed: () {
                      initCamera();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 35),
                      height: 600,
                      width: MediaQuery.of(context).size.width,
                      child: cameraImage == null
                          ? SizedBox(
                              height: 600,
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    'Please tap the camera button to enable Camera...',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: controller!.value.aspectRatio,
                              child: CameraPreview(controller!),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Container(
                height: 25,
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(top: 20),
                child: SingleChildScrollView(
                  child: Text(
                    result,
                    style: const TextStyle(
                      backgroundColor: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
