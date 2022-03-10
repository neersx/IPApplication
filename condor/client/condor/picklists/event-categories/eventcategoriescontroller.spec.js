describe('inprotech.picklists.eventCategoriesController', function() {
    'use strict';

    var controller, scope;

    beforeEach(module('inprotech.picklists'));

    beforeEach(inject(function($rootScope, $controller) {
        scope = $rootScope.$new();

        controller = function(newScope) {
            if (newScope) {
                scope = angular.extend(scope, newScope);
            } else {
                scope = angular.extend(scope, {
                    vm: {
                        maintenanceState: "viewing"
                    }
                });
            }
            scope.vm.maintenance = {
                $setDirty: function() {
                    return;
                }
            };

            spyOn(scope.vm.maintenance, '$setDirty').and.callThrough();

            var dependencies = {
                $scope: scope
            };

            return $controller('eventCategoriesController', dependencies);
        };
    }));

    describe('initialising', function() {
        it('should define image status filter and leave form clean', function() {
            var ctr = controller({
                vm: {
                    maintenanceState: "editing",
                    entry: {
                        name: "xyz"
                    }
                }
            });
            scope.$digest();
            expect(ctr.eventCategoryImages).toBeDefined();
            expect(scope.vm.maintenance.$setDirty).not.toHaveBeenCalled();
        });
    });

    describe('maintaining event categories', function() {
        it('should not set form to dirty when editing', function() {
            controller({
                vm: {
                    maintenanceState: "editing",
                    entry: {
                        name: "xyz"
                    }
                }
            });
            scope.$digest();

            expect(scope.vm.entry.name).toEqual('xyz');
            expect(scope.vm.maintenance.$setDirty).not.toHaveBeenCalled();
        });
        it('should initialise name with \'Copy\' and set form to dirty', function() {
            controller({
                vm: {
                    maintenanceState: "duplicating",
                    entry: {
                        name: "abc"
                    }
                }
            });
            scope.$digest();

            expect(scope.vm.entry.name).toEqual('abc - Copy');
            expect(scope.vm.maintenance.$setDirty).toHaveBeenCalled();
        });
    });
});
