angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEntryControlDetails', {
    templateUrl: 'condor/configuration/rules/workflows/entrycontrol/details.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEntryControlService, ExtObjFactory, hotkeys, modalService) {
        'use strict';

        var vm = this;
        var criteriaId;
        var entryId;
        var extObjFactory = new ExtObjFactory().useDefaults();
        var state = extObjFactory.createContext();
        vm.$onInit = onInit;
        var service = workflowsEntryControlService;
        var viewData;

        function onInit() {
            viewData = vm.topic.params.viewData;
            criteriaId = viewData.criteriaId;
            entryId = viewData.entryId;            

            vm.canEdit = viewData.canEdit;
            vm.onAddClick = onAddClick;
            vm.onEditClick = onEditClick;
            vm.gridOptions = buildGridOptions();
            vm.translateDateOption = service.translateDateOption;
            vm.translateControlOption = service.translateControlOption;
            vm.formData = state.attach(viewData);
            vm.fieldClasses = fieldClasses;
            vm.topic.hasError = hasError;
            vm.topic.isDirty = isDirty;
            vm.topic.getFormData = getTopicFormData;
            vm.topic.setError = setError;
            vm.combinedFieldTemplate = combinedFieldTemplate;
            vm.topic.initializeShortcuts = initShortcuts;
            vm.parentData = (viewData.isInherited === true && viewData.parent) ? {
                atLeastOneEventFlag: viewData.parent.atLeastOneEventFlag,
                policeImmediately: viewData.parent.policeImmediately,
                officialNumberType: viewData.parent.officialNumberType,
                fileLocation: viewData.parent.fileLocation
            } : {};

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
                id: 'detailsGrid',
                topicItemNumberKey: vm.topic.key,
                autoBind: true,
                pageable: false,
                sortable: false,
                selectable: true,
                titlePrefix: 'workflows.entrycontrol.details',
                read: function () {
                    return service.getDetails(criteriaId, entryId);
                },
                autoGenerateRowTemplate: true,
                rowDraggable: vm.canEdit,
                rowAttributes: 'ng-class="{edited: dataItem.isAdded || dataItem.isEdited || dataItem.deleted || dataItem.moved, error: dataItem.error, deleted: dataItem.deleted,' +
                    '\'input-inherited\': dataItem.isInherited&&!dataItem.isEdited}"',
                actions: viewData.canEdit ? {
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
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited && !dataItem.isEdited"></ip-inheritance-icon>'
                }, {
                    title: '.event',
                    template: '{{ vm.combinedFieldTemplate(dataItem.entryEvent.value,dataItem.entryEvent.key) }}'
                }, {
                    title: '.eventDate',
                    template: '{{ vm.translateDateOption(dataItem.eventDate) | translate}}'
                }, {
                    title: '.dueDate',
                    template: '{{ vm.translateDateOption(dataItem.dueDate) | translate}}'
                }, {
                    title: '.alsoUpdates',
                    template: '{{ vm.combinedFieldTemplate(dataItem.eventToUpdate.value,dataItem.eventToUpdate.key) }}'
                }, {
                    title: '.period',
                    template: '{{ vm.translateControlOption(dataItem.period) | translate}}',
                    oneTimeBinding: true
                }, {
                    title: '.policing',
                    template: '{{ vm.translateControlOption(dataItem.policing) | translate}}',
                    oneTimeBinding: true
                }, {
                    title: '.dueDateResp',
                    template: '{{ vm.translateControlOption(dataItem.dueDateResp) | translate}}',
                    oneTimeBinding: true
                }, {
                    title: '.overridingEvent',
                    template: '{{ vm.translateDateOption(dataItem.overrideEventDate) | translate}}',
                    oneTimeBinding: true
                }, {
                    title: '.overridingDue',
                    template: '{{ vm.translateDateOption(dataItem.overrideDueDate) | translate}}',
                    oneTimeBinding: true
                }]
            });
        }

        function fieldClasses(field) {
            return '{edited: vm.formData.isDirty(\'' + field + '\')}';
        }

        function combinedFieldTemplate(fieldValue, fieldInBrackets) {
            if (fieldValue && fieldInBrackets)
                return fieldValue + " (" + fieldInBrackets + ")";
            if (fieldValue)
                return fieldValue;
            if (fieldInBrackets)
                return fieldInBrackets
            return "";
        }

        function hasError() {
            var errorInGrid = _.countBy(vm.gridOptions.dataSource.data(), function (i) {
                return i.error == true && (i.deleted == false || i.deleted == undefined);
            }).true > 0;

            return (vm.form.$invalid || errorInGrid) && isDirty();
        }

        function isDirty() {
            var data = vm.gridOptions && vm.gridOptions.dataSource && vm.gridOptions.dataSource.data();
            var dirtyGrid = data && _.any(data, function (item) {
                return item.isAdded || item.isEdited || item.deleted || item.moved;
            });

            return state.isDirty() || dirtyGrid;
        }

        function setError(errors) {
            _.chain(errors)
                .where({
                    field: 'entryEvents'
                })
                .each(applyError);
        }

        function applyError(error) {
            var item = _.find(vm.gridOptions.dataSource.data(), function (i) {
                return i.entryEvent.key === error.id;
            });
            if (item) {
                item.error = true;
            }
        }

        function convertToSaveModel(dataItem) {
            return {
                eventId: dataItem.entryEvent.key,
                alsoUpdateEventId: dataItem.eventToUpdate ? dataItem.eventToUpdate.key : null,
                eventAttribute: dataItem.eventDate,
                dueAttribute: dataItem.dueDate,
                policingAttribute: dataItem.policing,
                dueDateResponsibleNameAttribute: dataItem.dueDateResp,
                overrideDueAttribute: dataItem.overrideDueDate,
                overrideEventAttribute: dataItem.overrideEventDate,
                periodAttribute: dataItem.period,
                relativeEventId: dataItem.relativeEventId,
                previousEventId: dataItem.previousEventId
            };
        }

        function getSaveModel(filter) {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(filter)
                .map(convertToSaveModel)
                .value();
        }

        function setRelativeEventId(item) {
            var relativeItem = vm.gridOptions.getRelativeItemAbove(item);
            if (relativeItem != null) {
                item.relativeEventId = relativeItem.entryEvent.key;
            }
        }

        function getEntryEventDelta() {
            _.chain(vm.gridOptions.dataSource.data())
                .filter(function (d) {
                    return d.isAdded || d.isEdited || d.deleted
                })
                .each(setRelativeEventId);

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

        function getMovedEntryEvents() {
            return _.chain(vm.gridOptions.dataSource.data())
                .filter(function (d) {
                    return d.moved;
                })
                .map(function (d) {
                    var relativeItem = vm.gridOptions.getRelativeItemAbove(d);
                    return {
                        eventId: d.entryEvent.key,
                        prevEventId: !relativeItem ? null : relativeItem.entryEvent.key
                    };
                })
                .value();
        }

        function getTopicFormData() {
            var otherDetails = {
                officialNumberTypeId: vm.formData.officialNumberType ? vm.formData.officialNumberType.key : null,
                fileLocationId: vm.formData.fileLocation ? vm.formData.fileLocation.key : null,
                shouldPoliceImmediate: vm.formData.policeImmediately,
                atLeastOneFlag: vm.formData.atLeastOneEventFlag
            }
            return _.extend(otherDetails, {
                entryEventDelta: getEntryEventDelta(),
                entryEventsMoved: getMovedEntryEvents()
            });
        }

        function onAddClick() {
            openEntryEventMaintenance('add').then(function (newData) {
                addItem(newData);
            });
        }

        function onEditClick(dataItem) {
            openEntryEventMaintenance('edit', dataItem);
        }

        function addItem(newData) {
            vm.gridOptions.insertAfterSelectedRow(newData);
        }

        function openEntryEventMaintenance(mode, dataItem) {
            return modalService.openModal({
                id: 'EntryEventMaintenance',
                mode: mode,
                dataItem: dataItem || {},
                criteriaId: viewData.criteriaId,
                entryId: viewData.entryId,
                entryDescription: viewData.description,
                all: vm.gridOptions.dataSource.data(),
                isAddAnother: false,
                addItem: addItem
            });
        }        
    }
});