describe('inprotech.processing.policing.ipPolicingServerStatusController', function() {
    'use strict';

    var controller, scope, rootScope, service, notificationService, promiseMock;
    var topic = 'policing.server.status';

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.processing.policing', 'inprotech.mocks.components.notification', 'inprotech.mocks.core']);

            service = $injector.get('policingServerServiceMock');
            $provide.value('policingServerService', service);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            promiseMock = $injector.get('promiseMock');
        });
    });

    beforeEach(inject(function($rootScope) {
        rootScope = $rootScope;
        scope = $rootScope.$new();
    }));

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                $rootScope: rootScope
            }, dependencies);

            return $controller('ipPolicingServerStatusController', dependencies);
        };
    }));

    describe('initialization', function() {
        it('should start with pending state', function() {
            var c = controller();
            expect(c.currentState.state).toBe(0);
            expect(c.currentState.data.message).toBe('policing.serverStatus.checking');
        });

        it('should check for administration permissions', function() {
            controller();
            expect(service.canAdminister).toHaveBeenCalled();
        });

        describe('and permissions are retrieved', function() {
            beforeEach(function() {
                spyOn(rootScope, '$emit');
            });
            it('should emit administration permissions to subscribers', function() {
                var permissions = {
                    data: {
                        canAdminister: true,
                        canManageExchangeRequests: 'AAA'
                    }
                };
                service.canAdminister = promiseMock.createSpy(permissions);

                var c = controller();
                expect(c.canAdminister).toBe(true);
                expect(rootScope.$emit).toHaveBeenCalledWith('onPolicingPermissionsReturned', 'AAA');
            });
        });

    });

    describe('policng server state change', function() {
        it('should turn on', function() {
            var c = controller();
            c.canAdminister = true;
            scope.$broadcast(topic, 1);
            expect(c.currentState.state).toBe(1);
            expect(c.currentState.data.message).toBe('policing.serverStatus.running');
            expect(c.currentState.data.radioClass).toBe('saved');
        });

        it('should turn off', function() {
            var c = controller();
            scope.$broadcast(topic, 2);
            expect(c.currentState.state).toBe(2);
            expect(c.currentState.data.message).toBe('policing.serverStatus.stopped');
            expect(c.currentState.data.radioClass).toBe('error');
        });
    });

    describe('policing server adminsitration', function() {
        it('should turn off server', function() {
            var c = controller();
            scope.$broadcast(topic, 1);
            c.changeServerStatus();
            expect(notificationService.confirm).toHaveBeenCalled();
            expect(service.turnOff).toHaveBeenCalled();
        });

        it('should turn on server', function() {
            var c = controller();
            scope.$broadcast(topic, 2);
            c.changeServerStatus();
            expect(notificationService.confirm).toHaveBeenCalled();
            expect(service.turnOn).toHaveBeenCalled();
        });
    });
});
