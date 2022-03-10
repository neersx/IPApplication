describe('inprotech.picklists.actionsController', function() {
    'use strict';

    var controller, http, scope, modalService;

    beforeEach(function() {
        module('inprotech.picklists')

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function($httpBackend, $rootScope, $controller) {

        http = $httpBackend;
        scope = $rootScope.$new();

        controller = function() {
            var dependencies = {
                $scope: scope,
                modalService: modalService
            };

            return $controller('actionsController', dependencies);
        };

    }));

    it('should get importance levels', function() {
        var importanceLevels = [{
            level: 5,
            description: 'Critical'
        }];
        http.whenGET('api/picklists/actions/importancelevels')
            .respond(function() {
                return [200, importanceLevels, {}];
            });

        scope.vm = {
            maintenanceState: 'adding',
            entry: {}
        };

        var ctr = controller();
        http.flush();

        expect(ctr.importanceLevels).toEqual(importanceLevels);
        expect(scope.vm.entry.importanceLevel).toEqual(importanceLevels[0].level);
    });

    describe('initialising', function() {
        it('should initialise defaults and get support data', function() {
            scope.vm = {
                maintenanceState: 'adding',
                entry: {}
            };
            
            var ctr = controller();
            expect(ctr.canEnterMaxCycles).toEqual(true);
            expect(scope.vm.entry.cycles).toEqual(1);
        });
    });

    describe('toggling unlimited cycles', function() {
        it('should set maxCycles to 9999 and disable the field when checked', function() {

            scope.vm = {
                entry: {
                    unlimitedCycles: true
                }
            };

            var ctr = controller();
            ctr.toggleMaxCycle(scope.vm);

            expect(scope.vm.entry.cycles).toEqual(9999);
            expect(ctr.canEnterMaxCycles).toEqual(false);
        });

        it('should set maxCycles to 9999 and disable the field when checked', function() {

            scope.vm = {
                entry: {
                    unlimitedCycles: false
                }
            };

            var ctr = controller();
            ctr.toggleMaxCycle(scope.vm);

            expect(ctr.canEnterMaxCycles).toEqual(true);
        });
    });
    describe('launchActionOrder', function() {
        it('should open ActionOrder window when entity is added or duplicated', function() {
            scope.vm = {
                maintenanceState: 'adding',
                entry: {},
                entity: "actions",
                isValidCombinationPicklist: jasmine.createSpy().and.returnValue(true)
            };

            controller();
            scope.vm.confirmAfterSave(scope.vm.entry);

            expect(modalService.openModal).toHaveBeenCalled();
        });
    });
});