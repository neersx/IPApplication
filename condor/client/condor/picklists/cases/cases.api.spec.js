describe('Service inprotech.picklists.casesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(casesApi) {
        var url = casesApi.$url();
        expect(url).toMatch(/\/cases$/);
    }));
});
