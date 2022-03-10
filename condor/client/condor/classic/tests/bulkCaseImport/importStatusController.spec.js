describe('Inprotech.BulkCaseImport.importStatusController', function () {
    'use strict';

    var _scope, _controller, _http, notificationService, _bulkCaseImportService, _permissions, kendoGridBuilder, localSettings, bulkMenuOperationsMock, modalServiceMock, schedulerMock;


    beforeEach(function () {
        module('Inprotech.BulkCaseImport')
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.notification', 'inprotech.mocks.bulkcaseimport', 'inprotech.mocks']);
            notificationService = $injector.get('notificationServiceMock');
            _bulkCaseImportService = $injector.get('importStatusServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');
            modalServiceMock = $injector.get('modalServiceMock');
            schedulerMock = $injector.get('schedulerMock');
            localSettings = $injector.get('localSettingsMock');
            localSettings.Keys.caseImport.status.pageNumber.setLocal(20);
            $provide.value('notificationService', notificationService);
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            $provide.value('BulkMenuOperations', bulkMenuOperationsMock);
            $provide.value('modalService', modalServiceMock);
            $provide.value('scheduler', schedulerMock);
        });
    });

    beforeEach(inject(function ($rootScope, $controller, $injector) {
        _scope = $rootScope.$new();
        _http = $injector.get('$httpBackend');
        _permissions = {};

        _controller = function (permissions) {
            return $controller('importStatusController', {
                '$scope': _scope,
                'bulkCaseImportService': _bulkCaseImportService,
                'localSettings': localSettings,
                'permissions': permissions || _permissions
            });
        };
    }));

    describe('onInit', function () {
        it('initialises grid without bulk operations', function () {
            var c = _controller();
            c.$onInit();
            expect(c.gridOptions).toBeDefined();
            expect(c.gridOptions.columns.length).toBe(8);
            expect(c.gridOptions.columns[0].field).toBe('submittedDate');
            expect(c.gridOptions.columns[1].field).toBe('displayStatusType');
            expect(c.gridOptions.columns[2].field).toBe('batchIdentifier');
            expect(c.gridOptions.columns[3].field).toBe('total');
            expect(c.gridOptions.columns[4].columns[0].field).toBe('newCases');
            expect(c.gridOptions.columns[4].columns[1].field).toBe('amended');
            expect(c.gridOptions.columns[4].columns[2].field).toBe('noChange');
            expect(c.gridOptions.columns[5].field).toBe('rejected');
            expect(c.gridOptions.columns[6].columns[0].field).toBe('notMapped');
            expect(c.gridOptions.columns[6].columns[1].field).toBe('nameIssues');
            expect(c.gridOptions.columns[6].columns[2].field).toBe('unresolved');
            expect(c.gridOptions.columns[7].field).toBe('isHomeName');
        });

        it('initialises grid without bulk operations', function () {
            var permissions = {
                canReverseBatch: true
            };
            var c = _controller(permissions);
            c.$onInit();
            expect(c.gridOptions).toBeDefined();
            expect(c.gridOptions.columns[0].headerTemplate).toMatch('data-bulk-actions-menu');
            expect(c.gridOptions.columns.length).toBe(9);
            expect(c.gridOptions.columns[1].field).toBe('submittedDate');
            expect(c.gridOptions.columns[2].field).toBe('displayStatusType');
            expect(c.gridOptions.columns[3].field).toBe('batchIdentifier');
            expect(c.gridOptions.columns[4].field).toBe('total');
            expect(c.gridOptions.columns[5].columns[0].field).toBe('newCases');
            expect(c.gridOptions.columns[5].columns[1].field).toBe('amended');
            expect(c.gridOptions.columns[5].columns[2].field).toBe('noChange');
            expect(c.gridOptions.columns[6].field).toBe('rejected');
            expect(c.gridOptions.columns[7].columns[0].field).toBe('notMapped');
            expect(c.gridOptions.columns[7].columns[1].field).toBe('nameIssues');
            expect(c.gridOptions.columns[7].columns[2].field).toBe('unresolved');
            expect(c.gridOptions.columns[8].field).toBe('isHomeName');
        });
    })

    describe('viewing details of an imported batch', function () {
        it('sets details from selection', function () {

            var c = _controller();
            c.$onInit();
            c.onViewDetails({});

            expect(modalServiceMock.openModal).toHaveBeenCalled();
        });
    });

    describe('resubmitting a batch', function () {
        it('sends a http request', function () {
            var c = _controller();
            c.$onInit();
            _http.expectPOST('api/bulkcaseimport/resubmitbatch', '{"batchId":1}')
                .respond(function () {
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }];
                });

            c.resubmitBatch({
                id: 1
            });

            _http.flush();

            expect(notificationService.success).toHaveBeenCalled();
            expect(c.status).toBe('success');
        });

        it('relays handled errors from server', function () {
            var c = _controller();
            c.$onInit();

            _http.whenPOST('api/bulkcaseimport/resubmitbatch').respond(function () {
                return [200, {
                    result: {
                        result: 'error',
                        errorMessage: 'errorMessage'
                    }
                }];
            });

            c.resubmitBatch({});

            _http.flush();

            expect(notificationService.alert).toHaveBeenCalledWith(jasmine.objectContaining({
                errors: 'errorMessage'
            }));
            expect(c.status).toBe('idle');
        });
    });

    describe('reversing a batch', function () {

        var vm;
        var batch1 = {
            id: 1,
            statusType: 'ResolutionRequired',
            statusMessage: 'Unprocessed',
            batchIdentifier: '45687',
            isReversible: true
        };
        var batch2 = {
            id: 2,
            statusType: 'InProgress',
            batchIdentifier: '12345',
            isReversible: false
        };
        var batch3 = {
            id: 3,
            statusType: 'Error',
            batchIdentifier: '12346',
            isReversible: true
        };

        beforeEach(function () {
            _permissions = {
                canReverseBatch: true
            };

            vm = _controller();
            vm.$onInit();
            vm.gridOptions = {
                data: function () {
                    return false;
                }
            };

            spyOn(vm.gridOptions, 'data').and.returnValue([batch1, batch2]);
        });

        it('should enable "Reverse Batch" if single item selected', function () {
            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1]);

            expect(vm.menu.items[0].enabled()).toBe(true);
        });

        it('should not enable "Reverse Batch" if multiple items selected', function () {
            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1, batch3]);

            expect(vm.menu.items[0].enabled()).toBe(false);
        });

        it('should not enable "Reverse Batch" if item already submitted for reversal', function () {

            batch1.statusType = 'SubmittedForReversal';

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1]);

            expect(vm.menu.items[0].enabled()).toBe(false);
        });

        it('should not enable "Reverse Batch" if item already resubmitted for processing', function () {

            batch1.statusType = 'Resubmitted';

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1]);

            expect(vm.menu.items[0].enabled()).toBe(false);
        });

        it('should not enable "Reverse Batch" if item is marked not reversible', function () {

            batch2.isReversible = false;

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch2]);

            expect(vm.menu.items[0].enabled()).toBe(false);
        });

        it('should call reverse batch api with the batch id', function () {

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1]);
            bulkMenuOperationsMock.prototype.selectedRecord.and.returnValue(batch1);

            _http.expectPOST('api/bulkcaseimport/reversebatch', '{"batchId":1}')
                .respond(function () {
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }];
                });

            vm.menu.items[0].click();
            _http.flush();

            expect(notificationService.success).toHaveBeenCalled();
            expect(vm.status).toBe('success');
        });

        it('relays handled errors from server', function () {

            bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([batch1]);
            bulkMenuOperationsMock.prototype.selectedRecord.and.returnValue(batch1);

            _http.whenPOST('api/bulkcaseimport/reversebatch', '{"batchId":1}')
                .respond(function () {
                    return [200, {
                        result: {
                            result: 'error',
                            errorMessage: 'errorMessage'
                        }
                    }];
                });

            vm.menu.items[0].click();

            _http.flush();

            expect(notificationService.alert).toHaveBeenCalledWith(jasmine.objectContaining({
                errors: 'errorMessage'
            }));
            expect(vm.status).toBe('idle');
        });
    });
});