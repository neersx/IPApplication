describe('inprotech.components.page.lastSearch', function() {
    'use strict';

    var pagerHelperServiceMock;
    beforeEach(function() {
        module('inprotech.components.page');
        module(function($provide) {
            pagerHelperServiceMock = {
                getPageForId: jasmine.createSpy().and.returnValue('abc')
            };
            $provide.value('pagerHelperService', pagerHelperServiceMock);
        });
    });

    it('can set ids', inject(function(LastSearch) {
        var ids = [1, 2];
        var lastSearch = new LastSearch({
            method: angular.noop,
            methodName: 'a',
            args: []
        });
        lastSearch.setAllIds(ids);
        expect(lastSearch.ids).toEqual(ids);
    }));

    it('can get previous defined ids', inject(function(LastSearch) {
        var ids = [1, 2];
        var lastSearch = new LastSearch({
            method: angular.noop,
            methodName: 'a',
            args: []
        });
        lastSearch.setAllIds(ids);
        lastSearch.getAllIds().then(function(data) {
            expect(data).toEqual(ids);
        });
    }));

    it('should run previous search', inject(function(LastSearch, $q) {
        var ids = [1, 2];
        var lastSearch = new LastSearch({
            method: function() {
                return $q.when(ids);
            },
            methodName: 'a',
            args: [{}]
        });
        lastSearch.getAllIds().then(function(data) {
            expect(data).toEqual([1, 2]);
        });
    }));

    it('can get the current page size', inject(function(LastSearch) {
        var lastSearch = new LastSearch({
            method: angular.noop,
            args: [{}, {
                take: 123
            }]
        });

        var result = lastSearch.getPageSize();

        expect(result).toBe(123);
    }));

    describe('Get Page For Id Method', function() {
        it('returns call to pager helper service with the right parameters', inject(function(LastSearch) {
            var lastSearch = new LastSearch({
                method: angular.noop,
                args: [{}, {
                    take: 99
                }]
            });
            var ids = [1];
            lastSearch.setAllIds(ids);
            var result = lastSearch.getPageForId(123);

            expect(pagerHelperServiceMock.getPageForId).toHaveBeenCalledWith(ids, 123, 99);
            expect(result).toEqual('abc');
        }));
    });
});
