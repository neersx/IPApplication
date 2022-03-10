describe('Service inprotech.picklists.tagsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(tagsApi) {
        var url = tagsApi.$url();
        expect(url).toMatch(/\/tags/);
    }));
});
