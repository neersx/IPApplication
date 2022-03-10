describe('inprotech.processing.policing.ipSavedRequestViewComponent', function() {
    'use strict';
    var modalService, service, scope, controller, notificationService, kendoGridBuilder, promiseMock, localSettings;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.core', 'inprotech.mocks.components.notification', 'inprotech.mocks.components.grid', 'inprotech.mocks.core']);
            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            service = $injector.get('PolicingRequestServiceMock');
            $provide.value('policingRequestService', service);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            promiseMock = $injector.get('promiseMock');

            localSettings = $injector.get('localSettingsMock');
            $provide.value('localSettings', localSettings);
        });
    });

    beforeEach(inject(function($componentController, $rootScope) {
        controller = function() {
            scope = $rootScope.$new();
            var viewData = {
                requests: [{}, {}]
            };
            var topic = {};

            var c = $componentController('ipSavedRequestView', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                modalService: modalService,
                policingRequestService: service,
                notificationservice: notificationService
            }, {
                viewData: viewData,
                topic: topic
            });
            c.$onInit();
            return c;
        }
    }));

    it('initialises data', function() {
        var c = controller();

        expect(c.context).toBe('policingRequest');
        expect(c.topic.initialised).toBeTruthy();
    });

    it('should have edit, delete, run-now menu', function() {
        var c = controller();
        var containsEdit = _.some(c.actions, function(c) {
            return c.id === 'edit';
        });
        expect(containsEdit).toBeTruthy();

        var containsDelete = _.some(c.actions, function(c) {
            return c.id === 'delete';
        });
        expect(containsDelete).toBeTruthy();

        var containsRunNow = _.some(c.actions, function(c) {
            return c.id === 'runNow';
        });
        expect(containsRunNow).toBeTruthy();
    });

    describe('actions', function() {
        it('should edit selected request', function() {
            var c = controller();
            modalService.open = promiseMock.createSpy({
                result: 'done'
            });

            c.openSelectedRequest(10);

            expect(modalService.open).toHaveBeenCalled();
        });

        it('should refresh data, if edited request is saved', function() {
            var c = controller();
            modalService.open = promiseMock.createSpy('Success');
            c.gridOptions.data = function() {
                return [];
            };

            c.openSelectedRequest(10);

            expect(modalService.open).toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should open marked item for edit', function() {
            var c = controller();
            var requests = [{
                id: 1
            }, {
                id: 2
            }];

            modalService.open = promiseMock.createSpy('Success');
            service.getRequest = promiseMock.createSpy({
                requestId: 1
            });
            requests[0].selected = true;
            c.gridOptions.data = function() {
                return requests;
            };

            c.openSelectedRequest();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.getRequest).toHaveBeenCalledWith(1);
            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        it('should delete selected items and refresh data', function() {
            var c = controller();
            var requests = [{
                id: 1,
                selected: true
            }, {
                id: 2,
                selected: true
            }];
            notificationService.confirmDelete = promiseMock.createSpy('Success');
            notificationService.success = promiseMock.createSpy();

            service.delete = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });

            c.gridOptions.data = function() {
                return requests;
            };
            c.deleteSelected();

            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(service.delete).toHaveBeenCalledWith([1, 2]);
            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should mark non deletable items and refresh data', function() {
            var c = controller();
            var requests = [{
                id: 1,
                selected: true
            }, {
                id: 2,
                selected: true
            }];
            notificationService.confirmDelete = promiseMock.createSpy('Success');
            notificationService.success = promiseMock.createSpy();

            service.delete = promiseMock.createSpy({
                data: {
                    status: 'partialSuccess',
                    notDeletedIds: [1],
                    error: 'alreadyInUse'
                }
            });

            c.gridOptions.data = function() {
                return requests;
            };
            c.deleteSelected();

            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(service.delete).toHaveBeenCalledWith([1, 2]);
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should not delete selected items, if confirmation not provided', function() {
            var c = controller();
            var requests = [{
                id: 1,
                selected: true
            }, {
                id: 2,
                selected: true
            }];
            notificationService.confirmDelete = promiseMock.createSpy();
            service.get = promiseMock.createSpy({
                requests: requests
            });

            service.delete = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });
            c.gridOptions.data = function() {
                return requests;
            };

            c.deleteSelected();

            expect(notificationService.confirmDelete).toHaveBeenCalled();
        });

        it('should run the item selected for run now', function() {
            var c = controller();
            var requests = [{
                id: 1,
                selected: true
            }, {
                id: 2
            }];
            modalService.open = promiseMock.createSpy({
                runType: 1
            });
            notificationService.success = promiseMock.createSpy();
            service.getRequestWithAffectedCasesCount = promiseMock.createSpy({
                requests: requests
            });
            service.runNow = promiseMock.createSpy();
            c.gridOptions.data = function() {
                return requests;
            };

            c.runNowSelected();

            expect(modalService.open).toHaveBeenCalled();
            expect(service.runNow).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
        });
    });
});