describe('inprotech.processing.policing.PolicingQueueController', function() {
    'use strict';

    var controller, kendoGridBuilder, service, notificationService, scope, interval, promiseMock, summary;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.processing.policing', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification', 'inprotech.mocks.core']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('PolicingQueueServiceMock');
            $provide.value('policingQueueService', service);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            promiseMock = $injector.get('promiseMock');
        });
    });

    beforeEach(inject(function($controller, $rootScope, $interval) {

        scope = $rootScope.$new();
        interval = $interval;

        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                viewData: {
                    hasOffices: true,
                    summary: summary
                },
                queueType: 'all',
                refreshInterval: 30
            }, dependencies);

            var c = $controller('PolicingQueueController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function() {
        it('should initialise grid', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
        });

        it('should initialise config', function() {
            controller();

            expect(service.config).toHaveBeenCalled();
        });

        it('should not have a subheading when returning all items', function() {
            var c = controller();

            expect(c.subheading).toEqual('total');
        });

        it('should have a subheading when returning progressing items', function() {
            var c = controller({
                queueType: 'progressing'
            });

            expect(c.subheading).toEqual('progressing');
        });

        it('should have a subheading when returning requires-attention items', function() {
            var c = controller({
                queueType: 'requires-attention'
            });

            expect(c.subheading).toEqual('requires-attention');
        });

        it('should have a subheading when returning on-hold items', function() {
            var c = controller({
                queueType: 'on-hold'
            });

            expect(c.subheading).toEqual('on-hold');
        });

        it('should initialise summaryData', function() {
            var c = controller();

            expect(c.summary).toBe(summary);
        });
    });

    describe('auto refresh on policing queue', function() {
        it('should initialise refreshState and run auto refresh', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();

            expect(c.refreshState).toEqual(true);

            interval.flush(31000);
            expect(c.gridOptions.search.calls.count()).toBe(1);

            interval.flush(31000);
            expect(c.gridOptions.search.calls.count()).toBe(2);
        });

        it('should remove interval when controller destroys', function() {
            controller();
            spyOn(interval, 'cancel');
            scope.$destroy();
            expect(interval.cancel).toHaveBeenCalled();
        });

        it('should set default refresh interval to be 30 secs', function() {
            var c = controller();

            expect(c.refreshInterval).toEqual(30);
        });

        it('should set refreshInterval if provided by User', function() {
            var c = controller({
                refreshInterval: 5
            });

            expect(c.refreshInterval).toEqual(5);
        });
    });

    describe('bulk menu actions', function() {
        it('should call service to do release selected', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();
            _.findWhere(c.actions, {
                id: 'Release'
            }).click();
            expect(service.releaseSelected).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should call service to delete selected', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();
            _.findWhere(c.actions, {
                id: 'Delete'
            }).click();
            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(service.deleteSelected).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should call service to hold all', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();
            _.findWhere(c.actions, {
                id: 'HoldAll'
            }).click();
            expect(notificationService.confirm).toHaveBeenCalled();
            expect(service.holdAll).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should call service to release all', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();
            _.findWhere(c.actions, {
                id: 'ReleaseAll'
            }).click();
            expect(notificationService.confirm).toHaveBeenCalled();
            expect(service.releaseAll).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should call service to delete all', function() {
            var c = controller();
            c.gridOptions.search = promiseMock.createSpy();
            _.findWhere(c.actions, {
                id: 'DeleteAll'
            }).click();
            expect(notificationService.confirm).toHaveBeenCalled();
            expect(service.deleteAll).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
    });
});
