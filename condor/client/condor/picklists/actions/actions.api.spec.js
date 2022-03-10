describe('Service inprotech.picklists.actionsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(actionsApi) {
        var url = actionsApi.$url();
        expect(url).toMatch(/\/actions$/);
    }));
});
