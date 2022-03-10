describe('Service inprotech.picklists.keywordsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(keywordsApi) {
        var url = keywordsApi.$url();
        expect(url).toMatch(/\/keywords$/);
    }));
});
