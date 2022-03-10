describe('Service inprotech.picklists.relationshipsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(relationshipsApi) {
        var url = relationshipsApi.$url();
        expect(url).toMatch(/\/relationship$/);
    }));
});
