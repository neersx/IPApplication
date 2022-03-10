angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlDocuments', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/documents.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEntryControlService, kendoGridService, hotkeys) {
        'use strict';

        var vm = this;
        var viewData;
        var criteriaId;
        var entryId;
        var service;
        var canEdit;
        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            criteriaId = viewData.criteriaId;
            entryId = viewData.entryId;
            service = workflowsEntryControlService;
            canEdit = viewData.canEdit;
            //canEdit = true; // should remove after implementing save
            vm.topic.initializeShortcuts = initShortcuts;

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate
            });


            vm.canEdit = canEdit;
            vm.gridOptions = buildGridOptions();
            vm.onAddClick = onAddClick;
            vm.checkDuplicate = checkDuplicate;
            vm.onDocumentChanged = onDocumentChanged;
            vm.topic.initializeShortcuts = initShortcuts;
            vm.topic.initialised = true;
        }

        function initShortcuts() {
            if (viewData.canEdit) {
                hotkeys.add({
                    combo: 'alt+shift+i',
                    description: 'shortcuts.add',
                    callback: onAddClick
                });
            }
        }

        function getFormData() {
            var delta = mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            return {
                DocumentsDelta: delta
            };
        }

        function hasError() {
            return vm.form.$invalid;
        }

        function isDirty() {
            return vm.form.$dirty || kendoGridService.isGridDirty(vm.gridOptions);
        }

        function validate() {
            return vm.form.$validate() && !hasDuplicate();
        }

        function convertToSaveModel(data) {
            return {
                documentId: data.document.key,
                mustProduce: data.mustProduce,
                previousDocumentId: data.previousDocumentId
            };
        }

        function mapGridDelta(data, mapFunc) {
            return {
                added: _.chain(data).filter(isAdded).map(mapFunc).value(),
                deleted: _.chain(data).filter(isDeleted).map(mapFunc).value(),
                updated: _.chain(data).filter(isUpdated).map(mapFunc).value()
            };
        }

        function isAdded(data) {
            return (data.added || data.isAdded) && !data.deleted;
        }

        function isDeleted(data) {
            return data.deleted;
        }

        function isUpdated(data) {
            return (data.isEdited || data.isDirty && data.isDirty()) && !data.deleted && !(data.added || data.isAdded);
        }

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'documentsGrid',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                titlePrefix: 'workflows.entrycontrol.documents',
                actions: canEdit ? {
                    delete: true
                } : null,
                read: function () {
                    return service.getDocuments(criteriaId, entryId)
                        .then(function (records) {
                            return _.each(records, function (r) {
                                r.previousDocumentId = r.document.key;
                            });
                        });

                },
                autoGenerateRowTemplate: canEdit,
                rowAttributes: canEdit ? 'ng-form="rowForm" ng-class="{error: rowForm.$invalid, edited: dataItem.isEdited || dataItem.added ||dataItem.deleted, deleted: dataItem.deleted,' +
                    '\'input-inherited\': dataItem.isInherited && !dataItem.isEdited}"' : '',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>',
                    oneTimeBinding: true
                }, {
                    title: '.document',
                    width: '75%',
                    template: canEdit ? '<span ng-if="dataItem.deleted" ng-bind="dataItem.document.value"></span>' +
                        '{{vm.checkDuplicate(dataItem.isDuplicatedRecord, rowForm)}}' +
                        '<ip-typeahead data-picklist-can-maintain="true" ng-if="!dataItem.deleted" focus-on-add ip-required label="" name="document" ng-model="dataItem.document" ng-change="vm.onDocumentChanged(dataItem, rowForm)" data-config="document"></ip-typeahead>' : '<span ng-bind="dataItem.document.value"></span>'
                }, {
                    title: '.mustProduce',
                    width: '20%',
                    template: canEdit ? '<ip-checkbox ng-model="dataItem.mustProduce" ng-change="dataItem.isEdited = true"></ip-checkbox>' : '<ip-checkbox ng-model="dataItem.mustProduce" disabled></ip-checkbox>'
                }]
            });
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            vm.gridOptions.insertRow(insertIndex, {
                added: true,
                mustProduce: false
            });
        }

        function checkDuplicate(isDuplicatedRecord, rowForm) {
            if (isDuplicatedRecord) {
                rowForm.document.$setValidity('duplicate', false);
            }
        }

        function onDocumentChanged(dataItem, rowForm) {
            dataItem.isEdited = true;
            rowForm.document.$setValidity('duplicate', true);
            dataItem.isDuplicatedRecord = false;
            if (isDuplicate(dataItem)) {
                rowForm.document.$setValidity('duplicate', false);
            }
        }

        function isDuplicate(dataItem) {
            var all = vm.gridOptions.dataSource.data();
            return service.isDuplicated(_.without(all, dataItem), dataItem, ['document']);
        }

        function hasDuplicate() {
            var all = vm.gridOptions.dataSource.data();
            return hasDuplicates(all, ['document']);
        }

        function hasDuplicates(allRecords, propList) {
            allRecords = _.filter(allRecords, function (item) {
                return item.deleted ? false : true;
            });

            for (var i = allRecords.length - 1; i >= 0; i--) {
                var exists = service.isDuplicated(_.without(allRecords, allRecords[i]), allRecords[i], propList);
                if (exists) {
                    allRecords[i].isDuplicatedRecord = true;
                    return true;
                }
            }
            return false;
        }        
    }
});