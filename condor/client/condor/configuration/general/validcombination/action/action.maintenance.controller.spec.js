describe('inprotech.configuration.general.validcombination.ActionMaintenanceController', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('actionMaintenanceController', {}, {
                entity: {
                    state: 'adding'
                },
                searchCriteria: {
                    propertyType: {
                        key: 'P',
                        value: 'Patents'
                    },
                    caseType: {
                        key: 'P',
                        value: 'Properties'
                    },
                    jurisdictions: [{
                        key: 'AU',
                        value: 'Australia'
                    }],
                    action: {
                        key: 'AL',
                        value: 'Filing'
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

            expect(c.entity.propertyType).toBe(c.searchCriteria.propertyType);
            expect(c.entity.caseType).toBe(c.searchCriteria.caseType);
            expect(c.entity.jurisdictions).toBe(c.searchCriteria.jurisdictions);
            expect(c.entity.action).toBe(c.searchCriteria.action);
            expect(c.entity.validDescription).toBe(c.searchCriteria.action.value);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            var c = controller();
            expect(c.entity.prepopulated).toBe(true);
        });
    });
});