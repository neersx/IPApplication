angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlDocuments', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/documents.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, $translate, kendoGridBuilder, modalService, workflowsEventControlService, kendoGridService, hotkeys) {
        'use strict';

        var service;
        var viewData;
        var eventControlPrefix;        
        var documentsPrefix;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowsEventControlService
            viewData = vm.topic.params.viewData;
            eventControlPrefix = 'workflows.eventcontrol.';
            documentsPrefix = eventControlPrefix + 'documents.';
            vm.topic.initializeShortcuts = initShortcuts;

            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getFormData;

            _.extend(vm, {
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                canEdit: viewData.canEdit,
                gridOptions: buildGridOptions(),
                onAddClick: onAddClick,
                onEditClick: onEditClick,
                showPeriodType: showPeriodType,
                showProduce: showProduce
            });
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

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'documentsGrid',
                autoBind: true,
                pageable: false,
                sortable: false,
                actions: viewData.canEdit ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: true
                } : null,
                topicItemNumberKey: {
                    key: vm.topic.key,
                    isSubSection: true
                },
                read: function () {
                    return service.getDocuments(viewData.criteriaId, viewData.eventId);
                },
                autoGenerateRowTemplate: true,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted, deleted: dataItem.deleted, ' +
                    ' \'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>',
                    oneTimeBinding: true
                }, {
                    title: documentsPrefix + 'document',
                    field: 'document',
                    template: '{{ (dataItem.document && dataItem.document.value) ? dataItem.document.value : "" }}'
                }, {
                    title: documentsPrefix + 'produce',
                    field: 'produce',
                    template: '{{vm.showProduce(dataItem.produce)}}'
                }, {
                    title: eventControlPrefix + 'startBefore',
                    field: 'startBefore',
                    template: '{{vm.showPeriodType(dataItem.startBefore)}}'
                }, {
                    title: eventControlPrefix + 'repeatEvery',
                    field: 'repeatEvery',
                    template: '{{vm.showPeriodType(dataItem.repeatEvery)}}'
                }, {
                    title: eventControlPrefix + 'stopAfter',
                    field: 'stopTime',
                    template: '{{vm.showPeriodType(dataItem.stopTime)}}'
                }, {
                    title: documentsPrefix + 'maxDocuments',
                    field: 'maxDocuments'
                }]
            });
        }

        function showProduce(produce) {
            if (produce == null) {
                return '';
            }

            return $translate.instant(documentsPrefix + produce);
        }

        function showPeriodType(dataAttribute) {
            if (dataAttribute == null) {
                return '';
            }

            var type = $translate.instant(service.translatePeriodType(dataAttribute.type));
            return dataAttribute.value == null ? type : dataAttribute.value + ' ' + type;
        }

        function addItem(newData) {
            var insertIndex = vm.gridOptions.dataSource.data().length + 1;
            vm.gridOptions.dataSource.insert(insertIndex, newData);
        }

        function onAddClick() {
            openDocumentsMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openDocumentsMaintenance('edit', dataItem);
        }

        function openDocumentsMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'DocumentsMaintenance',
                /* hide this id to framework */
                mode: mode,
                /* pass all data */
                /* shouldn't specifiy template url*/
                /* it should be passed in the id for the actual modal content */
                // templateUrl: 'condor/configuration/rules/workflows/eventcontrol/documents-maintenance.html',
                dataItem: dataItem || {},
                allItems: vm.gridOptions.dataSource.data(),
                criteriaId: viewData.criteriaId,
                eventId: viewData.eventId,
                eventDescription: viewData.overview.data.description,
                isAddAnother: false,
                addItem: addItem
            });
        }

        function getFormData() {
            var delta = service.mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);

            return {
                documentDelta: delta
            };
        }

        function isDirty() {
            return kendoGridService.isGridDirty(vm.gridOptions);
        }

        function convertToSaveModel(data) {
            var scheduleObject = {};
            if (data.produce === 'asScheduled') {
                _.extend(scheduleObject, {
                    startBeforeTime: data.startBefore && data.startBefore.value,
                    startBeforePeriod: data.startBefore && data.startBefore.type,
                    repeatEveryTime: data.repeatEvery ? data.repeatEvery.value : 0,
                    repeatEveryPeriod: data.repeatEvery ? data.repeatEvery.type : data.startBefore.type,

                    stopTimePeriod: data.stopTime && data.stopTime.type,
                    stopTime: data.stopTime && data.stopTime.value
                });


            } else {
                _.extend(scheduleObject, {
                    startBeforeTime: null,
                    startBeforePeriod: null,
                    repeatEveryTime: null,
                    repeatEveryPeriod: null,

                    stopTimePeriod: null,
                    stopTime: null
                });
            }
            return _.extend({
                sequence: data.sequence,
                documentId: data.document && data.document.key,
                produceWhen: data.produce,

                maxDocuments: data.maxDocuments,
                chargeType: data.chargeType && data.chargeType.key,

                isPayFee: data.isPayFee,
                isRaiseCharge: data.isRaiseCharge,
                isEstimate: data.isEstimate,
                isDirectPay: data.isDirectPay,
                isCheckCycleForSubstitute: data.isCheckCycleForSubstitute
            }, scheduleObject);
        }
    }
});