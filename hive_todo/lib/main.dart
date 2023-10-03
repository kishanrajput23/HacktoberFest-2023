import 'dart:math';
import 'package:flutter/services.dart';
import 'package:hive_todo/onboardingScreen.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_todo/viewItem.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzs;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

int initScreen = 0;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  initScreen = prefs.getInt("initScreen") ?? 0;
  await prefs.setInt("initScreen", 1);
  print(initScreen);
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('todo_hives');
  _MyHomePageState._notificationService.initNotification();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'aiTODO',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: initScreen == 0 ? OnboardingScreen() : MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _jamController = TextEditingController();
  final TextEditingController _menitController = TextEditingController();
  String _name = '';

  Future<void> getName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('nameFixed');
    setState(() {
      _name = name!;
    });
  }

  int setHour = 0;
  int setMinute = 0;
  static final _MyHomePageState _notificationService =
      _MyHomePageState._internal();

  factory _MyHomePageState() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  _MyHomePageState._internal();

  Future<void> initNotification() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ios initialization
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    // the initialization settings are initialized after they are setted
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  //get hour of time now

  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzs.TZDateTime.now(tzs.local).add(Duration(
        hours: setHour,
        minutes: setMinute,
      )), //schedule the notification to show after 2 seconds.
      const NotificationDetails(
        // Android details
        android: AndroidNotificationDetails('main_channel', 'Main Channel',
            channelDescription: "ashwin",
            importance: Importance.max,
            priority: Priority.max),
        // iOS details
        iOS: IOSNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),

      // Type of time interpretation
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle:
          true, // To show notification even when the app is closed
    );
  }

  List<Map<String, dynamic>> _items = [];
  final _todoBox = Hive.box('todo_hives');
  String dateNow = //date time now format EEEE
      "${DateFormat('EEEE').format(DateTime.now())}, ${DateFormat('dd MMMM yyyy').format(DateTime.now())}";

  void _refreshItems() {
    final data = _todoBox.keys.map((key) {
      final item = _todoBox.get(key);
      return {
        "key": key,
        "activity": item["activity"],
        "description": item["description"],
      };
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _todoBox.add(newItem);
    _refreshItems();
  }

  Future<void> deleteItem(int itemKey) async {
    bool confirm = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Kamu yakin ingin menghapus item ini?'),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                " No ",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                confirm = true;
                Navigator.pop(context);
                _todoBox.delete(itemKey);
                _refreshItems();
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm) {
      print("Confirmed!");
    }
  }

  Future<void> updateItem(int itemKey, Map<String, dynamic> newItem) async {
    await _todoBox.put(itemKey, newItem);
    _refreshItems();
  }

  String activityDetail = '';
  String deskripsiDetail = '';
  Future<void> showDetail(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      final existingItem2 =
          _items.firstWhere((element) => element['key'] == itemKey);
      setState(() {
        activityDetail = existingItem2['activity'];
        deskripsiDetail = existingItem2['description'];
      });
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detail'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  activityDetail,
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  deskripsiDetail,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Ok",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForm(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      _activityController.text = existingItem['activity'];
      _descriptionController.text = existingItem['description'];
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5,
      context: ctx,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLength: 20,
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: "Aktivitas",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
              ),
            ),
            const Center(
              child: Text(
                'Ingatkan dalam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 12.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      maxLength: 2,
                      controller: _jamController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Jam",
                        helperText: 'Dalam Berapa Jam',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12.0,
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      controller: _menitController,
                      decoration: const InputDecoration(
                        labelText: "Menit",
                        helperText: 'Dalam Berapa Menit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (itemKey == null &&
                    _activityController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty &&
                    _jamController.text.isNotEmpty &&
                    _menitController.text.isNotEmpty) {
                  _createItem({
                    "activity": _activityController.text,
                    "description": _descriptionController.text,
                  });
                  setState(() {
                    setHour = int.parse(_jamController.text);
                    setMinute = int.parse(_menitController.text);
                    showNotification(1, _activityController.text,
                        _descriptionController.text);
                  });
                  _activityController.clear();
                  _descriptionController.clear();
                } else {
                  //show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tolong Lengkapi semua data!"),
                    ),
                  );
                }

                if (itemKey != null) {
                  updateItem(itemKey, {
                    "activity": _activityController.text.trim(),
                    "description": _descriptionController.text.trim(),
                  });
                  _activityController.clear();
                  _descriptionController.clear();
                }
                Navigator.of(ctx).pop();
              },
              child: Text(itemKey == null ? "Tambah" : "Update"),
            ),
            const SizedBox(
              height: 12.0,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    getName();
    _refreshItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _showForm(context, null)),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                height: 200,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    const Text(
                      'Hello',
                      style: TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    Positioned(
                      top: 50,
                      child: Text(
                        _name,
                        style: const TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w400,
                            color: Colors.deepPurple),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Text(
                        dateNow,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 24),
                  child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, index) {
                        final currentItem = _items[index];
                        final Color colorRandom = Colors.primaries[
                            Random().nextInt(Colors.primaries.length)];
                        return viewItem(
                            colors: colorRandom,
                            onTap: () =>
                                showDetail(context, currentItem['key']),
                            onEdit: () =>
                                _showForm(context, currentItem['key']),
                            onDelete: () => deleteItem(currentItem['key']),
                            activity: '${_items[index]['activity']}',
                            description: '${_items[index]['description']}');
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
