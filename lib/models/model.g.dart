// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Model _$ModelFromJson(Map<String, dynamic> json) => Model(
  id: json['id'] as String,
  name: json['name'] as String,
  displayName: json['displayName'] as String,
  provider: json['provider'] as String,
);

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'displayName': instance.displayName,
  'provider': instance.provider,
};
