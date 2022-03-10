describe('Service inprotech.picklists.instructionTypesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(instructionTypesApi) {
        var url = instructionTypesApi.$url();
        expect(url).toMatch(/\/instructionTypes$/);
    }));
});
