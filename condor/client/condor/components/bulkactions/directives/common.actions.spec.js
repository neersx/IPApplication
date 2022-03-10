describe('Service inprotech.components.bulkactions.commonActions', function() {
    'use strict';

    beforeEach(module('inprotech.components'));

    var service;

    beforeEach(inject(function(commonActions) {
        service = commonActions;
    }));

    it('should initialise service', function() {
        expect(service).toBeDefined();
    });

    it('should intentionally throw error on click', function() {
        _.each(service.get(), function(action) {
            expect(action.click).toThrowError('action not defined!');
        });
    });

});
