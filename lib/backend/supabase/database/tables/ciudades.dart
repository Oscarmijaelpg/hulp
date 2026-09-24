import '../database.dart';

class CiudadesTable extends SupabaseTable<CiudadesRow> {
  @override
  String get tableName => 'ciudades';

  @override
  CiudadesRow createRow(Map<String, dynamic> data) => CiudadesRow(data);
}

class CiudadesRow extends SupabaseDataRow {
  CiudadesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CiudadesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get provinciaId => getField<String>('provincia_id')!;
  set provinciaId(String value) => setField<String>('provincia_id', value);

  String get nombre => getField<String>('nombre')!;
  set nombre(String value) => setField<String>('nombre', value);

  bool? get activo => getField<bool>('activo');
  set activo(bool? value) => setField<bool>('activo', value);

  DateTime? get creadoEn => getField<DateTime>('creado_en');
  set creadoEn(DateTime? value) => setField<DateTime>('creado_en', value);
}
