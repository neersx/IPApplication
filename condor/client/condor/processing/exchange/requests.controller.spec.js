describe('inprotech.processing.exchange.ExchangeRequestsController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, exchangeQueueService, promiseMock, notificationService, localSettings;

    beforeEach(function() {
        module('inprotech.processing.exchange');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.grid']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            exchangeQueueService = $injector.get('ExchangeQueueServiceMock');
            notificationService = $injector.get('notificationServiceMock');
            promiseMock = $injector.get('promiseMock');
            localSettings = $injector.get('localSettingsMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            $provide.value('exchangeQueueService', exchangeQueueService);
            $provide.value('notificationService', notificationService);
            $provide.value('localSettings', localSettings);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            scope = {};
            dependencies = angular.extend({
                $scope: scope
            }, dependencies);

            return $controller('ExchangeRequestsController', dependencies);
        };
    }));

    describe('initialise controller', function() {
        it('should initialise the grid and menu', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.menu).toBeDefined();
        })
    });

    describe('loading the grid', function() {
        it('should call the service with correct parameters', function() {
            var c = controller();
            var params = { take: 50 };

            c.gridOptions.read(params);
            expect(exchangeQueueService.get).toHaveBeenCalledWith(params);
        })
    })

    describe('bulk menu', function() {
        it('should build the menu', function() {
            var c = controller();
            expect(c.menu).toEqual(jasmine.objectContaining({
                context: 'exchangeRequestListMenu',
                items: [jasmine.objectContaining({
                    id: 'resetRequest',
                    text: 'exchangeIntegration.bulkMenu.reset',
                    icon: 'eraser',
                    enabled: jasmine.any(Function),
                    click: jasmine.any(Function)
                }), jasmine.objectContaining({
                    id: 'delete',
                    enabled: jasmine.any(Function),
                    click: jasmine.any(Function)
                }), jasmine.objectContaining({
                    id: 'selectObsolete',
                    text: 'exchangeIntegration.bulkMenu.selectObsolete',
                    icon: 'check',
                    click: jasmine.any(Function)
                })],
                clearAll: jasmine.any(Function),
                selectAll: jasmine.any(Function),
                selectionChange: jasmine.any(Function)
            }));
        });

        it('should call reset function when eraser clicked', function() {
            var c = controller();
            var response = {
                data: {
                    result: {
                        status: 'sucess',
                        updated: 2
                    }
                }
            };
            spyOn(c.gridOptions, 'data').and.returnValue([{
                id: 1,
                selected: true
            }, {
                id: 2,
                selected: false
            }, {
                id: 3,
                selected: true
            }]);
            exchangeQueueService.reset = promiseMock.createSpy(response);
            c.menu.items[0].click();

            expect(exchangeQueueService.reset).toHaveBeenCalled();
        });

        it('should call delete function when bin clicked', function() {
            var c = controller();
            var response = {
                data: {
                    result: {
                        status: 'sucess'
                    }
                }
            };
            spyOn(c.gridOptions, 'data').and.returnValue([{
                id: 1,
                selected: true,
                statusId: 0
            }, {
                id: 2,
                selected: false,
                statusId: 1
            }, {
                id: 3,
                selected: true,
                statusId: 0
            }]);
            exchangeQueueService.delete = promiseMock.createSpy(response);
            c.menu.items[1].click();

            expect(notificationService.confirmDelete).toHaveBeenCalled();
            expect(exchangeQueueService.delete).toHaveBeenCalled();
        });
    })
});