describe('inprotech.configuration.general.validcombination.RelationshipMaintenanceController', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('relationshipMaintenanceController', {}, {
                entity: {
                    state: 'adding'
                },
                searchCriteria: {
                    propertyType: {
                        key: 'P',
                        value: 'Patents'
                    },
                    jurisdictions: [{
                        key: 'AU',
                        value: 'Australia'
                    }],
                    relationship: {
                        key: 'R',
                        value: 'Relationship'
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
            expect(c.entity.jurisdictions).toBe(c.searchCriteria.jurisdictions);
            expect(c.entity.relationship).toBe(c.searchCriteria.relationship);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            var c = controller();
            expect(c.entity.prepopulated).toBe(true);
        });
    });
});