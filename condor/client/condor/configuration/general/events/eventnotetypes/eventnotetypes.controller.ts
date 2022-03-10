namespace inprotech.configuration.general.events.eventnotetypes {
    export class EventNoteTypesController {
        static $inject = ['$scope', 'viewData', 'EventNoteTypesService', 'kendoGridBuilder', 'states', 'modalService', 'notificationService', 'BulkMenuOperations', '$timeout', 'hotkeys', '$translate'];

        searchOptions;
        gridOptions;
        form;
        searchCriteria;
        context;
        viewData;
        bulkMenuOperations;
        eventNoteTypes;

        constructor(private $scope: ng.IScope, viewData, private eventNoteTypeService: IEventNoteTypesService, private kendoGridBuilder, private states, private modalService, private notificationService, private BulkMenuOperations, private $timeout: any, private hotkeys: any, private $translate: any) {
            this.gridOptions = this.buildGridOptions();
            this.context = 'eventnotetypes';
            this.bulkMenuOperations = new this.BulkMenuOperations(this.context);
            this.viewData = viewData;
            this.eventNoteTypes = this.buildMenu();
            this.$timeout(this.initShortcuts, 500);
        }

        doSearch = () => {
            return this.eventNoteTypeService.search(this.searchCriteria, this.gridOptions.getQueryParams());
        }

        columns = (): Array<IGridColumn> => {
            return [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.eventNoteTypes.items" data-context="eventnotetypes" data-initialised="vm.eventNoteTypes.initialised()" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'eventNoteType.description',
                field: 'description',
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>',
                oneTimeBinding: true
            }, {
                title: 'eventNoteType.sharingEventNotes',
                field: 'sharingAllowed',
                template: '<input type="checkbox" ng-model="dataItem.sharingAllowed" disabled="disabled"></input>',
                oneTimeBinding: true
            }, {
                title: 'eventNoteType.public',
                field: 'isExternal',
                template: '<input type="checkbox" ng-model="dataItem.isExternal" disabled="disabled"></input>',
                oneTimeBinding: true
            }];
        }

        buildGridOptions = () => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'searchResults',
                navigatable: true,
                reorderable: false,
                autoGenerateRowTemplate: true,
                filterable: true,
                autoBind: true,
                selectable: 'row',
                scrollable: false,
                rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
                onDataCreated: () => {
                    this.eventNoteTypeService.persistSavedEventNoteTypes(this.gridOptions.data());
                    this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                },
                read: () => { return this.doSearch(); },
                columns: this.columns()
            });
        }

        add = () => {
            let entity = new EventNoteTypeModel();
            this.openEventNoteTypesMaintenance(entity, this.states.adding);
        }

        openEventNoteTypesMaintenance = (entity: EventNoteTypeModel, state) => {
            entity.state = state;
            let modalOptions: IEventNoteTypeModalOptions = {
                id: 'EventNoteTypesMaintenance',
                entity: entity || new EventNoteTypeModel(),
                controllerAs: 'vm',
                dataItem: this.getEntityFromGrid(entity.id),
                allItems: this.gridOptions.data(),
                callbackFn: this.gridOptions.search
            };
            this.modalService.openModal(modalOptions);
        }

        getEntityFromGrid = (id: number | null) => {
            if (id === undefined || id === null) { return null; }
            return _.find(this.gridOptions.data(), (item: any) => {
                return item.id === id;
            });
        }

        clearAll = (): any => {
            return this.bulkMenuOperations.clearAll(this.gridOptions.data());
        }

        selectAll = (val): any => {
            return this.bulkMenuOperations.selectAll(this.gridOptions.data(), val);
        }

        selectionChange = (dataItem): any => {
            if (dataItem && dataItem.inUse && dataItem.selected) {
                dataItem.inUse = false;
            }
            return this.bulkMenuOperations.selectionChange(this.gridOptions.data());
        }

        anySelected = (): boolean => {
            return this.bulkMenuOperations.anySelected(this.gridOptions.data());
        }

        actions = (): Array<IMenuAction> => {
            return [{
                id: 'edit',
                enabled: this.anySelected.bind(this),
                click: this.edit.bind(this),
                maxSelection: 1
            }, {
                id: 'duplicate',
                enabled: this.anySelected.bind(this),
                click: this.duplicate.bind(this),
                maxSelection: 1
            }, {
                id: 'delete',
                enabled: this.anySelected.bind(this),
                click: this.confirmAndDeleteSelectedEventNoteTypes.bind(this)
            }]
        }

        buildMenu = () => {
            return {
                items: this.actions(),
                initialised: () => {
                    if (this.gridOptions.data()) {
                        this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                    }
                }
            };
        }

        confirmAndDeleteSelectedEventNoteTypes = (): void => {
            if (this.bulkMenuOperations.selectedRecords(this.gridOptions.data()).length <= 0) { return };
            this.notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(() => {
                this.deleteSelectedEventNoteTypes();
            });
        }

        deleteSelectedEventNoteTypes = (): void => {
            this.eventNoteTypeService.deleteSelected(this.bulkMenuOperations.selectedRecords(this.gridOptions.data())).then(
                (response) => {
                    if (response.data.hasError) {
                        let allInUse = this.bulkMenuOperations.selectedRecords(this.gridOptions.data()).length === response.data.inUseIds.length;

                        let message = allInUse ? this.$translate.instant('modal.alert.alreadyInUse') :
                            this.$translate.instant('modal.alert.partialComplete') + '<br/>' + this.$translate.instant('modal.alert.alreadyInUse');
                        let title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';

                        this.gridOptions.search().then(() => {
                            this.notificationService.alert({
                                title: title,
                                message: message
                            });
                            this.eventNoteTypeService.markInUseEventNoteTypes(this.gridOptions.data(), response.data.inUseIds);
                            this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                        });
                    } else {
                        this.notificationService.success(response.data.message);
                        this.gridOptions.search();
                    }
                });
        }

        getSelectedEntityId = (id: number | null): any => {
            if (id !== undefined && id !== null) {
                return id;
            }
            return this.bulkMenuOperations.selectedRecord(this.gridOptions.data()).id;
        }

        edit = (id: number): void => {
            let eventNoteTypeId = this.getSelectedEntityId(id);
            this.eventNoteTypeService.get(eventNoteTypeId)
                .then((entity) => {
                    this.openEventNoteTypesMaintenance(entity, this.states.updating);
                });
        }

        duplicate = (): void => {
            let eventNoteTypeId = this.getSelectedEntityId(null);
            this.eventNoteTypeService.get(eventNoteTypeId).then((entity) => {
                let entityToBeAdded = angular.copy(entity);
                entityToBeAdded.id = null;
                entityToBeAdded.description = this.getDescriptionText(entity.description.trim());
                this.openEventNoteTypesMaintenance(entityToBeAdded, this.states.duplicating);
            });
        }

        getDescriptionText = (description: string): string => {
            let appendText = ' - Copy';
            let maxlength = 250 - appendText.length;
            if (description.length > maxlength) {
                description = description.substring(0, maxlength);
            }
            return description + appendText;
        }

        initShortcuts = () => {
            let addShortcut: IHotKey = {
                combo: 'alt+shift+i',
                description: 'shortcuts.add',
                callback: () => {
                    if (this.modalService.canOpen()) {
                        this.add();
                    }
                }
            };

            let deleteShortcut: IHotKey = {
                combo: 'alt+shift+del',
                description: 'shortcuts.delete',
                callback: () => {
                    if (this.modalService.canOpen()) {
                        this.confirmAndDeleteSelectedEventNoteTypes();
                    }
                }
            };

            this.hotkeys.add(addShortcut);
            this.hotkeys.add(deleteShortcut);
        }
    }
    angular.module('inprotech.configuration.general.events.eventnotetypes')
        .controller('EventNoteTypesController', EventNoteTypesController);
}
