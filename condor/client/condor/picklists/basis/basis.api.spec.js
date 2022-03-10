describe('Service inprotech.picklists.basisApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(basisApi) {
        var url = basisApi.$url();
        expect(url).toMatch(/\/basis$/);
    }));
});
