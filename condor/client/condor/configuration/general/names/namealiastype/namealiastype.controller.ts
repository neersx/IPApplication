namespace inprotech.configuration.general.names.namealiastype {

    export class NameAliasTypeController {
        static $inject = ['$scope', 'viewData', 'NameAliasTypeService', 'kendoGridBuilder', 'states', 'modalService', 'BulkMenuOperations', 'notificationService', '$translate', 'hotkeys', '$timeout'];
        context;
        gridOptions;
        form;
        searchCriteria;
        nameAliasTypes;
        viewData;
        bulkMenuOperations;

        constructor(private $scope: ng.IScope, viewData, private nameAliasTypeService: INameAliasTypeService, private kendoGridBuilder, private states, private modalService, bulkMenuOperations, private notificationService, private $translate, private hotkeys, private $timeout) {
            this.context = 'nameAliasTypes';
            this.gridOptions = this.buildGridOptions();
            this.nameAliasTypes = this.buildMenu();
            this.bulkMenuOperations = new bulkMenuOperations(this.context);
            this.viewData = viewData;
            this.$timeout(this.initShortcuts, 500);
        }

        doSearch = () => {
            return this.nameAliasTypeService.search(this.searchCriteria, this.gridOptions.getQueryParams());
        }

        buildGridOptions = () => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: 'searchResults',
                navigatable: true,
                reorderable: false,
                autoGenerateRowTemplate: true,
                autoBind: true,
                selectable: 'row',
                scrollable: false,
                rowAttributes: 'ng-class="{saved: dataItem.saved, error: dataItem.inUse === true && dataItem.selected === true}"',
                onDataCreated: () => {
                    this.nameAliasTypeService.persistSavedNameAliasTypes(this.gridOptions.data());
                    this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                },
                read: () => { return this.doSearch(); },
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                    headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.nameAliasTypes.items" data-context="nameAliasTypes" data-initialised="vm.nameAliasTypes.initialised()" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
                }, {
                    title: 'nameAliasType.type',
                    field: 'code',
                    width: '300px',
                    oneTimeBinding: true,
                    template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.code"></a>'
                }, {
                    title: 'nameAliasType.description',
                    field: 'description',
                    oneTimeBinding: true,
                    template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.description"></a>'
                }, {
                    title: 'nameAliasType.unique',
                    field: 'isUnique',
                    template: '<input type="checkbox" ng-model="dataItem.isUnique" disabled="disabled"></input>',
                    width: '300px',
                    oneTimeBinding: true
                }
                ]
            });
        }

        clearAll = (): void => {
            return this.bulkMenuOperations.clearAll(this.gridOptions.data());
        }

        selectAll = (val): void => {
            return this.bulkMenuOperations.selectAll(this.gridOptions.data(), val);
        }

        selectionChange = (dataItem): void => {
            if (dataItem && dataItem.inUse && dataItem.selected) {
                dataItem.inUse = false;
            }
            return this.bulkMenuOperations.selectionChange(this.gridOptions.data());
        }

        anySelected = () => {
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
                click: this.confirmAndDeleteSelectedNameAliasType.bind(this)
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

        add = (): void => {
            let entity: INameAliasEntity = {};
            this.openNameAliasTypeMaintenance(entity, this.states.adding);
        }

        edit = (id): void => {
            let nameAliasTypeId = this.getSelectedEntityId(id);
            this.nameAliasTypeService.get(nameAliasTypeId)
                .then((entity: INameAliasEntity) => {
                    this.openNameAliasTypeMaintenance(entity, this.states.updating);
                });
        }

        duplicate = (): void => {
            let nameAliasTypeId = this.getSelectedEntityId(null);
            this.nameAliasTypeService.get(nameAliasTypeId).then((entity: INameAliasEntity) => {
                let entityToBeAdded = angular.copy(entity);
                entityToBeAdded.id = null;
                this.openNameAliasTypeMaintenance(entityToBeAdded, this.states.duplicating);
            });
        }

        getSelectedEntityId = (id) => {
            if (id !== undefined && id !== null) {
                return id;
            }
            return this.bulkMenuOperations.selectedRecord(this.gridOptions.data()).id;
        }

        confirmAndDeleteSelectedNameAliasType = () => {
            if (this.bulkMenuOperations.selectedRecords(this.gridOptions.data()).length <= 0) {
                return;
            }

            this.notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(() => {
                this.deleteSelectedNameAliasType();
            });
        }

        deleteSelectedNameAliasType = () => {
            this.nameAliasTypeService.deleteSelected(this.bulkMenuOperations.selectedRecords(this.gridOptions.data())).then(
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
                            this.nameAliasTypeService.markInUseNameTypeAlias(this.gridOptions.data(), response.data.inUseIds);
                            this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                        });
                    } else {
                        this.notificationService.success(response.data.message);
                        this.gridOptions.search();
                    }
                });
        }

        openNameAliasTypeMaintenance = (entity: INameAliasEntity, state) => {
            entity.state = state;
            let modalOptions: INameAliasModalOptions = {
                id: 'NameAliasTypeMaintenance',
                entity: entity || {},
                controllerAs: 'vm',
                dataItem: this.getEntityFromGrid(entity.id),
                allItems: this.gridOptions.data(),
                callbackFn: this.gridOptions.search
            };
            this.modalService.openModal(modalOptions);
        }

        getEntityFromGrid = (id) => {
            return _.find(this.gridOptions.data(), (item: INameAliasEntity) => {
                return item.id === id;
            });
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
                        this.confirmAndDeleteSelectedNameAliasType();
                    }
                }
            };

            this.hotkeys.add(addShortcut);
            this.hotkeys.add(deleteShortcut);
        }
    }
    angular.module('inprotech.configuration.general.names.namealiastype')
        .controller('NameAliasTypeController', NameAliasTypeController);
}