describe('Service inprotech.picklists.jurisdictionsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(jurisdictionsApi) {
        var url = jurisdictionsApi.$url();
        expect(url).toMatch(/\/jurisdictions$/);
    }));
});
