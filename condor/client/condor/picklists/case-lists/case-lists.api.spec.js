describe('Service inprotech.picklists.caseListsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(caseListsApi) {
        var url = caseListsApi.$url();
        expect(url).toMatch(/\/caseLists$/);
    }));
});
