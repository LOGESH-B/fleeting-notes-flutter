import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receive_intent/receive_intent.dart' as ri;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'my_app.dart' as base_app;

class MyApp extends base_app.MyApp {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<base_app.MyApp> createState() => _MyAppState();
}

class _MyAppState extends base_app.MyAppState<MyApp> {
  StreamSubscription? noteChangeStream;
  StreamSubscription? homeWidgetSub;
  StreamSubscription? receiveShareSub;
  StreamSubscription? androidIntentSub;

  String? findUrlInText(String sharedText) {
    var r = RegExp(
        r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=,]*)',
        multiLine: true);
    var m = r.firstMatch(sharedText);
    if (m != null) {
      String source = m.group(0)?.trim() ?? '';
      bool validSource = Uri.tryParse(source)?.hasAbsolutePath ?? false;
      if (validSource) {
        return source;
      }
    }
    return null;
  }

  Future<Note?> getNoteFromWidgetUri(Uri uri) async {
    final db = ref.read(dbProvider);
    var noteId = uri.queryParameters['id'];
    if (noteId != null) {
      try {
        Note? note = await db.getNote(noteId);
        return note;
      } catch (e) {
        debugPrint(e.toString());
        return null;
      }
    }
    return null;
  }

  void homeWidgetRefresh(event) async {
    final db = ref.read(dbProvider);
    debugPrint("homeWidgetRefresh");
    var q = SearchQuery(query: '', sortBy: SortOptions.createdDESC, limit: 25);
    var notes = await db.getSearchNotes(q);
    await HomeWidget.saveWidgetData('notes', jsonEncode(notes));
    await HomeWidget.updateWidget(
        name: 'WidgetProvider', iOSName: 'NoteListWidgetExtension');
  }

  @override
  void refreshApp(user) {
    super.refreshApp(user);
    if (Platform.isAndroid || Platform.isIOS) {
      initHomeWidget();
    }
  }

  void initHomeWidget() {
    final db = ref.read(dbProvider);
    homeWidgetRefresh(null);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      noteChangeStream?.cancel();
      db.listenNoteChange(homeWidgetRefresh).then((stream) {
        noteChangeStream = stream;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    void goToNote(Note note, {bool noteExists = false}) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (noteExists) {
          router.goNamed('note', params: {'id': note.id});
        } else {
          router.goNamed('home', queryParams: {
            'title': note.title,
            'content': note.content,
            'source': note.source,
            'note': '', // needed if note is empty
          });
        }
      });
    }

    Note getNoteFromShareText({String title = '', String body = ''}) {
      bool _validURL = Uri.tryParse(body)?.hasAbsolutePath ?? false;
      if (_validURL) {
        return Note.empty(title: title, source: body);
      } else {
        String? source = findUrlInText(body);
        if (source != null) {
          return Note.empty(title: title, content: body, source: source);
        }
        return Note.empty(title: title, content: body);
      }
    }

    void handleAndroidIntent(ri.Intent? intent) {
      List<String> acceptedIntents = [
        'android.intent.action.VOICE_COMMAND',
        'android.intent.action.EDIT',
      ];
      if (intent == null ||
          intent.isNull ||
          !acceptedIntents.contains(intent.action)) return;
      // Validate receivedIntent and warn the user, if it is not correct,
      // but keep in mind it could be `null` or "empty"(`receivedIntent.isNull`).
      String title = (intent.extra?['name'] ?? '').toString();
      String body = (intent.extra?['articleBody'] ?? '').toString();
      String type = (intent.extra?['type'] ?? '').toString();
      var note = getNoteFromShareText(title: title, body: body);

      // ignore: unused_local_variable
      bool openRecordDialog = (type == 'DigitalDocument' ||
              intent.action == 'android.intent.action.VOICE_COMMAND') &&
          note.isEmpty();
      if (openRecordDialog) {
        return router.goNamed('record');
      }
      return goToNote(note);
    }

    void handleHomeWidgetUri(Uri? uri) {
      if (uri != null) {
        getNoteFromWidgetUri(uri).then((note) {
          if (note != null) {
            goToNote(note, noteExists: true);
          } else {
            goToNote(Note.empty());
          }
        });
      }
    }

    void handleMedia(List<SharedMediaFile> files) {
      if (files.isEmpty) return;
      String mediaSource = files.first.path;
      goToNote(Note.empty(source: mediaSource));
    }

    if (Platform.isAndroid) {
      ri.ReceiveIntent.getInitialIntent().then(handleAndroidIntent);
      androidIntentSub = ri.ReceiveIntent.receivedIntentStream
          .listen(handleAndroidIntent, onError: (err) {
        // ignore: avoid_print
        print(err);
      });
    }
    if (Platform.isIOS || Platform.isAndroid) {
      initHomeWidget();
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      receiveShareSub =
          ReceiveSharingIntent.getTextStream().listen((String sharedText) {
        var note = getNoteFromShareText(body: sharedText);
        goToNote(note);
      }, onError: (err) {
        // ignore: avoid_print
        print("getLinkStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then((String? sharedText) {
        if (sharedText != null) {
          var note = getNoteFromShareText(body: sharedText);
          goToNote(note);
        }
      });

      // For sharing or opening media
      ReceiveSharingIntent.getInitialMedia().then(handleMedia);
      ReceiveSharingIntent.getMediaStream().listen(handleMedia);

      // When app is started from widget
      HomeWidget.setAppGroupId('group.com.fleetingnotes');
      HomeWidget.initiallyLaunchedFromHomeWidget().then(handleHomeWidgetUri);

      homeWidgetSub =
          HomeWidget.widgetClicked.listen(handleHomeWidgetUri, onError: (err) {
        // ignore: avoid_print
        print(err);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream?.cancel();
    homeWidgetSub?.cancel();
    receiveShareSub?.cancel();
    androidIntentSub?.cancel();
  }
}
