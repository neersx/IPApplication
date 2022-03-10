angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlSteps', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/steps.html',
    controllerAs: 'vm',
    bindings: {
        topic: '<'
    },
    controller: function ($scope, kendoGridBuilder, modalService, workflowsEntryControlStepsService, $translate, hotkeys, notificationService) {
        'use strict';

        var stepService;
        var viewData;
        var criteriaId;
        var entryId;
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            stepService = workflowsEntryControlStepsService;
            vm.stepService = stepService;
            viewData = vm.topic.params.viewData;
            vm.topic.isDirty = isDirty;
            vm.topic.hasError = hasError;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.setError = setError;
            criteriaId = viewData.criteriaId;
            entryId = viewData.entryId;

            vm.canEdit = viewData.canEdit;
            vm.gridOptions = buildGridOptions();
            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;
            vm.editItem = editItem;
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

        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'steps',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                selectable: true,
                titlePrefix: 'workflows.entrycontrol.steps',
                autoGenerateRowTemplate: true,
                rowDraggable: vm.canEdit,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted || dataItem.moved, ' +
                    'error: dataItem.error, deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited&&!dataItem.isEdited }" uib-tooltip="{{dataItem.errorMessage}}" tooltip-class="tooltip-error" data-tooltip-placement="left"',
                read: function () {
                    return stepService.getSteps(criteriaId, entryId);
                },
                actions: vm.canEdit ? {
                    edit: {
                        onClick: 'vm.onEditClick(dataItem)'
                    },
                    delete: true
                } : null,
                onDropCompleted: function (args) {
                    args.source.moved = true;
                },
                columns: [{
                    fixed: true,
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>',
                    width: '35px',
                    oneTimeBinding: true
                }, {
                    title: '.defaultTitle',
                    field: 'step.value',
                    oneTimeBinding: true
                }, {
                    title: '.title',
                    field: 'title',
                    width: '15%'
                }, {
                    title: '.screenTip',
                    field: 'screenTip',
                    width: '30%'
                }, {
                    title: '.mandatory',
                    template: '<ip-checkbox ng-model="dataItem.isMandatory" disabled></ip-checkbox>'
                }, {
                    title: '.category',
                    template: '<div ng-repeat="category in dataItem.categories" ng-if="dataItem.categories && dataItem.categories.length>0">' +
                        '<span translate="{{vm.stepService.translateStepCategory(category.categoryName)}}"></span>' +
                        '<span ng-if="vm.stepService.categoryDisplay(category)">:&nbsp;{{ vm.stepService.categoryDisplay(category) }}</span>' +
                        '</div>'
                }]
            });
        }

        function isDirty() {
            var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
            var dirtyGrid = data && _.any(data, function (item) {
                return item.isAdded || item.isEdited || item.deleted || item.moved;
            });

            return dirtyGrid;
        }

        function hasError() {
            var errorInGrid = _.countBy(vm.gridOptions.dataSource.data(), function (i) {
                return i.error == true && (i.deleted == false || i.deleted == undefined);
            }).true > 0;

            return errorInGrid && isDirty();
        }

        function convertToSaveModel(dataItem) {
            var updatedRecord = {
                id: dataItem.id,
                screenName: dataItem.step.key,
                screenType: dataItem.step.type,
                title: dataItem.title,
                screenTip: dataItem.screenTip,
                isMandatory: dataItem.isMandatory,
                newItemId: dataItem.newId,
                relativeId: dataItem.relativeId
            };

            updatedRecord.categories = _.map(dataItem.categories, function (c) {
                return {
                    categoryCode: c.categoryCode,
                    categoryValue: c.categoryValue
                }
            }) || [];

            return updatedRecord;
        }

        function setRelativeStepId(item) {
            var relativeItem = vm.gridOptions.getRelativeItemAbove(item);
            if (relativeItem != null) {
                item.relativeId = relativeItem.id ? relativeItem.id : relativeItem.newId;
            }
        }

        function getSaveModel(filter) {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(filter)
                .map(convertToSaveModel)
                .value();
        }

        function setIdsForNewItems() {
            var i = 0;
            _.chain(vm.gridOptions.dataSource.data())
                .filter(function (data) {
                    return data.isAdded && !data.deleted;
                })
                .each(function (n) {
                    n.newId = getNewId(i++);
                });
        }

        function getNewId(i) {
            var letterA = 65;
            var newLetter = letterA + i;
            if (newLetter > 126) {
                notificationService.alert({
                    message: $translate.instant('workflows.entrycontrol.steps.tooManyAdditions'),
                    title: $translate.instant('modal.unableToComplete')
                });
                throw new Error('Too many new steps added. Rectify and try again.');
            }
            return String.fromCharCode(newLetter);
        }

        function getStepsDelta() {
            setIdsForNewItems();

            _.chain(vm.gridOptions.dataSource.data())
                .filter(function (d) {
                    return d.isAdded
                })
                .each(setRelativeStepId);

            var added = getSaveModel(function (data) {
                return data.isAdded && !data.deleted;
            });
            var updated = getSaveModel(function (data) {
                return data.isEdited && !data.deleted && !data.isAdded;
            });
            var deleted = getSaveModel(function (data) {
                return data.deleted;
            });

            return {
                added: added,
                updated: updated,
                deleted: deleted
            }
        }

        function getMovedSteps() {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(function (d) {
                    //Do not consider newly added records - since it already has relativeStepId
                    // Do not consider deleted records - cause it does not make sense
                    if (d.isAdded || d.deleted) {
                        return false;
                    }

                    return d.moved;
                })
                .map(function (d) {
                    var relativeItem = vm.gridOptions.getRelativeItemAbove(d);
                    return {
                        stepId: d.id,
                        prevStepIdentifier: !relativeItem ? null : (relativeItem.id ? relativeItem.id : relativeItem.newId)
                    };
                })
                .value();
        }

        function getTopicFormData() {
            return {
                stepsDelta: getStepsDelta(),
                stepsMoved: getMovedSteps()
            };
        }

        function setError(errors) {
            _.chain(errors)
                .where({
                    field: 'title'
                })
                .each(applyError);

            _.chain(errors)
                .where({
                    field: 'categoryValue'
                })
                .each(applyError);
        }

        function applyError(error) {
            var item = _.find(vm.gridOptions.dataSource.data(), function (i) {
                return i.id === error.id || i.newId === error.id;
            });
            if (item) {
                item.error = true;
                item.errorMessage = $translate.instant('row.' + error.message);
            }
        }

        function clearExistingDisplayValue(dataItem, newData) {
            _.each(dataItem.categories, function (c) {
                var changedCategory = _.find(newData.categories || [], function (item) {
                    return item.categoryCode === c.categoryCode;
                });

                if (!c.categoryValue || !changedCategory.categoryValue) {
                    return;
                }

                if (changedCategory.categoryValue.key !== c.categoryValue.key) {
                    c.categoryValue = null;
                }
            });
        }

        function onAddClick() {
            openEntryStepsMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openEntryStepsMaintenance('edit', dataItem)
                .then(function (newData) {
                    editItem(dataItem, newData);
                });
        }

        function addItem(newData) {
            vm.gridOptions.insertAfterSelectedRow(newData);
        }

        function editItem(dataItem, newData) {
            clearExistingDisplayValue(dataItem, newData);
            angular.merge(dataItem, newData);
        }

        function openEntryStepsMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'EntryStepsMaintenance',
                mode: mode,
                dataItem: dataItem || {},
                criteriaId: viewData.criteriaId,
                criteriaCharacteristics: viewData.characteristics,
                entryId: viewData.entryId,
                entryDescription: viewData.description,
                all: vm.gridOptions.dataSource.data(),
                editItem: vm.editItem,
                isAddAnother: false,
                addItem: addItem
            });
        }        
    }
});