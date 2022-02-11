import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({Key? key, required this.title, required this.content})
      : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }
}

// class NoteCard extends StatelessWidget {
//   const NoteCard(
//       {Key? key, required this.id, required this.title, required this.content})
//       : super(key: key);

//   final String id;
//   final String title;
//   final String content;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(5),
//         ),
//         child: Container(
//             alignment: Alignment.centerLeft,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 10,
//               vertical: 5,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 TextField(
//                   style: const TextStyle(fontSize: 16),
//                   controller: TextEditingController(text: title),
//                   decoration: const InputDecoration(
//                     hintText: "Title",
//                     border: InputBorder.none,
//                   ),
//                 ),
//                 TextField(
//                   autofocus: true,
//                   controller: TextEditingController(text: content),
//                   minLines: 5,
//                   maxLines: 10,
//                   style: const TextStyle(fontSize: 14),
//                   decoration: const InputDecoration(
//                     hintText: "Note",
//                     border: InputBorder.none,
//                   ),
//                 ),
//                 Text(
//                   id,
//                   style: const TextStyle(
//                       fontSize: 12, fontWeight: FontWeight.w100),
//                   // textAlign: TextAlign.left,
//                 ),
//               ],
//             )));
//   }
// }