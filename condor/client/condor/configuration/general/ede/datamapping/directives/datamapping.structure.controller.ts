namespace inprotech.configuration.general.ede.datamapping {

    export class DataMappingStructureController {
        static $inject = ['$scope', 'DataMappingService', 'kendoGridBuilder', 'BulkMenuOperations', 'states', 'modalService', 'notificationService', 'hotkeys'];

        bulkMenuOperations;
        gridOptions;
        context;
        menuActions;
        topic;

        constructor(private $scope: any, private dataMappingService: IDataMappingService, private kendoGridBuilder, bulkMenuOperations, private states, private modalService, private notificationService, private hotkeys) {
            this.topic = $scope.$topic;
            this.context = this.topic.key;
            this.gridOptions = this.buildGridOptions();
            this.menuActions = this.buildMenu();
            this.bulkMenuOperations = new bulkMenuOperations(this.context);
            this.topic.initShortcuts = this.initShortcuts;
        }

        doSearch = (queryParams) => {
            return this.dataMappingService.search(this.topic.parentId, this.topic.key, queryParams).then(response => {
                return response.structureDetails.mappings;
            });
        }

        fieldTemplate = (dataItem) => {
            if (!dataItem.output || (!dataItem.output.key && !dataItem.output.value)) {
                return '';
            }
            return '<span>{{ dataItem.output.value }}</span>' + '<span>{{ dataItem.output.key }}</span>';
        }

        columns = () => {
            return [{
                fixed: true,
                width: '35px',
                sortable: false,
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.menuActions.items" data-context="' + this.context + '" data-initialised="vm.menuActions.initialised()" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'dataMapping.maintenance.inputDescription',
                field: 'inputDesc',
                width: '300px',
                sortable: false,
                oneTimeBinding: true,
                template: '<span ng-class="pointerCursor" ng-bind="dataItem.inputDesc"></span>'
            }, {
                title: 'dataMapping.maintenance.systemEvent',
                field: 'output',
                sortable: false,
                width: '400px',
                oneTimeBinding: true,
                template: (dataItem) => {
                    return this.fieldTemplate(dataItem);
                }
            }, {
                title: 'dataMapping.maintenance.ignore',
                field: 'notApplicable',
                sortable: false,
                template: '<input type="checkbox" ng-model="dataItem.notApplicable" disabled="disabled"></input>',
                width: '150px',
                oneTimeBinding: true
            }];
        }

        buildGridOptions = () => {
            return this.kendoGridBuilder.buildOptions(this.$scope, {
                id: this.context,
                pageable: true,
                navigatable: true,
                reorderable: false,
                selectable: 'row',
                scrollable: false,
                autoBind: true,
                read: (queryParams) => this.doSearch(queryParams),
                onDataCreated: (queryParams) => {
                    this.bulkMenuOperations.selectionChange(this.gridOptions.data())
                },
                columns: this.columns()
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

        confirmAndDeleteSelected = () => {
            if (this.bulkMenuOperations.selectedRecords(this.gridOptions.data()).length <= 0) {
                return;
            }

            this.notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(() => {
                this.deleteSelected();
            });
        }

        deleteSelected = () => {
            this.dataMappingService.deleteSelected(this.bulkMenuOperations.selectedRecords(this.gridOptions.data())).then(
                (response) => {
                    this.notificationService.success();
                    this.gridOptions.search();
                });
        }

        actions = (): Array<IMenuAction> => {
            return [{
                id: 'edit',
                enabled: this.anySelected.bind(this),
                click: this.edit.bind(this),
                maxSelection: 1
            }, {
                id: 'delete',
                enabled: this.anySelected.bind(this),
                click: this.confirmAndDeleteSelected.bind(this)
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
            let entity: ITopicEntity = {};
            this.openDocumentMaintenance(entity, this.states.adding);
        }

        edit = (id: number): void => {
            let entityId: number = id === undefined ? this.bulkMenuOperations.selectedRecord(this.gridOptions.data()).id : id;
            this.dataMappingService.get(this.topic.parentId, entityId)
                .then((entity: ITopicEntity) => {
                    this.openDocumentMaintenance(entity, this.states.updating);
                });
        }

        openDocumentMaintenance = (entity: ITopicEntity, state) => {
            entity.state = state;
            let modalOptions: ITopicModalOptions = {
                id: 'DataMappingMaintenance',
                entity: entity || {},
                controllerAs: 'vm',
                dataItem: this.getEntityFromGrid(entity.id),
                allItems: this.gridOptions.data(),
                structure: this.topic.key,
                dataSource: this.topic.parentId,
                callbackFn: this.gridOptions.search
            };
            this.modalService.openModal(modalOptions);
        }

        getEntityFromGrid = (id) => {
            return _.find(this.gridOptions.data(), (item: ITopicEntity) => {
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
                        this.confirmAndDeleteSelected();
                    }
                }
            };

            this.hotkeys.add(addShortcut);
            this.hotkeys.add(deleteShortcut)
        }
    }

    angular.module('inprotech.configuration.general.ede.datamapping')
        .controller('DataMappingStructureController', DataMappingStructureController);
}

