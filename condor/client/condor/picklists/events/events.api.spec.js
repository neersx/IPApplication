describe('Service inprotech.picklists.eventsApi', function() {
    'use strict';

    beforeEach(module('inprotech.picklists'));

    it('should build the right URL', inject(function(eventsApi) {
        var url = eventsApi.$url();
        expect(url).toMatch(/\/events$/);
    }));
});
