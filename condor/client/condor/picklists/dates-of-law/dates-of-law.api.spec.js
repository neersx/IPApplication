describe('Service inprotech.picklists.datesOfLawApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(datesOfLawApi) {
        var url = datesOfLawApi.$url();
        expect(url).toMatch(/\/datesoflaw/);
    }));
});
