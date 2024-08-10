import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  File? imageFile1;
  File? imageFile2;

  String prompt = "Are they the same person?";
  String response = '';

  TextStyle ts1 = TextStyle(color: Colors.white, fontSize: 16.0);
  TextStyle ts2 = TextStyle(color: Colors.redAccent, fontSize: 16.0);

  @override
  Widget build(BuildContext context) {
    Image? image1 = imageFile1 != null ? Image.file(imageFile1!) : null;
    Image? image2 = imageFile2 != null ? Image.file(imageFile2!) : null;

    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Stack(children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Row(children: [
                Expanded(flex: 1, child: Center(child: image1)),
                SizedBox(width: 10),
                Expanded(flex: 1, child: Center(child: image2)),
              ]),
            ),
            Row(children: [
              myButton(icon: Icons.stop_circle_outlined, onPressed: () => onReset()),
              myButton(icon: Icons.image_outlined, onPressed: () => onSelectImage1()),
              myButton(icon: Icons.image_outlined, onPressed: () => onSelectImage2()),
              myButton(icon: Icons.play_circle_outline, onPressed: () => onGenerate()),
            ]),
            Row(children: [Expanded(child: myText(prompt, style: ts1))]),
            Row(children: [Expanded(child: myText(response, style: ts2, height: 100))]),
          ]),
        )
      ]),
    );
  }

  Future<void> onReset() async {
    setState(() {
      imageFile1 = null;
      imageFile2 = null;
      response = '';
    });
  }

  Future<void> onSelectImage1() async {
    FilePickerResult? f = await FilePicker.platform.pickFiles();
    if (f != null && f.files.single.path != null) {
      setState(() {
        imageFile1 = File(f.files.single.path!);
      });
    }
  }

  Future<void> onSelectImage2() async {
    FilePickerResult? f = await FilePicker.platform.pickFiles();
    if (f != null && f.files.single.path != null) {
      setState(() {
        imageFile2 = File(f.files.single.path!);
      });
    }
  }

  Future<void> onGenerate() async {
    try {
      await dotenv.load(fileName: 'assets/.env');
      String? apiKey = dotenv.env['API_KEY'];
      if (apiKey == null) {
        print('API_KEY none');
        return;
      }
      if (imageFile1 == null) {
        print('image is null');
        return;
      }
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final bytes1 = await imageFile1!.readAsBytes();
      final bytes2 = await imageFile2!.readAsBytes();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', bytes1),
          DataPart('image/png', bytes2),
        ])
      ];
      final res = await model.generateContent(content);
      setState(() {
        response = res.text ?? 'none';
      });
    } catch (e) {
      print('${e}');
    }
  }

  Widget myButton({IconData? icon, Function()? onPressed}) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 28,
      color: Colors.white,
      onPressed: onPressed,
    );
  }

  Widget myText(String text, {TextStyle? style, double? height}) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFF404040),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: style, maxLines: 4, softWrap: true, overflow: TextOverflow.ellipsis, textAlign: TextAlign.left),
    );
  }
}
