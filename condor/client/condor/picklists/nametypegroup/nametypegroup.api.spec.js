describe('Service inprotech.picklists.nametypegroupApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(nametypegroupApi) {
        var url = nametypegroupApi.$url();
        expect(url).toMatch(/\/nameTypeGroup/);
    }));
});
