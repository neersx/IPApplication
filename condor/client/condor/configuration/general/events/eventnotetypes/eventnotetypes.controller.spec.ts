namespace inprotech.configuration.general.events.eventnotetypes {

    describe('inprotech.configuration.general.events.eventnotetypes.EventNoteTypesController', () => {
        'use strict';

        let controller: (dependencies?: any) => EventNoteTypesController, scope: ng.IScope,
            notificationService: any, kendoGridBuilder: any, EventNoteTypesService: IEventNoteTypesService,
            entityStates: any, modalService: any, bulkMenuOperationsMock: any, hotkeys: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.events.eventnotetypes');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks.configuration.general.events.eventnotetypes', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification', 'inprotech.mocks']);

                EventNoteTypesService = $injector.get<IEventNoteTypesService>('EventNoteTypesServiceMock');
                $provide.value('EventNoteTypesService', EventNoteTypesService);

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

                return new EventNoteTypesController(scope, dependencies.viewData, EventNoteTypesService, kendoGridBuilder, entityStates, modalService, notificationService, bulkMenuOperationsMock, $timeout, jasmine.createSpyObj('hotkeys', ['add', 'del']), $translate);
            };
        }));

        describe('initialize view model', () => {
            let c: EventNoteTypesController;
            it('should initialize grid builder options along with search criteria', () => {

                c = controller();
                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
                expect(c.context).toBe('eventnotetypes');
            });
        });

        describe('add event note type', () => {
            it('should call modalService and entity state should be adding', () => {
                let c = controller();

                let entity = new EventNoteTypeModel();
                entity.state = entityStates.adding;

                c.add();

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'EventNoteTypesMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(null),
                        allItems: c.gridOptions.data(),
                        callbackFn: c.gridOptions.search
                    })));
            });
        });

        describe('edit event note type', () => {
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

                let editMenuItem = _.filter(c.eventNoteTypes.items, (item: any) => {
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
                let editMenuItem = _.filter(c.eventNoteTypes.items, (item: any) => {
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
                        id: 'EventNoteTypesMaintenance',
                        entity: entity,
                        controllerAs: 'vm',
                        dataItem: c.getEntityFromGrid(entity.id),
                        allItems: c.gridOptions.data(),
                    })));
            });
        });


        describe('delete event note type', () => {
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
                spyOn(c, 'doSearch');

                let response = {
                    data: {
                        message: 'deleted'
                    }
                };

                spyOn(EventNoteTypesService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                c.deleteSelectedEventNoteTypes();
                expect(EventNoteTypesService.deleteSelected).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
                expect(c.gridOptions.search).toHaveBeenCalled();
            });
            it('should call notification alert when some of selected event note type are in use', () => {
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
                        message: 'event note type in use',
                        inUseIds: [1]
                    }
                };

                spyOn(EventNoteTypesService, 'markInUseEventNoteTypes');
                spyOn(EventNoteTypesService, 'deleteSelected').and.callFake(() => {
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

                c.bulkMenuOperations.selectedRecord = bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{ id: 1 }, { id: 2 }]);
                c.deleteSelectedEventNoteTypes();

                expect(EventNoteTypesService.deleteSelected).toHaveBeenCalled();
                expect(EventNoteTypesService.markInUseEventNoteTypes).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
            it('should call notification alert when all the selected event note type are in use', () => {
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
                        message: 'event note type in use',
                        inUseIds: [1, 3]
                    }
                };

                spyOn(EventNoteTypesService, 'deleteSelected').and.callFake(() => {
                    return {
                        then: (fn) => {
                            fn(response);
                        }
                    };
                });

                spyOn(EventNoteTypesService, 'markInUseEventNoteTypes');

                let expected = {
                    title: 'modal.unableToComplete',
                    message: 'modal.alert.alreadyInUse'
                };

                c.bulkMenuOperations.selectedRecord = bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{ id: 1 }, { id: 3 }]);
                c.deleteSelectedEventNoteTypes();

                expect(EventNoteTypesService.deleteSelected).toHaveBeenCalled();
                expect(EventNoteTypesService.markInUseEventNoteTypes).toHaveBeenCalled();
                expect(notificationService.alert).toHaveBeenCalledWith(expected);
            });
        });
    });
}