// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAttendanceRecordCollection on Isar {
  IsarCollection<AttendanceRecord> get attendanceRecords => this.collection();
}

const AttendanceRecordSchema = CollectionSchema(
  name: r'AttendanceRecord',
  id: 3264724351450497341,
  properties: {
    r'firstName': PropertySchema(
      id: 0,
      name: r'firstName',
      type: IsarType.string,
    ),
    r'isLate': PropertySchema(
      id: 1,
      name: r'isLate',
      type: IsarType.bool,
    ),
    r'isPresent': PropertySchema(
      id: 2,
      name: r'isPresent',
      type: IsarType.bool,
    ),
    r'lastName': PropertySchema(
      id: 3,
      name: r'lastName',
      type: IsarType.string,
    ),
    r'lrn': PropertySchema(
      id: 4,
      name: r'lrn',
      type: IsarType.string,
    ),
    r'studentSection': PropertySchema(
      id: 5,
      name: r'studentSection',
      type: IsarType.string,
    ),
    r'studentYear': PropertySchema(
      id: 6,
      name: r'studentYear',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 7,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _attendanceRecordEstimateSize,
  serialize: _attendanceRecordSerialize,
  deserialize: _attendanceRecordDeserialize,
  deserializeProp: _attendanceRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'lrn': IndexSchema(
      id: -6381483324607427732,
      name: r'lrn',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lrn',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _attendanceRecordGetId,
  getLinks: _attendanceRecordGetLinks,
  attach: _attendanceRecordAttach,
  version: '3.1.0+1',
);

int _attendanceRecordEstimateSize(
  AttendanceRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.firstName.length * 3;
  bytesCount += 3 + object.lastName.length * 3;
  bytesCount += 3 + object.lrn.length * 3;
  bytesCount += 3 + object.studentSection.length * 3;
  bytesCount += 3 + object.studentYear.length * 3;
  return bytesCount;
}

void _attendanceRecordSerialize(
  AttendanceRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.firstName);
  writer.writeBool(offsets[1], object.isLate);
  writer.writeBool(offsets[2], object.isPresent);
  writer.writeString(offsets[3], object.lastName);
  writer.writeString(offsets[4], object.lrn);
  writer.writeString(offsets[5], object.studentSection);
  writer.writeString(offsets[6], object.studentYear);
  writer.writeDateTime(offsets[7], object.timestamp);
}

AttendanceRecord _attendanceRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AttendanceRecord();
  object.firstName = reader.readString(offsets[0]);
  object.id = id;
  object.isLate = reader.readBool(offsets[1]);
  object.isPresent = reader.readBool(offsets[2]);
  object.lastName = reader.readString(offsets[3]);
  object.lrn = reader.readString(offsets[4]);
  object.studentSection = reader.readString(offsets[5]);
  object.studentYear = reader.readString(offsets[6]);
  object.timestamp = reader.readDateTime(offsets[7]);
  return object;
}

P _attendanceRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _attendanceRecordGetId(AttendanceRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _attendanceRecordGetLinks(AttendanceRecord object) {
  return [];
}

void _attendanceRecordAttach(
    IsarCollection<dynamic> col, Id id, AttendanceRecord object) {
  object.id = id;
}

extension AttendanceRecordQueryWhereSort
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QWhere> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension AttendanceRecordQueryWhere
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QWhereClause> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      lrnEqualTo(String lrn) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lrn',
        value: [lrn],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      lrnNotEqualTo(String lrn) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lrn',
              lower: [],
              upper: [lrn],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lrn',
              lower: [lrn],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lrn',
              lower: [lrn],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lrn',
              lower: [],
              upper: [lrn],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AttendanceRecordQueryFilter
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firstName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firstName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      firstNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firstName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      isLateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLate',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      isPresentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPresent',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lastNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lrn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lrn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lrn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lrn',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      lrnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lrn',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentSection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studentSection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studentSection',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentSection',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentSectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studentSection',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentYear',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studentYear',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studentYear',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentYear',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      studentYearIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studentYear',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AttendanceRecordQueryObject
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {}

extension AttendanceRecordQueryLinks
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {}

extension AttendanceRecordQuerySortBy
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QSortBy> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByFirstName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByFirstNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByIsLate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLate', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByIsLateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLate', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByIsPresent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPresent', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByIsPresentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPresent', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByLastName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByLastNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> sortByLrn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lrn', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByLrnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lrn', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByStudentSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentSection', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByStudentSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentSection', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByStudentYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentYear', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByStudentYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentYear', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension AttendanceRecordQuerySortThenBy
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QSortThenBy> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByFirstName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByFirstNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIsLate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLate', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIsLateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLate', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIsPresent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPresent', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIsPresentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPresent', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByLastName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByLastNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastName', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> thenByLrn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lrn', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByLrnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lrn', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByStudentSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentSection', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByStudentSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentSection', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByStudentYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentYear', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByStudentYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentYear', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension AttendanceRecordQueryWhereDistinct
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByFirstName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByIsLate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLate');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByIsPresent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPresent');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByLastName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct> distinctByLrn(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lrn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByStudentSection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studentSection',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByStudentYear({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studentYear', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension AttendanceRecordQueryProperty
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QQueryProperty> {
  QueryBuilder<AttendanceRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AttendanceRecord, String, QQueryOperations> firstNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstName');
    });
  }

  QueryBuilder<AttendanceRecord, bool, QQueryOperations> isLateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLate');
    });
  }

  QueryBuilder<AttendanceRecord, bool, QQueryOperations> isPresentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPresent');
    });
  }

  QueryBuilder<AttendanceRecord, String, QQueryOperations> lastNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastName');
    });
  }

  QueryBuilder<AttendanceRecord, String, QQueryOperations> lrnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lrn');
    });
  }

  QueryBuilder<AttendanceRecord, String, QQueryOperations>
      studentSectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentSection');
    });
  }

  QueryBuilder<AttendanceRecord, String, QQueryOperations>
      studentYearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentYear');
    });
  }

  QueryBuilder<AttendanceRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
