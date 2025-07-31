// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_records.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncRecordsCollection on Isar {
  IsarCollection<SyncRecords> get syncRecords => this.collection();
}

const SyncRecordsSchema = CollectionSchema(
  name: r'SyncRecords',
  id: 8331773863851059921,
  properties: {
    r'deviceID': PropertySchema(
      id: 0,
      name: r'deviceID',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 1,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _syncRecordsEstimateSize,
  serialize: _syncRecordsSerialize,
  deserialize: _syncRecordsDeserialize,
  deserializeProp: _syncRecordsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _syncRecordsGetId,
  getLinks: _syncRecordsGetLinks,
  attach: _syncRecordsAttach,
  version: '3.1.0+1',
);

int _syncRecordsEstimateSize(
  SyncRecords object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceID.length * 3;
  return bytesCount;
}

void _syncRecordsSerialize(
  SyncRecords object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deviceID);
  writer.writeDateTime(offsets[1], object.timestamp);
}

SyncRecords _syncRecordsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncRecords();
  object.deviceID = reader.readString(offsets[0]);
  object.id = id;
  object.timestamp = reader.readDateTime(offsets[1]);
  return object;
}

P _syncRecordsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncRecordsGetId(SyncRecords object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncRecordsGetLinks(SyncRecords object) {
  return [];
}

void _syncRecordsAttach(
    IsarCollection<dynamic> col, Id id, SyncRecords object) {
  object.id = id;
}

extension SyncRecordsQueryWhereSort
    on QueryBuilder<SyncRecords, SyncRecords, QWhere> {
  QueryBuilder<SyncRecords, SyncRecords, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncRecordsQueryWhere
    on QueryBuilder<SyncRecords, SyncRecords, QWhereClause> {
  QueryBuilder<SyncRecords, SyncRecords, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterWhereClause> idBetween(
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
}

extension SyncRecordsQueryFilter
    on QueryBuilder<SyncRecords, SyncRecords, QFilterCondition> {
  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> deviceIDEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> deviceIDBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> deviceIDMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceID',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceID',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      deviceIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceID',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
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

  QueryBuilder<SyncRecords, SyncRecords, QAfterFilterCondition>
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

extension SyncRecordsQueryObject
    on QueryBuilder<SyncRecords, SyncRecords, QFilterCondition> {}

extension SyncRecordsQueryLinks
    on QueryBuilder<SyncRecords, SyncRecords, QFilterCondition> {}

extension SyncRecordsQuerySortBy
    on QueryBuilder<SyncRecords, SyncRecords, QSortBy> {
  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> sortByDeviceID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceID', Sort.asc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> sortByDeviceIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceID', Sort.desc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension SyncRecordsQuerySortThenBy
    on QueryBuilder<SyncRecords, SyncRecords, QSortThenBy> {
  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenByDeviceID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceID', Sort.asc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenByDeviceIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceID', Sort.desc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension SyncRecordsQueryWhereDistinct
    on QueryBuilder<SyncRecords, SyncRecords, QDistinct> {
  QueryBuilder<SyncRecords, SyncRecords, QDistinct> distinctByDeviceID(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceID', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncRecords, SyncRecords, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension SyncRecordsQueryProperty
    on QueryBuilder<SyncRecords, SyncRecords, QQueryProperty> {
  QueryBuilder<SyncRecords, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncRecords, String, QQueryOperations> deviceIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceID');
    });
  }

  QueryBuilder<SyncRecords, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
