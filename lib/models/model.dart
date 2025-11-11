import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Model {
  final String id;
  final String name;
  final String displayName;
  final String provider;

  Model({
    required this.id,
    required this.name,
    required this.displayName,
    required this.provider,
  });

  factory Model.fromJson(Map<String, dynamic> json) =>
      _$ModelFromJson(json);

  Map<String, dynamic> toJson() => _$ModelToJson(this);
}

extension ModelCopyWith on Model {
  Model copyWith({
    String? id,
    String? name,
    String? displayName,
    String? provider,
  }) {
    return Model(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
    );
  }
}