angular.module('Inprotech.SchemaMapping')
    .constant('dataTypeToInputMap', Object.freeze({
        'String': 'text',
        'AnyUri': 'text',
        'QName': 'text',
        'NormalizedString': 'text',
        'Token': 'text',
        'Language': 'text',
        'NmToken': 'text',
        'Name': 'text',
        'NCName': 'text',
        'Id': 'text',
        'Idref': 'text',
        'Entity': 'text',
        'Notation': 'text',
        'Integer': 'numeric',
        'Long': 'numeric',
        'Int': 'numeric',
        'Short': 'numeric',
        'Byte': 'numeric',
        'Decimal': 'numeric',
        'Float': 'numeric',
        'Double': 'numeric',
        'Duration': 'numeric',
        'NonPositiveInteger': 'numeric',
        'NegativeInteger': 'numeric',
        'NonNegativeInteger': 'numeric',
        'UnsignedLong': 'numeric',
        'UnsignedInt': 'numeric',
        'UnsignedShort': 'numeric',
        'UnsignedByte': 'numeric',
        'PositiveInteger': 'numeric',
        'Date': 'date',
        'Time': 'time',
        'DateTime': 'datetime',
        'GYearMonth': 'date',
        'GYear': 'date',
        'GMonthDay': 'date',
        'GDay': 'date',
        'GMonth': 'date',
        'Boolean': 'boolean',
        'HexBinary': 'notsupported',
        'Base64Binary': 'notsupported'
    }));