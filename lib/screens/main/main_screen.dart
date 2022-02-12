import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

import '../../realm_db.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'components/list_of_notes.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.db}) : super(key: key);

  final RealmDB db;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final RealmApp app = RealmApp();
  late String userId;
  late SearchBar searchBar;
  CarouselController carouselController = CarouselController();
  TextEditingController searchController = TextEditingController();
  List<String> paneQueries = [''];
  int currPaneIndex = 0;

  _MyHomePageState() {
    searchBar = SearchBar(
        inBar: false,
        setState: setState,
        onChanged: _onSearchChanged,
        showClearButton: false,
        clearOnSubmit: false,
        controller: searchController,
        buildDefaultAppBar: buildAppBar);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(children: [
        const Text('Fleeting Notes', style: TextStyle(fontSize: 16)),
        Text(paneQueries[currPaneIndex], style: const TextStyle(fontSize: 12))
      ]),
      actions: <Widget>[
        searchBar.getSearchAction(context),
      ],
    );
  }

  void _addNewPane(query) {
    setState(() {
      currPaneIndex++;
      paneQueries = paneQueries.sublist(0, currPaneIndex);
      paneQueries.add(query);
    });
    carouselController.animateToPage(currPaneIndex);
  }

  void _onSearchChanged(query) {
    setState(() {
      paneQueries[currPaneIndex] = query;
    });
  }

  void _onPageChanged(int index, CarouselPageChangedReason reason) {
    setState(() {
      currPaneIndex = index;
    });
    searchController.text = paneQueries[currPaneIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        mobile: ListOfNotes(query: '', db: widget.db),
        tablet: Row(
          children: [
            Expanded(
              flex: 6,
              child: ListOfNotes(query: '', db: widget.db),
            ),
            Expanded(
              flex: 9,
              child: NoteScreen(
                note: Note(
                  id: '0123',
                  title: 'i am title',
                  content: 'i am content',
                ),
                db: widget.db,
              ),
            ),
          ],
        ),
        desktop: Row(
          children: [
            Expanded(
              flex: 6,
              child: ListOfNotes(query: '', db: widget.db),
            ),
            Expanded(
                flex: 9,
                child: NoteScreen(
                  note: Note(
                      id: '123', title: 'i am title', content: 'i am content'),
                  db: widget.db,
                )),
          ],
        ),
      ),
    );
  }
}
