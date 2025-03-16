import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:audioplayers/audioplayers.dart';

final List<String> labels = ["Cat", "Dog", "Others", "Human"];
tfl.Interpreter? interpreter;
final audioPlayer = AudioPlayer();

Future<void> loadModel() async {
  try {
    interpreter = await tfl.Interpreter.fromAsset("assets/model.tflite");
    debugPrint("Model loaded successfully.");
  } catch (e) {
    debugPrint("Error loading model: $e");
  }
}

Future<File?> pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  return pickedFile != null ? File(pickedFile.path) : null;
}

Future<Map<String, dynamic>> classifyImage(File imageFile) async {
  if (interpreter == null)
    return {"result": "Model not loaded", "color": Colors.white};

  final image = img.decodeImage(imageFile.readAsBytesSync());
  if (image == null)
    return {"result": "Error processing image", "color": Colors.white};

  final resizedImage = img.copyResize(image, width: 224, height: 224);
  final input = [
    List.generate(
      224,
      (y) => List.generate(224, (x) {
        final pixel = resizedImage.getPixel(x, y);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      }),
    ),
  ];

  final output = [List.filled(4, 0.0)];
  interpreter!.run(input, output);

  final maxIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
  final label = labels[maxIndex];
  final colorMap = {
    "Cat": Colors.red,
    "Dog": Colors.blue,
    "Human": Colors.green,
    "Others": Colors.grey,
  };

  await playSound(label);

  return {"result": "Result: $label", "color": colorMap[label] ?? Colors.grey};
}

Future<void> playSound(String label) async {
  final soundMap = {
    "Cat": "sounds/cat.mp3",
    "Dog": "sounds/dog.mp3",
    "Human": "sounds/human.mp3",
    "Others": "sounds/others.mp3",
  };
  try {
    await audioPlayer.play(AssetSource(soundMap[label] ?? "sounds/others.mp3"));
  } catch (e) {
    debugPrint("Error playing sound: $e");
  }
}

void disposeResources() {
  interpreter?.close();
  audioPlayer.dispose();
}
