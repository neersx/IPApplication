namespace inprotech.configuration.general.names.namealiastype {
    describe('inprotech.configuration.general.names.namealiastype.NameAliasTypeController', () => {
        'use strict';

        let controller: (dependencies?: any) => NameAliasTypeController, scope: ng.IScope,
            notificationService: any, kendoGridBuilder: any, NameAliasTypeService: INameAliasTypeService,
            entityStates: any, modalService: any, bulkMenuOperationsMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.namealiastype');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.configuration.general.names.namealiastype', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification', 'inprotech.mocks']);

                NameAliasTypeService = $injector.get<INameAliasTypeService>('NameAliasTypeServiceMock');
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                notificationService = $injector.get('notificationServiceMock');
                modalService = $injector.get('modalServiceMock');
                bulkMenuOperationsMock = $injector.get('BulkMenuOperationsMock');

            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService, $translate: any, states: any, $timeout) => {
            scope = <ng.IScope>$rootScope.$new();
            entityStates = states;
            controller = (dependencies?) => {
                dependencies = angular.extend({
                    viewData: {}
                }, dependencies);
                return new NameAliasTypeController(scope, dependencies.viewData, NameAliasTypeService, kendoGridBuilder, entityStates, modalService, bulkMenuOperationsMock, notificationService, $translate, jasmine.createSpyObj('hotkeys', ['add', 'del']), $timeout);
            };
        }));

        describe('initialize view model', () => {
            let c: NameAliasTypeController;
            it('should initialize grid builder options along with search criteria', () => {

                c = controller();
                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
                expect(c.context).toBe('nameAliasTypes');
            });
        });

        describe('add name alias type', () => {
            it('should call modalService and entity state should be adding', () => {
                let c = controller();

                let entity = {
                    state: entityStates.adding
                };

                c.add();

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'NameAliasTypeMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(null),
                        allItems: c.gridOptions.data(),
                    })));
            });
        });

        describe('edit name alias type', () => {
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

                let editMenuItem = _.filter(c.nameAliasTypes.items, (item: any) => {
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
                let editMenuItem = _.filter(c.nameAliasTypes.items, (item: any) => {
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
                    state: 'updating',
                };

                c.edit(1);

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'NameAliasTypeMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(entity.id),
                        allItems: c.gridOptions.data(),
                    })));
            });
        });


        describe('delete name alias type', () => {
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

                spyOn(NameAliasTypeService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                spyOn(c, 'doSearch');

                c.deleteSelectedNameAliasType();
                expect(NameAliasTypeService.deleteSelected).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
            it('should call notification alert when some of selected name alias type are in use', () => {
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
                        message: 'name alias type in use',
                        inUseIds: [1]
                    }
                };

                spyOn(NameAliasTypeService, 'markInUseNameTypeAlias');
                spyOn(NameAliasTypeService, 'deleteSelected').and.callFake(() => {
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
                c.deleteSelectedNameAliasType();

                expect(NameAliasTypeService.deleteSelected).toHaveBeenCalled();
                expect(NameAliasTypeService.markInUseNameTypeAlias).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
            it('should call notification alert when all the selected name alias type are in use', () => {
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
                        message: 'name alias type in use',
                        inUseIds: [1, 3]
                    }
                };

                spyOn(NameAliasTypeService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                spyOn(NameAliasTypeService, 'markInUseNameTypeAlias');

                let expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };

                c.bulkMenuOperations.selectedRecord = bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{ id: 'abc' }, { id: '123' }]);
                c.deleteSelectedNameAliasType();

                expect(NameAliasTypeService.deleteSelected).toHaveBeenCalled();
                expect(NameAliasTypeService.markInUseNameTypeAlias).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
        });
    });
}