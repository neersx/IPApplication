describe('inprotech.processing.policing.PolicingQueueService', function() {
    'use strict';

    var service;

    beforeEach(function() {
        module('inprotech.processing.policing');
    });

    beforeEach(inject(function(policingQueueFilterService) {
        service = policingQueueFilterService;
    }));


    var getColumn = function(fieldName, data) {
        return {
            field: fieldName,
            filterable: {
                dataSource: {
                    data: function() {
                        return data;
                    }
                }
            }
        };
    };

    describe('policing queue filter service', function() {
        it('should return new data as is if no filters defined', function() {
            var column = getColumn('field1', []);
            var oldFilters = [{}];

            var newData = [{}, {}];
            var result = service.getFilters(column, oldFilters, newData);

            expect(result).toEqual(newData);
        });

        it('should return stale filter', function() {
            var column = getColumn('field1', [{
                code: 'B',
                description: 'B description'
            }, {
                code: 'D',
                description: 'D description'
            }]);

            var oldFilters = [{
                field: 'field1',
                value: 'B,D'
            }];

            var newData = [{
                code: 'A',
                description: 'A Description'
            }, {
                code: 'C',
                description: 'C Description'
            }];

            var result = service.getFilters(column, oldFilters, newData);

            expect(result.length).toEqual(4);
            expect(_.last(result).code).toEqual('D');
            expect(_.last(result).description).toEqual('D description');
        });
    });
});
