angular.module('inprotech.configuration.general.jurisdictions')
    .directive('ipJurisdictionClasses', function () {
        'use strict';
        return {
            restrict: 'E',
            scope: {
                parentId: '='
            },
            controller: 'ClassesController',
            controllerAs: 'vm',
            templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/classes.html',
            bindToController: {
                topic: '='
            }
        };
    })
    .controller('ClassesController', function ($scope, kendoGridBuilder, jurisdictionClassesService, dateService, modalService, $translate, picklistService, notificationService) {
        'use strict';

        var vm = this;
        var parentId;
        vm.$onInit = onInit;

        function onInit() {
            parentId = $scope.parentId;
            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;
            vm.onViewItemClick = onViewItemClick;
            vm.allowSubClass = allowSubClass;
            vm.itemMaintenanceToolTip = itemMaintenanceToolTip;
            vm.shouldDisable = shouldDisable;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.hasError = angular.noop;
            vm.gridOptions = buildGridOptions();
            vm.countryCode = $scope.parentId;
            vm.topic.initialised = true;

            setActiveTopic();
        }

        function setActiveTopic() {
            if (vm.topic.activeTopic && vm.topic.activeTopic === "classes") {
                vm.topic.isActive = true;
            }
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'localClasses',
                topicItemNumberKey: vm.topic.key,
                scrollable: false,
                reorderable: false,
                navigatable: true,
                selectable: 'row',
                pageable: false,
                serverSorting: true,
                serverFiltering: false,
                autoBind: true,
                noRecords: {
                    template: '<br><div align="left" style="margin-left: 2.7%">{{"jurisdictions.maintenance.classes.noLocalClasses" | translate}}</div>'
                },
                detailTemplate: parentId !== 'ZZZ' ?
                    '<ipt-jurisdiction-class-detail data-content="dataItem" data-has-int-classes="true"></ipt-jurisdiction-class-detail>' : '<ipt-jurisdiction-class-detail data-content="dataItem" data-has-int-classes="false"></ipt-jurisdiction-class-detail>',
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, error: dataItem.error}" uib-tooltip="{{dataItem.errorMessage}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                actions: vm.topic.canUpdate ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: true,
                    custom: {
                        template: '<ip-icon-button ng-if="vm.allowSubClass(dataItem)" class="btn-no-bg" data-ng-click="vm.onViewItemClick(dataItem)" button-icon="cpa-icon cpa-icon-items-o" data-tooltip-placement="top" ip-tooltip="{{ vm.itemMaintenanceToolTip(dataItem) }}" ng-disabled = "vm.shouldDisable(dataItem)" >< /ip-icon-button>'
                    }
                } : {
                        custom: {
                            template: '<ip-icon-button ng-if="vm.allowSubClass(dataItem)" class="btn-no-bg" data-ng-click="vm.onViewItemClick(dataItem)" button-icon="cpa-icon cpa-icon-items-o" data-tooltip-placement="top" ip-tooltip="{{ vm.itemMaintenanceToolTip(dataItem) }}" ng-disabled = "vm.shouldDisable(dataItem)" >< /ip-icon-button>'
                        }
                    },
                read: function (queryParams) {
                    if (vm.gridOptions.getQueryParams() !== null)
                        queryParams = vm.gridOptions.getQueryParams();

                    return jurisdictionClassesService.search(queryParams, parentId);
                },
                columns: configureColumns(parentId !== 'ZZZ')
            });
        }

        function configureColumns(showIntClasses) {
            var columns = [{
                title: 'jurisdictions.maintenance.classes.class',
                field: 'class',
                sortable: true
            }, {
                title: 'jurisdictions.maintenance.classes.heading',
                field: 'description',
                sortable: true
            }, {
                title: 'jurisdictions.maintenance.classes.internationalClasses.heading',
                field: 'intClasses',
                sortable: false
            }, {
                title: 'jurisdictions.maintenance.classes.subClass',
                field: 'subClass',
                sortable: true
            }, {
                title: 'jurisdictions.maintenance.classes.effectiveDate',
                field: 'effectiveDate',
                sortable: true,
                template: '<span>{{ dataItem.effectiveDate | localeDate }}</span>'
            }, {
                title: 'jurisdictions.maintenance.classes.propertyType',
                field: 'propertyType',
                sortable: true
            }];

            if (!showIntClasses) {
                return _.reject(columns, function (col) {
                    return col.field === 'intClasses';
                });
            }
            return columns;
        }

        function onAddClick() {
            openClassesMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openClassesMaintenance('edit', dataItem);
        }

        function onViewItemClick(dataItem) {
            vm.currentFilter = {
                class: dataItem.class,
                subClass: dataItem.subClass,
                propertyType: dataItem.propertyTypeCode
            };
            picklistService.openModal($scope, {
                type: 'classItems',
                canMaintain: true,
                canAddAnother: true,
                displayName: _.isEmpty(vm.currentFilter.subClass) ? $translate.instant('jurisdictions.maintenance.classes.lblClassItemMaintenance', {
                    class: vm.currentFilter.class
                }) : $translate.instant('jurisdictions.maintenance.classes.lblSubClassItemMaintenance', {
                    class: vm.currentFilter.class,
                    subclass: vm.currentFilter.subClass
                }),
                fieldLabel: _.isEmpty(vm.currentFilter.subClass) ? $translate.instant('jurisdictions.maintenance.classes.lblFieldClassItemMaintenance', {
                    class: vm.currentFilter.class
                }) : $translate.instant('jurisdictions.maintenance.classes.lblFieldSubClassItemMaintenance', {
                    class: vm.currentFilter.class,
                    subclass: vm.currentFilter.subClass
                }),
                appendPicklistLabel: false,
                extendQuery: includeFilter,
                initialViewData: {
                    class: vm.currentFilter.class,
                    subClass: vm.currentFilter.subClass,
                    countryCode: $scope.parentId,
                    propertyType: vm.currentFilter.propertyType
                }
            }).then(confirmRefresh, confirmRefresh);
        }

        function confirmRefresh() {
            if (isDirty()) {
                notificationService.confirm({
                    message: 'modal.unsavedchanges.refreshConfirmation'
                }).then(function () {
                    vm.gridOptions.search();
                });
            } else {
                vm.gridOptions.search();
            }
        }

        function includeFilter(query) {
            var extended = angular.extend({}, query, {
                class: vm.currentFilter.class,
                subClass: vm.currentFilter.subClass,
                country: $scope.parentId,
                propertyType: vm.currentFilter.propertyType
            });
            return extended;
        }

        function allowSubClass(dataItem) {
            return dataItem.allowSubClass === 2;
        }

        function shouldDisable(dataItem) {
            return dataItem.isAdded || dataItem.deleted || dataItem.isEdited;
        }

        function itemMaintenanceToolTip(dataItem) {
            return $translate.instant('jurisdictions.maintenance.classes.itemMaintenance') + ' (' + dataItem.itemsCount + ')';
        }

        function addItem(newData) {
            vm.gridOptions.insertAfterSelectedRow(newData);
        }

        function openClassesMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'ClassesMaintenance',
                mode: mode,
                isAddAnother: false,
                controllerAs: 'vm',
                addItem: addItem,
                dataItem: dataItem,
                allItems: vm.gridOptions.dataSource.data(),
                parentId: parentId,
                jurisdiction: vm.topic.jurisdiction
            });
        }

        function isDirty() {
            var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
            var dirtyGrid = data && _.any(data, function (item) {
                return item.isAdded || item.deleted || item.isEdited;
            });
            return dirtyGrid;
        }

        function getTopicFormData() {
            return {
                classesDelta: getDelta()
            };
        }

        function getDelta() {
            var added = getSaveModel(function (data) {
                return data.isAdded && !data.deleted;
            });

            var updated = getSaveModel(function (data) {
                return data.isEdited && !data.isAdded;
            });

            var deleted = getSaveModel(function (data) {
                return data.deleted;
            });

            return {
                added: added,
                updated: updated,
                deleted: deleted
            };
        }

        function getSaveModel(filter) {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(filter)
                .map(convertToSaveModel)
                .value();
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                class: dataItem.class,
                countryId: $scope.parentId,
                description: dataItem.description,
                sequenceNo: dataItem.sequenceNo,
                subClass: dataItem.subClass,
                propertyType: dataItem.propertyTypeCode,
                notes: dataItem.notes,
                allowSubClass: dataItem.allowSubClass,
                effectiveDate: dataItem.effectiveDate,
                intClasses: dataItem.intClasses
            };

            return updatedRecord;
        }

    });