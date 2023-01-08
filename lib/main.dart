import 'package:flutter/material.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:contacts_service/contacts_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  SpeechRecognition _speechRecognition;
  bool _isAvailable = false;
  bool _isListening = false;

  String resultText = "";
}
  class ContactsPage extends StatefulWidget {
    @override
    _ContactsPageState createState() => _ContactsPageState();
  }

  class _ContactsPageState extends State<ContactsPage> {
    Iterable<Contact> _contacts=[];

    @override
    void initState() {
      super.initState();
      _getContacts();
    }

    void _getContacts() async {
      _contacts = await ContactsService.getContacts();
      setState(() {});
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: _contacts == null
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  Contact contact = _contacts.elementAt(index);
                  return ListTile(
                    title: Text(contact.displayName ?? 'unknown'),
                  );
                },
              ),
      );
    }
  }

  class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();
    initSpeechRecognizer();
  }

  void initSpeechRecognizer() {
    _speechRecognition = SpeechRecognition();

    _speechRecognition.setAvailabilityHandler(
      (bool result) => setState(() => _isAvailable = result),
    );

    _speechRecognition.setRecognitionStartedHandler(
      () => setState(() => _isListening = true),
    );

    _speechRecognition.setRecognitionResultHandler(
      (String speech) => setState(() => resultText = speech),
    );

    _speechRecognition.setRecognitionCompleteHandler(
      () => setState(() => _isListening = false),
    );

    _speechRecognition.activate().then(
          (result) => setState(() => _isAvailable = result),
        );
    _speechRecognition.listen(locale: "en_US", listenFor: Duration.infinite).then((result) {
    if (resultText == "emergency") {
      triggerEmergencyResponse();
    }
  });    
  }

  void triggerEmergencyResponse() async {
  // Get the device's current location
  var currentLocation = await getCurrentLocation();

  // Get the phone numbers of the selected contacts
  List<String> recipients = _selectedContacts.map((contact) => contact.phones.first.value).toList();

  // Send an SMS message with the location to the selected contacts
  String _result = await FlutterSms.sendSMS(
    message: "I am in distress at this location: " + currentLocation,
    recipients: recipients,
  );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Voice Recognition App'),
        ),
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FloatingActionButton(
                    child: Icon(Icons.cancel),
                    mini: true,
                    backgroundColor: Colors.deepOrange,
                    onPressed: () {
                      if (_isListening)
                        _speechRecognition.cancel().then(
                              (result) => setState(() {
                                _isListening = result;
                                resultText = "";
                              }),
                            );
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter trigger word",
                    ),
                    onChanged: (value) {
                      // Update the trigger word when the user types in the text field
                      setState(() {
                        resultText = value;
                      });
                    },
                  )
                  RaisedButton(
                    onPressed: () {
                      // Save the trigger word and start listening for it
                      setState(() {
                        _speechRecognition.listen(locale: "en_US", listenFor: Duration.infinite).then((result) {
                          if (resultText == result) {
                            triggerEmergencyResponse();
                          }
                        });
                      });
                    },
                    child: Text("Save"),
                  )

                  FloatingActionButton(
                    child: Icon(Icons.mic),
                    onPressed: () {
                      if (_isAvailable && !_isListening)
                        _speechRecognition
                            .listen(locale: "en_US")
                            .then((result) => print('$result'));
                    },
                    backgroundColor: Colors.pink,
                  ),
                  FloatingActionButton(
                    child: Icon(Icons.stop),
                    mini: true,
                    backgroundColor: Colors.deepPurple,
                    onPressed: () {
                          if (_isListening)
                              _speechRecognition.stop().then(
                                    (result) => setState(() => _isListening = result),
                                  );
                          },
                  ),
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent[100],
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                child: Text(
                  resultText,
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(
                onPressed: resultText == "emergency" ? triggerEmergencyResponse : null,
                child: Text("Send Emergency Message"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

}
