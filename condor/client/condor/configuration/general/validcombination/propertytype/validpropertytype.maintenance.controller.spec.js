describe('inprotech.configuration.general.validcombination.validPropertyTypeMaintenanceController', function() {
    'use strict';

    var controller, scope;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        controller = function(dependencies) {
            return $controller('validPropertyTypeMaintenanceController', angular.extend({ $scope: scope }, dependencies));
        };
    }));
    describe('clear annuity options ', function() {
        it('should clear other annuity options when ', function() {
            var c = controller();

            scope.model = {
                offset: '1',
                cycleOffset: null
            };

            c.clearAnnuityOptions();

            expect(scope.model.offset).toBe(null);
        });
    });
    describe('text field change ', function() {
        it('Should mark data not supported false when on text field change with invalid values', function() {
            var c = controller();

            scope.model = {
                offset: 9999999999,
                cycleOffset: 999
            };

            scope.maintenance = {
                annuityOffset: {
                    $setValidity: jasmine.createSpy()
                },
                annuityCycleOffset: {
                    $setValidity: jasmine.createSpy()
                }
            };

            c.onOffsetChange();

            expect(scope.maintenance.annuityOffset.$setValidity).toHaveBeenCalledWith('notSupportedValue', false);
            expect(scope.maintenance.annuityCycleOffset.$setValidity).toHaveBeenCalledWith('notSupportedValue', false);
        });
        it('Should mark data not supported true when on text field change with valid values', function() {
            var c = controller();

            scope.model = {
                offset: 100,
                cycleOffset: 10
            };

            scope.maintenance = {
                annuityOffset: {
                    $setValidity: jasmine.createSpy()
                },
                annuityCycleOffset: {
                    $setValidity: jasmine.createSpy()
                }
            };

            c.onOffsetChange();

            expect(scope.maintenance.annuityOffset.$setValidity).toHaveBeenCalledWith('notSupportedValue', true);
            expect(scope.maintenance.annuityCycleOffset.$setValidity).toHaveBeenCalledWith('notSupportedValue', true);
        });
    });
});