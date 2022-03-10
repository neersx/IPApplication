describe('inprotech.processing.policing.PolicingDashboardController', function() {
    'use strict';

    var controller, scope, rootScope, messageBroker, policingDashboardService;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.core', 'inprotech.mocks.processing.policing']);

            messageBroker = $injector.get('messageBrokerMock');
            $provide.value('messageBroker', messageBroker);

            policingDashboardService = $injector.get('policingDashboardServiceMock');
            $provide.value('policingDashboardService', policingDashboardService);
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
                $rootScope: rootScope,
                messageBroker: messageBroker,
                policingDashboardService: policingDashboardService
            }, dependencies);

            var c = $controller('PolicingDashboardController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function() {
        it('should set statusGraph as default', function() {
            var c = controller();
            expect(c.graphSelected).toBe('statusGraph');
        });

        it('should set summary and trend', function() {
            var data = {
                summary: {
                    a: 1
                },
                trend: {
                    b: 2
                }
            };
            policingDashboardService.dashboard.returnValue = data;
            var c = controller();
            expect(messageBroker.subscribe).toHaveBeenCalled();
            expect(c.summary).toBeUndefined();
            expect(c.trend).toBe(data.trend);
        });

        it('should initialise canManageExchangeRequests', function() {
            var c = controller();
            expect(c.canManageExchangeRequests).toBe(false);
        });

        it('should set up to receive updates for statusGraph', function() {
            controller();

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();

            expect(messageBroker.subscribe.calls.first().args[0]).toBe('policing.dashboard.statusGraph');
        });

        it('should set up to receive updates for policing server', function() {
            controller();

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();

            expect(messageBroker.subscribe.calls.count()).toBe(3);
            expect(messageBroker.subscribe.calls.argsFor(0)[0]).toBe('policing.dashboard.statusGraph');
            expect(messageBroker.subscribe.calls.argsFor(1)[0]).toBe('policing.server.status');
            expect(messageBroker.subscribe.calls.argsFor(2)[0]).toBe('processing.backgroundServices.status');
        });

        it('should set canManageExchangeRequests from emitted value', function() {
            var c = controller();

            rootScope.$emit('onPolicingPermissionsReturned', true);
            expect(c.canManageExchangeRequests).toBe(true);

            rootScope.$emit('onPolicingPermissionsReturned', false);
            expect(c.canManageExchangeRequests).toBe(false);
        });
    });

    describe('when chart type changed to rateGraph', function() {

        function clearAllMessageBrokerCalls() {
            messageBroker.disconnect.calls.reset();
            messageBroker.connect.calls.reset();
            messageBroker.subscribe.calls.reset();
        }

        it('should set up to receive updates for the selected graph', function() {
            var c = controller();

            clearAllMessageBrokerCalls();

            c.graphSelected = 'rateGraph';
            c.chartTypeChanged();

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();

            expect(messageBroker.subscribe.calls.first().args[0]).toBe('policing.dashboard.rateGraph');

            clearAllMessageBrokerCalls();

            c.graphSelected = 'statusGraph';
            c.chartTypeChanged();

            expect(messageBroker.disconnect).toHaveBeenCalled();
            expect(messageBroker.connect).toHaveBeenCalled();
            expect(messageBroker.subscribe).toHaveBeenCalled();

            expect(messageBroker.subscribe.calls.first().args[0]).toBe('policing.dashboard.statusGraph');
        });

        it('should broadcast the message in the scope', function() {

            var statusGraphCalls = 0;
            var rateGraphCalls = 0;
            var serverStatusCalls = 0;

            var c = controller();

            scope.$on('policing.dashboard.statusGraph', function() {
                statusGraphCalls = statusGraphCalls + 1;
            });

            scope.$on('policing.dashboard.rateGraph', function() {
                rateGraphCalls = rateGraphCalls + 1;
            });


            scope.$on('policing.server.status', function() {
                serverStatusCalls = serverStatusCalls + 1;
            });

            c.graphSelected = 'rateGraph';
            c.chartTypeChanged();

            c.graphSelected = 'statusGraph';
            c.chartTypeChanged();

            expect(statusGraphCalls).toBe(1);
            expect(rateGraphCalls).toBe(1);
            expect(serverStatusCalls).toBe(2);
        });
    });

    describe('when scope is destroyed', function() {
        it('should disconnect from messageBroker', function() {
            controller();

            messageBroker.disconnect.calls.reset();

            scope.$destroy();

            expect(messageBroker.disconnect).toHaveBeenCalled();
        });
    });
});