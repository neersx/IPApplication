describe('Service inprotech.picklists.dataItemsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(dataItemsApi) {
        var url = dataItemsApi.$url();
        expect(url).toMatch(/\/dataItems/);
    }));
});
