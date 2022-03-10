describe('Service inprotech.picklists.caseCategoriesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(caseCategoriesApi) {
        var url = caseCategoriesApi.$url();
        expect(url).toMatch(/\/caseCategories$/);
    }));
});
