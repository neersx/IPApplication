describe('Service inprotech.picklists.subTypesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(subTypesApi) {
        var url = subTypesApi.$url();
        expect(url).toMatch(/\/subtypes/);
    }));
});
