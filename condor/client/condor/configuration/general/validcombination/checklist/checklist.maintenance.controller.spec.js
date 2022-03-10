describe('inprotech.configuration.general.validcombination.ChecklistMaintenanceController', function() {
    'use strict';

    var controller;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('checklistMaintenanceController', {}, {
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
                    checklist: {
                        key: 'RN',
                        value: 'Renewal'
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
            expect(c.entity.checklist).toBe(c.searchCriteria.checklist);
            expect(c.entity.validDescription).toBe(c.searchCriteria.checklist.value);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            var c = controller();
            expect(c.entity.prepopulated).toBe(true);
        });
    });
    describe('checklist picklist selection change', function() {
        describe('checklist picklist selection change', function() {
            it('should default valid description on selection change', function() {
                var c = controller();

                c.entity = {
                    checklist: {
                        key: 1,
                        value: 'Checklist'
                    },
                    validDescription: null
                };
                var validDescription = {
                    $dirty: false
                };
                c.onChecklistSelectionChanged(validDescription);

                expect(c.entity.checklistDirty).toBe(true);
                expect(c.entity.validDescription).toBe(c.entity.checklist.value);
            });

            it('should not default valid description on selection change', function() {
                var c = controller();

                c.entity = {
                    checklist: {
                        key: 1,
                        value: 'Checklist'
                    },
                    validDescription: null
                };
                var validDescription = {
                    $dirty: true
                };
                c.onChecklistSelectionChanged(validDescription);

                expect(c.entity.checklistDirty).toBe(true);
                expect(c.entity.validDescription).toBe(null);
            });
        });
    });
});