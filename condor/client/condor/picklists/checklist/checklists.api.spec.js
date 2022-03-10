describe('Service inprotech.picklists.checklistApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(checklistApi) {
        var url = checklistApi.$url();
        expect(url).toMatch(/\/checklist/);
    }));
});
