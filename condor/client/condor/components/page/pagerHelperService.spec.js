describe('levelUpButton', function() {
    'use strict';

    var service;

    beforeEach(function() {
        module('inprotech.components.page');
        inject(function(pagerHelperService) {
            service = pagerHelperService;
        });

    });

    it('should return index of id on page', function() {
        var ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        var id = 5;
        var pageSize = 10;

        var result = service.getPageForId(ids, id, pageSize);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(4);

        result = service.getPageForId(ids, 99, pageSize);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });

    it('should return page and relative index of an id', function() {
        var ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
        var id = 13;
        var pageSize = 10;
        var result = service.getPageForId(ids, id, pageSize);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(2);

        result = service.getPageForId(ids, 1, 10);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(0);

        result = service.getPageForId(ids, 10, 10);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(9);

        result = service.getPageForId(ids, 11, 10);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(0);

        result = service.getPageForId(ids, 99, 10);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });

    it('should handle string ids', function() {
        //								5						10
        var ids = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];

        var result = service.getPageForId(ids, 'A', 5);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(0);

        result = service.getPageForId(ids, 'E', 5);
        expect(result.page).toEqual(1);
        expect(result.relativeRowIndex).toEqual(4);

        result = service.getPageForId(ids, 'F', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(0);

        result = service.getPageForId(ids, 'G', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(1);

        result = service.getPageForId(ids, 'J', 5);
        expect(result.page).toEqual(2);
        expect(result.relativeRowIndex).toEqual(4);

        result = service.getPageForId(ids, 'N', 5);
        expect(result.page).toEqual(3);
        expect(result.relativeRowIndex).toEqual(3);

        result = service.getPageForId(ids, 'Z', 5);
        expect(result.page).toEqual(-1);
        expect(result.relativeRowIndex).toEqual(-1);
    });
});
