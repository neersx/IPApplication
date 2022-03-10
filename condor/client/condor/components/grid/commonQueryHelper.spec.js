describe('inprotech.components.grid.commonQueryHelper', function() {
    'use strict';

    var helper;
    var columnFilterHelper;
    beforeEach(function() {
        module('inprotech.components.grid');
        module(function($provide) {
            columnFilterHelper = {buildQueryParams: jasmine.createSpy()};
            $provide.value('columnFilterHelper', columnFilterHelper);
        });
    });


    beforeEach(inject(function(commonQueryHelper) {
        helper = commonQueryHelper;
    }));

    describe('buildQueryParams', function() {
        it('should build paging params', function() {
            var result = helper.buildQueryParams({
                data: {
                    skip: 1,
                    take: 2
                }
            });

            expect(result).toEqual({
                skip: 1,
                take: 2
            });
        });

        it('should build sorting params', function() {
            var result = helper.buildQueryParams({
                data: {
                    sort: [{
                        field: 'a',
                        dir: 'asc'
                    }]
                }
            });

            expect(result).toEqual({
                sortBy: 'a',
                sortDir: 'asc'
            });
        });

        it('should build query params', function() {
            var gridOptions = {};
            var evt = {data: {
                    filter: []
                }};
            helper.buildQueryParams(evt, gridOptions);

            expect(columnFilterHelper.buildQueryParams).toHaveBeenCalledWith(evt.data.filter, gridOptions);
        });
    });
});
