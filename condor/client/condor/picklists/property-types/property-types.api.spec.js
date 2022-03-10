describe('Service inprotech.picklists.propertyTypesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(propertyTypesApi) {
        var url = propertyTypesApi.$url();
        expect(url).toMatch(/\/propertyTypes$/);
    }));
});
