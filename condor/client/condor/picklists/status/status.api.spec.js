describe('Service inprotech.picklists.statusApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(statusesApi) {
        var url = statusesApi.$url();
        expect(url).toMatch(/\/status/);
    }));
});
