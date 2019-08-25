// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_livestream_ml_vision/firebase_livestream_ml_vision.dart';
import 'package:flutter_speech_recognition/flutter_speech_recognition.dart';
import 'package:flutter_text_to_speech/flutter_text_to_speech.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:testproj/detector_painters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


void main() => runApp(MaterialApp(home: _MyHomePage()));

class _MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  FirebaseVision _vision;
  List<ImageLabel> _scanResults;
  List<VisionEdgeImageLabel> _visionEdgeScanResults;
  VoiceController textToSpeech;
  RecognitionController speechRecognition;
  bool isListening = false;
  TextEditingController _controllerText = new TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _testSignInWithGoogle()
    .then((user) => print(user)).catchError((e) => print(e));
    _initializeCamera();
    _initSpeechRecognition();
    _initTextToSpeech();
  }

  Future<String> _testSignInWithGoogle() async {
    
    FirebaseUser user;
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    user = await _auth.signInWithCredential(credential);
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInWithGoogle succeeded: $user';
  }


  void _initializeCamera() async {
    List<FirebaseCameraDescription> cameras = await camerasAvailable();
    _vision = FirebaseVision(cameras[0], ResolutionSetting.high);
    _vision.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future _cancelRecognitionHandler() async {
    speechRecognition.stop().then((onValue) {
      setState(() {
        isListening = false;
      });
    });
    if (_controllerText.text != "") {
      _requestChatBot(_controllerText.text, "");
    }
    _controllerText.text = "";
  }

  Future _cancelRecognition() async {
    speechRecognition.stop().then((onValue) {
      setState(() {
        isListening = false;
      });
    });
    _controllerText.text = "";
  }

  Future _stopRecognition() async {
    speechRecognition.stop().then((onValue) {
      setState(() {
        isListening = false;
      });
    });
  }

  Future _startRecognition() async {
    setState(() {
      isListening = true;
    });
    speechRecognition.recognize().listen((onData) {
      _controllerText.text = onData;
    }, onDone: () {
      _requestChatBot(_controllerText.text, "");
      _controllerText.text = "";
      speechRecognition.stop().then((onValue) {
        setState(() {
          isListening = false;
        });
      });
    });
  }

  _requestChatBot(String text, String uid) {
    if (text == "") {
      _controllerText.clear();
    } else {
      _controllerText.clear();
      // final HttpsCallable dialogflow = CloudFunctions.instance
      //     .getHttpsCallable(functionName: 'detectIntent');
      // dialogflow.call(
      //   <String, dynamic>{
      //     'projectID': 'stepify-solutions',
      //     'sessionID': uid,
      //     'query': text,
      //     'languageCode': 'en'
      //   },
      // ).then((result) {
      //   if (result.data[0]['queryResult']['action'] != "image.identify") {
      //     textToSpeech.speak(result.data[0]['queryResult']['fulfillmentText'] ??
      //         "An error occurred, please try again!");
      //   } else if (result.data[0]['queryResult']['intent']['displayName'] ==
      //       "image.identify") {
      //     _speakObjects();
      //   } else if (result.data[0]['queryResult']['intent']['displayName'] ==
      //       "terrain.identify") {
      //     _speakTerrain();
      //   }
      // });
    }
  }

  _initTextToSpeech() async {
    textToSpeech = FlutterTextToSpeech.instance.voiceController();
    await textToSpeech.init();
  }

  _initSpeechRecognition() async {
    speechRecognition = FlutterSpeechRecognition.instance.voiceController();
    await speechRecognition.init();
  }

 _speakObjects() {
    _vision.addImageLabeler().then((onValue){
        onValue.listen((onData){
          setState(() {
              _scanResults = onData;
            });
        });
      });
    if (_scanResults is! List<ImageLabel>) {
      defaultTargetPlatform == TargetPlatform.iOS &&
              MediaQuery.of(context).accessibleNavigation
          ? textToSpeech.speak("")
          : textToSpeech.speak("");
    } else {
      String result = '';
      for (ImageLabel label in _scanResults.take(5)) {
        result = result + ", " + label.text;
      }
      defaultTargetPlatform == TargetPlatform.iOS &&
              MediaQuery.of(context).accessibleNavigation
          ? textToSpeech.speak("Hello")
          : textToSpeech.speak("Hello");
    }
  }

  _speakTerrain() {
    _vision.addVisionEdgeImageLabeler('potholes', ModelLocation.Local).then((onValue){
        onValue.listen((onData){
          setState(() {
              _visionEdgeScanResults = onData;
            });
        });
      });
    if (_visionEdgeScanResults is! List<VisionEdgeImageLabel>) {
      defaultTargetPlatform == TargetPlatform.iOS &&
              MediaQuery.of(context).accessibleNavigation
          ? textToSpeech.speak("")
          : textToSpeech.speak("");
    } else {
      for (VisionEdgeImageLabel label in _visionEdgeScanResults) {
        if (label.text == 'Asphalt') {
          defaultTargetPlatform == TargetPlatform.iOS &&
                  MediaQuery.of(context).accessibleNavigation
              ? textToSpeech.speak("")
              : textToSpeech.speak("");
        } else {
          defaultTargetPlatform == TargetPlatform.iOS &&
                  MediaQuery.of(context).accessibleNavigation
              ? textToSpeech.speak("")
              : textToSpeech.speak("");
        }
      }
    }
  }

  _buildNothing() {
    return Container();
  }

  _buildComposer({double width}) {
    return Container(
        width: width,
        color: Colors.grey.shade200,
        child: new Row(
          children: <Widget>[
            Flexible(
              child: new Padding(
                  padding: new EdgeInsets.all(8.0),
                  child: Semantics(
                    child: new TextField(
                      controller: _controllerText,
                      decoration: InputDecoration.collapsed(hintText: ""),
                      onTap: _stopRecognition,
                      onSubmitted: (String out) {
                        _requestChatBot(
                            _controllerText.text, 'uid' ?? "");
                      },
                    ),
                    textField: true,
                    label: "",
                  )),
            ),
            new Semantics(
              child: new IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: () {
                  _controllerText.text = "";
                  _cancelRecognition();
                },
              ),
              liveRegion: false,
              button: true,
              label: "",
            )
          ],
        ));
  }

  _captureControlRowWidget(var size) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            width: double.infinity,
            height: 120.0,
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Semantics(
                        child: FloatingActionButton(
                          child: new Icon(Icons.accessibility_new),
                          heroTag: "speakObjects",
                          onPressed: _speakObjects,
                          backgroundColor: Colors.blue,
                        ),
                        liveRegion: false,
                        button: true,
                        label: "",
                      ),
                      Semantics(
                        child: FloatingActionButton(
                          child: new Icon(Icons.accessible),
                          heroTag: "detectTerrain",
                          onPressed: _speakTerrain,
                          backgroundColor: Colors.blue,
                        ),
                        liveRegion: false,
                        button: true,
                        label: "",
                      ),
                      !isListening
                          ? Semantics(
                              child: FloatingActionButton(
                                child: new Icon(Icons.mic),
                                heroTag: "mic",
                                onPressed: _startRecognition,
                                backgroundColor: Colors.blue,
                              ),
                              liveRegion: false,
                              button: true,
                              label: "",
                            )
                          : Semantics(
                              child: FloatingActionButton(
                                child: new Icon(Icons.mic_off),
                                heroTag: "mic",
                                onPressed: isListening
                                    ? _cancelRecognitionHandler
                                    : null,
                                backgroundColor: Colors.redAccent,
                              ),
                              liveRegion: false,
                              button: true,
                              label: "",
                            ),
                    ])
              ],
            )));
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('No results!');

    if (_scanResults == null ||
        _vision == null ||
        !_vision.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _vision.value.previewSize.height,
      _vision.value.previewSize.width,
    );

    if (_scanResults is! List<ImageLabel>) return noResultsText;
    painter = LabelDetectorPainter(imageSize, _scanResults);

    return CustomPaint(
      painter: painter,
    );
  }

  Widget _buildImage() {
    final size = MediaQuery.of(context).size;
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _vision == null
          ? const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30.0,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                FirebaseCameraPreview(_vision),
                _buildResults(),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                        width: double.infinity,
                        height: 180.0,
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                isListening || _controllerText.text != ""
                                    ? _buildComposer(width: size.width - 40)
                                    : _buildNothing(),
                              ],
                            ),
                          ],
                        ))),
                  _captureControlRowWidget(size),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: _buildImage(),
    );
  }

  @override
  void dispose() {
    _vision.dispose();
    super.dispose();
  }

}