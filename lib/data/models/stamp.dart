// lib/data/models/stamp.dart
// Perangko digital yang bisa dikoleksi (F08).

import '../../core/utils/json_utils.dart';

class Stamp {
  const Stamp({
    required this.id,
    required this.title,
    required this.trivia,
    this.image,
  });

  final String id;
  final String title;
  final String trivia;
  final String? image;

  factory Stamp.fromJson(Map<String, dynamic> json) => Stamp(
        id: readRequired<String>(json, 'id', context: 'stamp'),
        title: readRequired<String>(json, 'title', context: 'stamp'),
        trivia: readRequired<String>(json, 'trivia', context: 'stamp'),
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'trivia': trivia,
        'image': image,
      };

  Stamp copyWith({String? id, String? title, String? trivia, String? image}) =>
      Stamp(
        id: id ?? this.id,
        title: title ?? this.title,
        trivia: trivia ?? this.trivia,
        image: image ?? this.image,
      );

  @override
  bool operator ==(Object other) =>
      other is Stamp &&
      other.id == id &&
      other.title == title &&
      other.trivia == trivia &&
      other.image == image;

  @override
  int get hashCode => Object.hash(id, title, trivia, image);
}
