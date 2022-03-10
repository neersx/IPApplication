namespace inprotech.names.consolidation {
    declare var test: any;
    describe('inprotech.names.consolidation', () => {
        'use strict';

        let controller: () => NamesConsolidationController, scope: ng.IScope, kendoGridBuilder, picklistService, kendoGridService;
        let notificationService: any, translate, modalService, namesConsolidationServiceMock, messageBroker, rootScope, featureDetectionMock, schedulerMock;

        beforeEach(() => {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.core']);
                notificationService = $injector.get('notificationServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                picklistService = $injector.get('picklistServiceMock');
                kendoGridService = $injector.get('kendoGridServiceMock');
                translate = test.mock('$translate', 'translateMock');
                translate.instant = jasmine.createSpy().and.returnValue('translated text');
                modalService = $injector.get('modalServiceMock');
                namesConsolidationServiceMock = $injector.get('NamesConsolidationServiceMock');
                messageBroker = $injector.get('messageBrokerMock');
                featureDetectionMock = $injector.get('featureDetectionMock');
                schedulerMock = $injector.get('schedulerMock');
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = <ng.IScope>$rootScope.$new();
            messageBroker.subscribe = jasmine.createSpy('subscribe').and.stub();
            controller = (): NamesConsolidationController => {
                rootScope = {
                    appContext: {
                        user: {
                            permissions: {
                                canShowLinkforInprotechWeb: false
                            }
                        }
                    }
                }
                let c = new NamesConsolidationController(rootScope, scope, kendoGridBuilder, notificationService, picklistService, kendoGridService, namesConsolidationServiceMock, translate, modalService, messageBroker, featureDetectionMock, schedulerMock);
                return c;
            };
        }));

        describe('Initialize', () => {
            it('initialize', function () {
                let c = controller();
                expect(c.openNamesPicklist).toBeDefined();
                expect(c.onDeleteClick).toBeDefined();
                expect(c.reset).toBeDefined();
                expect(c.selectName).toBeDefined();
                expect(c.targetName).toBeUndefined();
                expect(c.gridOptions).toBeDefined();
                expect(c.gridOptions.columns.length).toBe(7);
                expect(c.showWebLink).toBe(false);
            });

            it('select pickist', function () {
                let c = controller();
                let selectedName = [{ key: 1 }];
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
        });

        describe('Process Consolidation Result', () => {
            it('update status variables durning process', () => {
                let selectedName = [
                    { key: 1001, isError: false, isWarning: true },
                    { key: 1002, isError: false, isWarning: false },
                    { key: 1003, isError: false, isWarning: false }
                ]
                let data = {
                    isCompleted: false,
                    namesCouldNotConsolidate: [1001],
                    namesConsolidated: [1002]
                }
                let c = controller();
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                c.processConsolidationResult(data);
                let namesData = c.gridOptions.read();

                expect(namesData[0].isWarning).toBe(false);
                expect(namesData[0].isError).toBe(true);
                let successItem = _.find(namesData, (e: any) => {
                    return e.key === 1002
                });
                expect(successItem).toBeUndefined();
                expect(namesData.length).toBe(2);
                expect(c.requestSubmitted).toBe(true);
                expect(c.consolidateJobStatus).toBe('');
            });
            it('update status variables durning process', () => {
                let selectedName = [
                    { key: 1001, isError: false, isWarning: true },
                    { key: 1002, isError: false, isWarning: false },
                    { key: 1003, isError: false, isWarning: false }
                ]
                let data = {
                    isCompleted: true,
                    namesCouldNotConsolidate: [1001],
                    namesConsolidated: [1002, 1003]
                }
                let c = controller();
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                c.processConsolidationResult(data);
                let namesData = c.gridOptions.read();
                let errorItem = _.find(namesData, (e: any) => {
                    return e.key === 1001
                });
                expect(errorItem.isWarning).toBe(false);
                expect(errorItem.isError).toBe(true);
                expect(namesData.length).toBe(1);
                expect(c.requestSubmitted).toBe(false);
                expect(c.consolidateJobStatus).toBe('error');
            });
            it('update status variables durning process', () => {
                let selectedName = [
                    { key: 1001, isError: false, isWarning: false },
                    { key: 1002, isError: false, isWarning: false },
                    { key: 1003, isError: false, isWarning: false }
                ]
                let data = {
                    isCompleted: true,
                    namesConsolidated: [1001, 1002, 1003]
                }
                let c = controller();
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                c.processConsolidationResult(data);
                let namesData = c.gridOptions.read();
                expect(namesData.length).toBe(0);
                expect(c.requestSubmitted).toBe(false);
                expect(c.consolidateJobStatus).toBe('success');
            });
            it('lock screen for other users', () => {
                let data = {
                    isCompleted: false,
                    namesCouldNotConsolidate: [1001],
                    namesConsolidated: [1002, 1003]
                }
                let c = controller();
                c.requestSubmitted = false;
                c.processConsolidationResult(data);

                let namesData = c.gridOptions.read();
                expect(namesData).toBeUndefined();
                expect(c.requestSubmitted).toBe(true);
                expect(c.consolidateJobStatus).toBe('other');
            });
            it('no value change for other users', () => {
                let data = {
                    isCompleted: true,
                    namesCouldNotConsolidate: [1001],
                    namesConsolidated: [1002, 1003]
                }
                let c = controller();
                c.requestSubmitted = false;
                c.processConsolidationResult(data);

                let namesData = c.gridOptions.read();
                expect(namesData).toBeUndefined();
                expect(c.requestSubmitted).toBe(false);
                expect(c.consolidateJobStatus).toBe('');
            });
            it('update on changed data only', () => {
                let data = {
                    isCompleted: true,
                    namesCouldNotConsolidate: [1001],
                    namesConsolidated: [1002, 1003]
                }
                let c = controller();
                c.requestSubmitted = true;
                c.processConsolidationResult(data);
                expect(c.gridOptions.search).toHaveBeenCalled();

                c.processConsolidationResult(data);
                expect(c.gridOptions.search).toHaveBeenCalledTimes(1);
            })
        });

        describe('delete', () => {
            it('delete item from grid', function () {
                let c = controller();
                let selectedName = [
                    { key: 1 },
                    { key: 2 }
                ];
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                expect(c.gridOptions.search).toHaveBeenCalled();
                c.gridOptions.search.calls.reset();
                c.onDeleteClick({ key: 2 });
                expect(c.gridOptions.search).toHaveBeenCalled();
            });

            it('doesn not delete item from grid if request is submitted', function () {
                let c = controller();
                let selectedName = [
                    { key: 1 },
                    { key: 2 }
                ];
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                expect(c.gridOptions.search).toHaveBeenCalled();
                c.gridOptions.search.calls.reset();
                c.onDeleteClick({ key: 2 });
                expect(c.gridOptions.search).not.toHaveBeenCalled();
            });
        });

        describe('reset', () => {
            it('reset page prompts when changes are made', function () {
                let c = controller();
                let selectedName = [
                    { key: 1 },
                    { key: 2 }
                ];
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                expect(c.gridOptions.search).toHaveBeenCalled();
                c.reset();
                expect(notificationService.discard).toHaveBeenCalled();
                expect(c.targetName).toBeUndefined();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });

            it('resets errors on adding a new item', function () {
                let c = controller();
                let selectedName = [
                    { key: 1 },
                    { key: 2, isError: true }
                ];
                c.targetName = { key: 14 };
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                expect(c.gridOptions.search).toHaveBeenCalled();
                expect(c.isRunDisabled()).toBe(false);
            });

            it('reset page does not prompt when no change', function () {
                let c = controller();
                c.reset();
                expect(notificationService.discard).not.toHaveBeenCalled();
            });
        });

        describe('run request', () => {
            it('Disables run button', () => {
                let c = controller();
                c.requestSubmitted = true;

                expect(c.isRunDisabled()).toBe(true);

                c.requestSubmitted = false;
                c.targetName = null;
                expect(c.isRunDisabled()).toBe(true);

            });

            it('shows confirmation for the first time and disables after submitting the request', () => {
                let c = controller();
                c.targetName = { key: 10 };
                let selectedName = [
                    { key: 1 },
                    { key: 2 }
                ];
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                namesConsolidationServiceMock.consolidate.returnValue = { status: true };
                c.runRequest();
                expect(c.notificationService.confirm).toHaveBeenCalled();
                expect(namesConsolidationServiceMock.consolidate).toHaveBeenCalled();
                expect(c.requestSubmitted).toBe(true);
            });

            it('doesnt show confirmation message if validation all done', () => {
                let c = controller();

                c.targetName = { key: 10 };
                let selectedName = [
                    { key: 1 },
                    { key: 2 }
                ];
                c.requestSubmitted = true;
                picklistService.openModal.returnValue = selectedName;
                c.openNamesPicklist();
                namesConsolidationServiceMock.consolidate.returnValue = { status: false, errors: [{ nameNo: 1 }] };
                c.runRequest();
                expect(c.notificationService.confirm).toHaveBeenCalled();
                expect(namesConsolidationServiceMock.consolidate).toHaveBeenCalled();

                c.notificationService.confirm.calls.reset();
                namesConsolidationServiceMock.consolidate.calls.reset();

                c.runRequest();
                expect(c.notificationService.confirm).not.toHaveBeenCalled();
                expect(namesConsolidationServiceMock.consolidate).toHaveBeenCalled();
            });
        });

    });
}