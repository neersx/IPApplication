describe('Service inprotech.picklists.officesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(officesApi) {
        var url = officesApi.$url();
        expect(url).toMatch(/\/offices$/);
    }));
});
