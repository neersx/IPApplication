namespace inprotech.configuration.general.names.locality {

    describe('inprotech.configuration.general.names.locality.LocalityController', () => {
        'use strict';

        let controller: (dependencies?: any) => LocalityController, scope: ng.IScope,
            notificationService: any, kendoGridBuilder: any, LocalityService: ILocalityService,
            entityStates: any, modalService: any, bulkMenuOperationsMock: any, hotkeys: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.locality');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.configuration.general.names.locality', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification', 'inprotech.mocks']);

                LocalityService = $injector.get<ILocalityService>('LocalityServiceMock');
                $provide.value('LocalityService', LocalityService);

                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                $provide.value('kendoGridBuilder', kendoGridBuilder);

                notificationService = $injector.get('notificationServiceMock');
                $provide.value('notificationService', notificationService);

                modalService = $injector.get('modalServiceMock');
                $provide.value('modalService', modalService);

                bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');
                $provide.value('BulkMenuOperations', bulkMenuOperationsMock)

                hotkeys = $injector.get('hotkeysMock');
                $provide.value('hotkeys', hotkeys);
            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService, $translate: any, states: any, $timeout) => {
            scope = <ng.IScope>$rootScope.$new();
            entityStates = states;
            controller = (dependencies?) => {
                dependencies = angular.extend({
                    viewData: {}
                }, dependencies);
                return new LocalityController(scope, dependencies.viewData, LocalityService, kendoGridBuilder, entityStates, modalService, bulkMenuOperationsMock, notificationService, $translate, jasmine.createSpyObj('hotkeys', ['add', 'del']), $timeout);
            };
        }));

        describe('initialize view model', () => {
            let c: LocalityController;
            it('should initialize grid builder options along with search criteria', () => {

                c = controller();
                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
                expect(c.context).toBe('locality');
            });
        });

        describe('add locality', () => {
            it('should call modalService and entity state should be adding', () => {
                let c = controller();

                let entity = {
                    currentState: entityStates.adding
                };

                c.add();

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'LocalityMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(null),
                        allItems: c.gridOptions.data(),
                    })));
            });
        });

        describe('edit locality', () => {
            it('should not be available if no record is selected', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1
                    }, {
                        id: 2
                    }];
                };

                c.bulkMenuOperations.anySelected = bulkMenuOperationsMock.prototype.anySelected.and.returnValue(false);

                let editMenuItem = _.filter(c.menuActions.items, (item: any) => {
                    return item.id === 'edit';
                });
                expect(editMenuItem[0].enabled()).toBe(false);
            });
            it('should be available if record is selected', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1,
                        selected: true
                    }, {
                        id: 2
                    }];
                };
                c.bulkMenuOperations.anySelected = bulkMenuOperationsMock.prototype.anySelected.and.returnValue(true);
                let editMenuItem = _.filter(c.menuActions.items, (item: any) => {
                    return item.id === 'edit';
                });
                expect(editMenuItem[0].enabled()).toBe(true);
            });
            it('should call modalService and entity state should be updating', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1,
                        selected: true
                    }, {
                        id: 2
                    }];
                };

                let entity = {
                    id: 1,
                    description: 'entity description',
                    currentState: 'updating',
                };

                c.edit(1);

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'LocalityMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(entity.id),
                        allItems: c.gridOptions.data(),
                    })));
            });
        });


        describe('delete locality', () => {
            it('should call notification success and should initialize the grid', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1,
                        selected: true
                    }, {
                        id: 2,
                        selected: false
                    }, {
                        id: 3,
                        selected: true
                    }];
                };

                let response = {
                    data: {
                        message: 'deleted'
                    }
                };

                spyOn(LocalityService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                spyOn(c, 'doSearch');

                c.deleteSelectedLocality();
                expect(LocalityService.deleteSelected).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
            it('should call notification alert when some of selected locality are in use', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1,
                        selected: true
                    }, {
                        id: 2,
                        selected: false
                    }, {
                        id: 3,
                        selected: true
                    }];
                };

                let response = {
                    data: {
                        hasError: true,
                        message: 'locality in use',
                        inUseIds: [1]
                    }
                };

                spyOn(LocalityService, 'markInUseLocalities');
                spyOn(LocalityService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                let expected = {
                    title: 'modal.partialComplete',
                    message: 'modal.alert.partialComplete<br/>modal.alert.alreadyInUse'
                };

                c.bulkMenuOperations.selectedRecord = bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{ id: 'abc' }, { id: '123' }]);
                c.deleteSelectedLocality();

                expect(LocalityService.deleteSelected).toHaveBeenCalled();
                expect(LocalityService.markInUseLocalities).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
            it('should call notification alert when all the selected locality are in use', () => {
                let c = controller();
                c.gridOptions.data = () => {
                    return [{
                        id: 1,
                        selected: true
                    }, {
                        id: 2,
                        selected: false
                    }, {
                        id: 3,
                        selected: true
                    }];
                };

                let response = {
                    data: {
                        hasError: true,
                        message: 'delete in use',
                        inUseIds: [1, 3]
                    }
                };

                spyOn(LocalityService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                spyOn(LocalityService, 'markInUseLocalities');

                let expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };

                c.bulkMenuOperations.selectedRecord = bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{ id: 'abc' }, { id: '123' }]);
                c.deleteSelectedLocality();

                expect(LocalityService.deleteSelected).toHaveBeenCalled();
                expect(LocalityService.markInUseLocalities).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
        });
    });
}