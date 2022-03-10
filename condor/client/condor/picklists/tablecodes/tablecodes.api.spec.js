describe('Service inprotech.picklists.tablecodesApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(tablecodesApi) {
        var url = tablecodesApi.$url();
        expect(url).toMatch(/\/tablecodes/);
    }));
});
