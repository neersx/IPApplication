describe('Service inprotech.picklists.caseTypesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(caseTypesApi) {
        var url = caseTypesApi.$url();
        expect(url).toMatch(/\/casetypes/);
    }));
});
