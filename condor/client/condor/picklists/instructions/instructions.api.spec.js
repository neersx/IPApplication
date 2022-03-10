describe('Service inprotech.picklists.instructionsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(instructionsApi) {
        var url = instructionsApi.$url();
        expect(url).toMatch(/\/instructions$/);
    }));
});
