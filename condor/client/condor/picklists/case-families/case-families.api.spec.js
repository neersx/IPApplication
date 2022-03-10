describe('Service inprotech.picklists.caseFamiliesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(caseFamiliesApi) {
        var url = caseFamiliesApi.$url();
        expect(url).toMatch(/\/caseFamilies$/);
    }));
});
