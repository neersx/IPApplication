describe('Service inprotech.components.picklist.dataunwrapperservice', function() {
    'use strict';

    beforeEach(module('inprotech.components.picklist'));

    var service;
    beforeEach(inject(function(dataunwrapperservice) {
        service = dataunwrapperservice;
    }));

    it('should return data if meta data is absent', function() {
        var data = [{
            a: 'a'
        }];

        var result = service.unwrap(data);
        expect(result).toEqual(data);
    });

    it('should return unwrapped data if metadata is present', function() {
        var data1 = {
            field1: 'A',
            field2: 'B',
            field3: 'C'
        };
        var data2 = {
            field1: 'X',
            field2: 'Y',
            field3: 'Z'
        };
        var data = [data1,
            data2
        ];

        data.$metadata = {
            columns: [{
                field: 'field1',
                key: true
            }, {
                field: 'field2',
                key: false,
                description: true
            }, {
                field: 'field3',
                key: false,
                description: false
            }]
        };

        var result = service.unwrap(data);
        expect(result[0].key).toEqual('A');
        expect(result[0].value).toEqual('B');
        expect(result[0].model).toEqual(data1);

        expect(result[1].key).toEqual('X');
        expect(result[1].value).toEqual('Y');
        expect(result[1].model).toEqual(data2);
    });
});
