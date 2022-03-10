describe('inprotech.configuration.general.validcombination.StatusMaintenanceController', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('statusMaintenanceController', {}, {
                entity: {
                    state: 'adding'
                },
                searchCriteria: {
                    caseType: {
                        key: 'A',
                        value: 'Properties'
                    },
                    propertyType: {
                        key: 'P',
                        value: 'Patents'
                    },
                    jurisdictions: [{
                        key: 'AU',
                        value: 'Australia'
                    }],
                    status: {
                        key: 'S',
                        value: 'Status'
                    }
                }
            });
            c.$onInit();
            return c;
        };
    }));
    describe('pre populate search criteria', function() {
        it('should set prepopulate entity from search criteria', function() {
            var c = controller();

            expect(c.entity.caseType).toBe(c.searchCriteria.caseType);
            expect(c.entity.propertyType).toBe(c.searchCriteria.propertyType);
            expect(c.entity.jurisdictions).toBe(c.searchCriteria.jurisdictions);
            expect(c.entity.status).toBe(c.searchCriteria.status);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            var c = controller();
            expect(c.entity.prepopulated).toBe(true);
        });
    });
});