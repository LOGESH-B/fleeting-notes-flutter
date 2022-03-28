import 'package:test/test.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

class MockRealmDB extends RealmDB {
  Note newNote(id, title, content, source) {
    String t = DateTime.now().toIso8601String();
    var note = Note(
        id: id, title: title, content: content, timestamp: t, source: source);
    return note;
  }

  @override
  Future<List<Note>> getAllNotes({forceSync = false}) {
    return Future.value([
      newNote('1', 'title', 'content', 'source'),
      newNote('2', '', 'title in content', ''),
      newNote('3', '', 'some text and a [[link]]', ''),
      newNote('4', '', '#tag1 some content #tag2', ''),
    ]);
  }
}

void main() {
  group("getSearchNotes", () {
    var inputsToExpected = {
      'title': ['1', '2'],
      'content': ['1', '2', '4'],
      'source': ['1'],
      '#tag1 #tag2': [],
      '[[link]]': ['3'],
      'title content': [],
    };
    inputsToExpected.forEach((query, noteIds) {
      test('query: $query -> note_ids: $noteIds', () async {
        final db = MockRealmDB();
        List searchedNotes = await db.getSearchNotes(query);
        List searchedIds = searchedNotes.map((e) => e.id).toList();
        expect(searchedIds, noteIds);
      });
    });
  });
  group("getNoteByTitle", () {
    var inputsToExpected = {
      'title': '1',
      'content': null,
      'link': null,
    };
    inputsToExpected.forEach((query, noteId) {
      test('query: $query -> note_id: $noteId', () async {
        final db = MockRealmDB();
        Note? note = await db.getNoteByTitle(query);
        expect(note?.id, noteId);
      });
    });
  });
  group("titleExists", () {
    var inputsToExpected = {
      ['0', 'title']: true,
      ['1', 'title']: false,
      ['69', 'link']: false,
    };
    inputsToExpected.forEach((params, isExists) {
      test('query: $params -> note_id: $isExists', () async {
        final db = MockRealmDB();
        bool? actualIsExists = await db.titleExists(params[0], params[1]);
        expect(actualIsExists, isExists);
      });
    });
  });

  test('getAllLinks', () async {
    final db = MockRealmDB();
    List allLinks = await db.getAllLinks();
    expect(allLinks, ['title', 'link']);
  });

  group("noteExists", () {
    final db = MockRealmDB();
    var inputsToExpected = {
      db.newNote('1', 'title', 'content', 'source'): true,
      db.newNote('1', '', '', ''): true,
      db.newNote('0', 'title', 'content', 'source'): false,
    };
    inputsToExpected.forEach((note, isExists) {
      test('query: $note -> note_id: $isExists', () async {
        bool? actualIsExists = await db.noteExists(note);
        expect(actualIsExists, isExists);
      });
    });
  });
}