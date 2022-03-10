angular.module('inprotech.configuration.rules.workflows').component('ipWorkflowsEventControlEventOccurrence', {
    templateUrl: 'condor/configuration/rules/workflows/eventcontrol/event-occurrence.html',
    bindings: {
        topic: '<'
    },
    controllerAs: 'vm',
    controller: function ($scope, kendoGridBuilder, workflowsEventControlService, inlineEdit, caseValidCombinationService, kendoGridService, workflowsCharacteristicsService) {
        'use strict';

        var vm = this;
        var viewData;
        var service;
        var originalEventList;
        var charsService;
        var createObj;

        vm.$onInit = onInit;

        function onInit() {
            viewData = vm.topic.params.viewData;
            service = workflowsEventControlService;

            vm.canEdit = viewData.canEdit;
            vm.criteriaId = viewData.criteriaId;
            vm.eventId = viewData.eventId;
            vm.hasOffices = viewData.hasOffices;
            vm.formData = viewData.eventOccurrence;

            originalEventList = viewData.eventOccurrence.eventsExist;

            _.extend(vm.topic, {
                getFormData: getFormData,
                hasError: hasError,
                isDirty: isDirty,
                validate: validate
            });

            _.extend(vm, {
                formatPicklistColumn: service.formatPicklistColumn,
                gridOptions: buildGridOptions(),
                eventPicklistScope: service.initEventPicklistScope({
                    criteriaId: vm.criteriaId,
                    filterByCriteria: true
                }),
                matchBoxChanged: matchBoxChanged,
                parentData: (viewData.isInherited && viewData.parent) ? viewData.parent.eventOccurrence : {},
                isCharacteristicInherited: isCharacteristicInherited,
                onAddClick: onAddClick,
                onNameTypeChanged: onNameTypeChanged,
                markDuplicated: markDuplicated,
                validateValidCombinations: validateValidCombinations,
                isEventOccurrenceDisabled: isEventOccurrenceDisabled,
                isWhenAnotherCaseExistsDisabled: isWhenAnotherCaseExistsDisabled
            });

            if (!vm.formData.dueDateOccurs) {
                vm.formData.dueDateOccurs = 'NotApplicable';
            }

            $scope.$watch('vm.topic.params.viewData.dueDateCalcSettings.extendDueDate', function (newValue, oldValue) {
                if (newValue === true && !oldValue) {
                    vm.formData.dueDateOccurs = 'NotApplicable';
                }
            });

            // use scope watch over ng-click because this value can be changed programmatically
            $scope.$watch('vm.formData.dueDateOccurs', function (newValue, oldValue) {
                if (newValue === 'NotApplicable' && oldValue != newValue) {
                    vm.isWhenAnotherCaseExists = false;
                }
            });

            _.forEach(vm.formData.eventsExist, function (e) {
                e.customClassTrigger = e.isInherited;
            });
    
            vm.isWhenAnotherCaseExists = checkDataExists(vm.formData);
    
            charsService = caseValidCombinationService;
            charsService.initFormData(vm.formData.characteristics);
            charsService.addExtendFunctions(vm);

            createObj = inlineEdit.defineModel([{
                name: 'nameType',
                equals: pickListComparer
            }, {
                name: 'caseNameType',
                equals: pickListComparer
            },
                'mustExist'
            ]);
        }

        function isWhenAnotherCaseExistsDisabled() {
            return !vm.canEdit || vm.formData.dueDateOccurs === 'NotApplicable';
        }

        function isEventOccurrenceDisabled() {
            return !vm.canEdit || viewData.dueDateCalcSettings.extendDueDate;
        }       

        function pickListComparer(objA, objB) {
            if (typeof objA === 'object') {
                return objA.key === objB.key;
            }

            return objA === objB;
        }       

        function isCharacteristicInherited() {
            return isPlSameAsParent('office', 'key') &&
                isPlSameAsParent('caseType', 'code') &&
                isPlSameAsParent('jurisdiction', 'code') &&
                isPlSameAsParent('propertyType', 'code') &&
                isPlSameAsParent('caseCategory', 'code') &&
                isPlSameAsParent('subType', 'code') &&
                isPlSameAsParent('basis', 'code') &&
                angular.equals([
                    vm.formData.matchOffice,
                    vm.formData.matchJurisdiction,
                    vm.formData.matchPropertyType,
                    vm.formData.matchCaseCategory,
                    vm.formData.matchSubType,
                    vm.formData.matchBasis
                ], [
                    vm.parentData.matchOffice,
                    vm.parentData.matchJurisdiction,
                    vm.parentData.matchPropertyType,
                    vm.parentData.matchCaseCategory,
                    vm.parentData.matchSubType,
                    vm.parentData.matchBasis
                ]);
        }

        function isPlSameAsParent(pickListName, keyField) {
            return vm.formData.characteristics && vm.parentData.characteristics &&
                (vm.formData.characteristics[pickListName] && vm.formData.characteristics[pickListName][keyField])
                == (vm.parentData.characteristics[pickListName] && vm.parentData.characteristics[pickListName][keyField]);
        }

        function validateValidCombinations() {
            workflowsCharacteristicsService.validate(vm.formData.characteristics, vm.form);
        }

        function buildGridOptions() {
            var prefix = 'workflows.eventcontrol.eventOccurrence.'
            return kendoGridBuilder.buildOptions($scope, {
                id: 'matchNames',
                autoBind: true,
                pageable: false,
                sortable: false,
                actions: vm.canEdit ? {
                    delete: true
                } : null,
                read: function () {
                    return service.getMatchingNameTypes(vm.criteriaId, vm.eventId).then(function (data) {
                        if (data.length > 0) {
                            vm.isWhenAnotherCaseExists = true;
                        }
                        return _.map(data, createObj);
                    });
                },
                autoGenerateRowTemplate: true,
                rowAttributes: vm.canEdit ? 'ng-form="rowForm" ng-class="{error: rowForm.$invalid || dataItem.hasError(), edited: dataItem.added || dataItem.isDirty(), deleted: dataItem.deleted, \'input-inherited\': dataItem.isInherited && !dataItem.isDirty()}"' : 'ng-class="{\'input-inherited\': dataItem.isInherited}"',
                columns: [{
                    fixed: true,
                    width: '35px',
                    template: '<ip-inheritance-icon ng-if="dataItem.isInherited"></ip-inheritance-icon>'
                }, {
                    title: prefix + 'nameType',
                    template: vm.canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.formatPicklistColumn(dataItem.nameType)"></span>' +
                        '{{vm.markDuplicated(dataItem.isDuplicatedRecord, rowForm)}}' +
                        '<ip-typeahead ng-if="!dataItem.deleted"' +
                        ' focus-on-add ip-required label="" name="nameType" ng-model="dataItem.nameType" config="nameType" ng-change="vm.onNameTypeChanged(dataItem, rowForm)"></ip-typeahead>'
                        : '<span ng-bind="vm.formatPicklistColumn(dataItem.nameType)">{{dataItem.nameType}}</span>'
                }, {
                    template: '<span>=</span>'
                }, {
                    title: prefix + 'currentCaseNameType',
                    template: vm.canEdit ? '<span ng-if="dataItem.deleted" ng-bind="vm.formatPicklistColumn(dataItem.caseNameType)"></span>' +
                        '<ip-typeahead ng-if="!dataItem.deleted"' +
                        ' ip-required label="" name="caseNameType" ng-model="dataItem.caseNameType" config="nameType"></ip-typeahead>'
                        : '<span ng-bind="vm.formatPicklistColumn(dataItem.caseNameType)">{{dataItem.caseNameType}}</span>'
                }, {
                    title: prefix + 'mustExist',
                    template: '<ip-checkbox ng-model="dataItem.mustExist" ng-disabled="!vm.canEdit || dataItem.deleted">'
                }]
            });
        }

        function matchBoxChanged() {
            if (vm.formData.matchOffice) {
                vm.formData.characteristics.office = null;
            }

            if (vm.formData.matchJurisdiction) {
                vm.formData.characteristics.jurisdiction = null;
            }

            if (vm.formData.matchPropertyType) {
                vm.formData.characteristics.propertyType = null;
            }

            if (vm.formData.matchCaseCategory) {
                vm.formData.characteristics.caseCategory = null;
            }

            if (vm.formData.matchSubType) {
                vm.formData.characteristics.subType = null;
            }

            if (vm.formData.matchBasis) {
                vm.formData.characteristics.basis = null;
            }

            validateValidCombinations();
        }

        function checkDataExists(data) {
            return (data.characteristics.office && data.characteristics.office.key != null) || data.matchOffice
                || (data.characteristics.caseType && data.characteristics.caseType.key != null)
                || (data.characteristics.jurisdiction && data.characteristics.jurisdiction.key != null) || data.matchJurisdiction
                || (data.characteristics.propertyType && data.characteristics.propertyType.key != null) || data.matchPropertyType
                || (data.characteristics.caseCategory && data.characteristics.caseCategory.key != null) || data.matchCaseCategory
                || (data.characteristics.subType && data.characteristics.subType.key != null) || data.matchSubType
                || (data.characteristics.basis && data.characteristics.basis.key != null) || data.matchBasis
                || (data.eventsExist != null && data.eventsExist.length > 0)
        }

        function onAddClick() {
            var insertIndex = vm.gridOptions.dataSource.total();
            vm.gridOptions.insertRow(insertIndex, {
                added: true
            });
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

        function hasDuplicate() {
            var all = vm.gridOptions.dataSource.data();
            var allApplicable = _.filter(all, function (item) {
                return item.deleted ? false : true;
            });

            for (var i = allApplicable.length - 1; i >= 0; i--) {
                if (setIsDuplicate(allApplicable[i])) {
                    return true;
                }
            }

            return false;
        }

        function onNameTypeChanged(dataItem, rowForm) {
            rowForm.nameType.$setValidity('eventcontrol.eventOccurrence.nameTypeMapped', true);
            dataItem.isDuplicatedRecord = false;
            setIsDuplicate(dataItem);
        }

        function setIsDuplicate(dataItem) {
            if (!dataItem.nameType) {
                return false;
            }

            var all = vm.gridOptions.dataSource.data();
            var everythingElse = _.without(all, dataItem);

            var found = _.find(everythingElse, function (n) {
                return n.nameType && n.nameType.code === dataItem.nameType.code;
            }) != null;

            dataItem.isDuplicatedRecord = found;
            return found;
        }

        // this gets triggered by the angular expression in the template
        function markDuplicated(isDuplicate, rowForm) {
            if (isDuplicate && rowForm.nameType) {
                rowForm.nameType.$setValidity('eventcontrol.eventOccurrence.nameTypeMapped', false);
            }
        }

        function getFormData() {
            var data = {
                updateEventImmediate: vm.formData.dueDateOccurs === 'Immediate',
                updateEventWhenDue: vm.formData.dueDateOccurs === 'OnDueDate'
            };

            var currentEvents = _.pluck(vm.formData.eventsExist, 'key');
            var originalEvents = _.pluck(originalEventList, 'key');
            var addedEvents = [];
            var deletedEvents = [];

            if (vm.isWhenAnotherCaseExists) {
                _.extend(data, {
                    officeId: vm.formData.characteristics.office && vm.formData.characteristics.office.key,
                    officeIsThisCase: vm.formData.matchOffice,
                    caseTypeId: vm.formData.characteristics.caseType && vm.formData.characteristics.caseType.code,
                    countryCode: vm.formData.characteristics.jurisdiction && vm.formData.characteristics.jurisdiction.code,
                    countryCodeIsThisCase: vm.formData.matchJurisdiction,
                    propertyTypeId: vm.formData.characteristics.propertyType && vm.formData.characteristics.propertyType.code,
                    propertyTypeIsThisCase: vm.formData.matchPropertyType,
                    caseCategoryId: vm.formData.characteristics.caseCategory && vm.formData.characteristics.caseCategory.code,
                    caseCategoryIsThisCase: vm.formData.matchCaseCategory,
                    subTypeId: vm.formData.characteristics.subType && vm.formData.characteristics.subType.code,
                    subTypeIsThisCase: vm.formData.matchSubType,
                    basisId: vm.formData.characteristics.basis && vm.formData.characteristics.basis.code,
                    basisIsThisCase: vm.formData.matchBasis
                });

                addedEvents = _.difference(currentEvents, originalEvents);
                deletedEvents = _.difference(originalEvents, currentEvents);

            } else {
                _.each(vm.gridOptions.dataSource.data(), function (d) { d.deleted = true; });
                deletedEvents = originalEvents;
            }

            var delta = service.mapGridDelta(vm.gridOptions.dataSource.data(), convertToSaveModel);
            _.extend(data, {
                nameTypeMapDelta: delta,
                requiredEventRulesDelta: {
                    added: addedEvents,
                    deleted: deletedEvents
                }
            });

            return data;
        }

        function convertToSaveModel(data) {
            return {
                sequence: data.sequence,
                applicableNameTypeKey: data.nameType.code,
                substituteNameTypeKey: data.caseNameType.code,
                mustExist: data.mustExist
            };
        }
    }
});