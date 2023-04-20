import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription>? cameras;

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras=await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.lightGreen,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output=" ";

  

  @override
  initState(){
    super.initState();
    loadCamera();
    loadmodel();
  }

  loadCamera(){
    cameraController=CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if(!mounted){
        return;
      }
      else{
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage=imageStream;
            runModel();
          });
        });
      }
    });
  }

  runModel() async {
    if(cameraImage!=null){
      var prediction = await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,);
      prediction!.forEach((element) {
        setState(() {
          output=element['label'];
        });
      });
    }
  }

  loadmodel()async{
    await Tflite.loadModel(model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Currency Detection')),
        ),
        body: Column(
          children: [
            Padding(padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height*0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized?
            Container(): 
            AspectRatio(aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
            )
            ),
            ),
            Text(output,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyan),
            )
          ],
        ),
      ),
    );
  }
}
