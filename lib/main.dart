import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:indonesia_english_translation/about_me.dart';
import 'package:indonesia_english_translation/validator.dart';
import 'package:translator/translator.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TranslatorHome(),
    );
  }
}
class TranslatorHome extends StatefulWidget{
  @override
  _TranslatorHomeState createState() => _TranslatorHomeState();
}

class _TranslatorHomeState extends State<TranslatorHome>  with SingleTickerProviderStateMixin{
  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(Icons.person),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>AboutMe()));
              },
            ),
          ),
        ],
        title: Text('Translate to english'),
        bottom: TabBar(
          indicatorColor: Colors.red,
          controller: _tabController,
          tabs: <Tab>[
            Tab(icon: Icon(Icons.translate),),
            Tab(icon: Icon(Icons.picture_in_picture),)
          ],
        ),
      ),
      body: GestureDetector(
        onTap: (){
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            TextTranslation(),
            TranslateImage(),
          ],
        ),
      ),
    );
  }
}
class TextTranslation extends StatefulWidget {
  @override
  _TextTranslationState createState() => _TextTranslationState();
}

class _TextTranslationState extends State<TextTranslation> with Validation {
  GoogleTranslator translator = new GoogleTranslator();

  TextEditingController _controller = TextEditingController();

  String out = '';

  bool _isWaiting = false;

  final _globalKey = GlobalKey<FormState>();

  void trans()async{
    await translator.translate(_controller.text, to: 'en').then((output){
      setState(() {
        out = output;
        _isWaiting = true;
      });
      if(_controller.text != null){
        _isWaiting = false;
      }else{
        print('Tidak Boleh kosong');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _globalKey,
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: SelectableText('You Can Translate Any Languages to English'),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30,left: 10,right: 10),
                child: TextFormField(
                  validator: field,
                  maxLines: null,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Dont't let this field on the blank",
                    labelText: "Insert Text",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),

                  ),
                ),
              ),
              RaisedButton(
                color: Colors.blue,
                child: Text('Translate',style: TextStyle(color: Colors.white),),
                onPressed: (){
                  trans();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              Padding(
                padding: EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 10),
                child: _isWaiting?CircularProgressIndicator():
                SelectableText(out.toString(),style:TextStyle(fontSize: 20),textAlign: TextAlign.justify,),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TranslateImage extends StatefulWidget {
  @override
  _TranslateImageState createState() => _TranslateImageState();
}

class _TranslateImageState extends State<TranslateImage> {
  File pickedImage;
  String wordTxt = '';
  String imageTrans = '';

  bool _isImageLoaded = false;
  bool showTranslator = false;

  GoogleTranslator translator = new GoogleTranslator();

  Future pickImage () async{
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc){
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text('From Gallery'),
                  onTap: ()async{
                    var tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);
                    pickedImage = tempStore;
                    _isImageLoaded = true;
                    Navigator.pop(context);
                    wordTxt = '';
                    imageTrans = '';
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera),
                  title: Text('From Camera'),
                  onTap: ()async{
                    var tempCamera = await ImagePicker.pickImage(source: ImageSource.camera);
                    pickedImage = tempCamera;
                    _isImageLoaded = true;
                    Navigator.pop(context);
                    wordTxt = '';
                    imageTrans = '';
                  },
                )
              ],
            ),
          );
        }
    );

  }

  Future readText()async{
    final FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    VisionText visionText = await textRecognizer.processImage(ourImage);

    for (TextBlock block in visionText.blocks){
      for (TextLine line in block.lines){
        for (TextElement word in line.elements){
          print(word.text);
          setState(() {
            wordTxt += word.text + ' ';
            showTranslator = true;
          });
        }
      }
    }
  }
  void translateImage ()async{
    await translator.translate(wordTxt, to: 'en').then((res){
      setState(() {
        imageTrans = res;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _isImageLoaded ? Center(
            child: Container(
              padding: EdgeInsets.only(top: 10),
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(pickedImage),fit: BoxFit.fill
                ),
              ),
            ),
          ):Text('No Image Selected'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RaisedButton(
                  child: Text('Pick Image'),
                  onPressed: pickImage,
                ),
                SizedBox(height: 10,),
                RaisedButton(
                  child: Text('Read Text on Image'),
                  onPressed: readText,
                ),

              ],
            ),
          ),
          showTranslator?RaisedButton(
            child: Text('Translate Text to english'),
            onPressed: translateImage,
          ):Container(),
          SizedBox(height: 20,),
          Text('Original Text',style: TextStyle(color: Colors.grey),),
          Padding(
            padding: EdgeInsets.only(left: 20,right: 20,top: 10),
            child: SelectableText(wordTxt,textAlign: TextAlign.justify,),
          ),
          SizedBox(height: 20,),
          Text('Translation to english',style: TextStyle(color: Colors.grey),),
          Padding(
            padding: EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 20),
            child: SelectableText(imageTrans,textAlign: TextAlign.justify,),
          )
        ],
      ),
    );
  }
}


