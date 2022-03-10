describe('Service inprotech.picklists.classitemsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(classItemsApi) {
        var url = classItemsApi.$url();
        expect(url).toMatch(/\/classItems$/);
    }));
});