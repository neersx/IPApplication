namespace inprotech.configuration.general.names.namerelations {

    export class NameRelationController {
        static $inject = ['$scope', 'NameRelationService', 'kendoGridBuilder', 'BulkMenuOperations', 'hotkeys', '$timeout', 'modalService', 'states', 'notificationService', '$translate'];
        context;
        gridOptions;
        form;
        searchCriteria;
        menuActions;
        bulkMenuOperations;

        constructor(private $scope: ng.IScope, private nameRelationService: INameRelationService, private kendoGridBuilder, bulkMenuOperations, private hotkeys, private $timeout, private modalService, private states, private notificationService, private $translate) {
            this.context = 'namerelation';
            this.gridOptions = this.buildGridOptions();
            this.menuActions = this.buildMenu();
            this.bulkMenuOperations = new bulkMenuOperations(this.context);
            this.$timeout(this.initShortcuts, 500);
        }

        doSearch = () => {
            return this.nameRelationService.search(this.searchCriteria, this.gridOptions.getQueryParams());
        }

        columns: any = () => {
            return [{
                fixed: true,
                width: '35px',
                template: '<ip-checkbox data-ng-id="checkbox_row_{{dataItem.id}}" ng-model="dataItem.selected" ng-change="vm.selectionChange(dataItem)"></ip-checkbox>',
                headerTemplate: '<div data-bulk-actions-menu data-items="vm.gridOptions.data()" data-actions="vm.menuActions.items" data-context="namerelation" data-initialised="vm.menuActions.initialised()" data-on-clear="vm.clearAll();" data-on-select-all="vm.selectAll(val)"></div>'
            }, {
                title: 'namerelation.relationshipcode',
                field: 'relationshipCode',
                width: '300px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.relationshipCode"></a>'
            },
            {
                title: 'namerelation.relationshipdesc',
                field: 'relationshipDescription',
                width: '300px',
                sortable: true,
                template: '<a ng-click="vm.edit(dataItem.id)" ng-class="pointerCursor" ng-bind="dataItem.relationshipDescription"></a>'
            },
            {
                title: 'namerelation.reverserelationship',
                field: 'reverseDescription',
                width: '300px',
                sortable: true,
            },
            {
                title: 'namerelation.employee',
                field: 'isEmployee',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isEmployee" disabled="disabled"></input>'
            }
                ,
            {
                title: 'namerelation.individual',
                field: 'isIndividual',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isIndividual" disabled="disabled"></input>'
            },
            {
                title: 'namerelation.organisation',
                field: 'isOrganisation',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isOrganisation" disabled="disabled"></input>'
            },
            {
                title: 'namerelation.crm',
                field: 'isCrmOnly',
                sortable: true,
                template: '<input type="checkbox" ng-model="dataItem.isCrmOnly" disabled="disabled"></input>'
            },
            {
                title: 'namerelation.ethicalwall',
                field: 'ethicalWallValue',
                width: '300px',
                sortable: true
            }
            ];
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
                    this.nameRelationService.persistSavedNameRelationship(this.gridOptions.data());
                    this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                },
                read: () => { return this.doSearch(); },
                columns: this.columns()
            });
        }

        clearAll = () => {
            return this.bulkMenuOperations.clearAll(this.gridOptions.data());
        }

        selectAll = (val) => {
            return this.bulkMenuOperations.selectAll(this.gridOptions.data(), val);
        }

        selectionChange = (dataItem) => {
            if (dataItem && dataItem.inUse && dataItem.selected) {
                dataItem.inUse = false;
            }
            return this.bulkMenuOperations.selectionChange(this.gridOptions.data());
        }

        anySelected = () => {
            return this.bulkMenuOperations.anySelected(this.gridOptions.data());
        }

        buildMenu = () => {
            return {
                items: [{
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
                    click: this.confirmAndDeleteSelectedNameRelationship.bind(this)
                }],
                initialised: () => {
                    if (this.gridOptions.data()) {
                        this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                    }
                }
            };
        }

        add = () => {
            let entity = {};
            this.openNameRelationMaintenance(entity, this.states.adding);
        }

        edit(id: number) {
            let namerelationid: number = this.getSelectedEntityId(id);
            this.nameRelationService.get(namerelationid)
                .then((entity) => {
                    this.openNameRelationMaintenance(entity, this.states.updating);
                });
        }

        duplicate = () => {
            let namerelationid: number = this.getSelectedEntityId(null);
            this.nameRelationService.get(namerelationid).then((entity) => {
                let entityToBeAdded = angular.copy(entity);
                entityToBeAdded.id = null;
                this.openNameRelationMaintenance(entityToBeAdded, this.states.duplicating);
            });
        }

        getSelectedEntityId = (id) => {
            if (id !== undefined && id !== null) {
                return id;
            }
            return this.bulkMenuOperations.selectedRecord(this.gridOptions.data()).id;
        }

        confirmAndDeleteSelectedNameRelationship() {
            if (this.bulkMenuOperations.selectedRecords(this.gridOptions.data()).length <= 0) {
                return;
            }

            this.notificationService.confirmDelete({
                message: 'modal.confirmDelete.message'
            }).then(() => {
                this.deleteSelectedNameRelationship();
            });
        }

        deleteSelectedNameRelationship() {
            this.nameRelationService.deleteSelected(this.bulkMenuOperations.selectedRecords(this.gridOptions.data())).then(
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
                            this.nameRelationService.markInUseNameRelationship(this.gridOptions.data(), response.data.inUseIds);
                            this.bulkMenuOperations.selectionChange(this.gridOptions.data());
                        });
                    } else {
                        this.notificationService.success(response.data.message);
                        this.gridOptions.search();
                    }
                });
        }

        openNameRelationMaintenance = (entity, state) => {
            entity.currentState = state;
            this.modalService.openModal({
                id: 'NameRelationMaintenance',
                entity: entity || {},
                controllerAs: 'vm',
                dataItem: this.getEntityFromGrid(entity.id),
                allItems: this.gridOptions.data(),
                callbackFn: this.gridOptions.search
            });
        }

        getEntityFromGrid = (id) => {
            return _.find(this.gridOptions.data(), (item: INameRelationEntity) => {
                return item.id === id;
            });
        }

        initShortcuts = () => {
            this.hotkeys.add({
                combo: 'alt+shift+i',
                description: 'shortcuts.add',
                callback: () => {
                    if (this.modalService.canOpen()) {
                        this.add();
                    }
                }
            });

            this.hotkeys.add({
                combo: 'alt+shift+del',
                description: 'shortcuts.delete',
                callback: () => {
                    if (this.modalService.canOpen()) {
                        this.confirmAndDeleteSelectedNameRelationship();
                    }
                }
            });
        }
    }
    angular.module('inprotech.configuration.general.names.namerelations')
        .controller('NameRelationController', NameRelationController);
}