angular.module('inprotech.configuration.rules.workflows').controller('WorkflowsSearchController', function ($scope, $state, $element, viewData, kendoGridBuilder, sharedService, workflowsSearchService, focusService, menuSelection, modalService, BulkMenuOperations, hotkeys) {
    'use strict';

    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {
        vm.searchBy = 'characteristics';
        vm.validate = validate;
        vm.search = search;
        vm.gridOptions = buildGridOptions();
        vm.reset = reset;
        vm.isSearchDisabled = isSearchDisabled;
        vm.optionChange = optionChange;
        vm.prepareToGoDetail = prepareToGoDetail;
        vm.mounted = {
            characteristics: true
        };
        vm.initializeShortcuts = initShortcuts;
        bulkMenuOperations = new BulkMenuOperations('workflowSearch');

        vm.menu = buildMenu();
        vm.openCharacteristicModal = openCharacteristicModal;

        vm.noResultsHint = getNoResultsHint;

        sharedService.reset();
        sharedService.hasOffices = viewData.hasOffices;
        sharedService.includeProtectedCriteria = viewData.maintainWorkflowRulesProtected;
    }


    function optionChange() {
        vm.mounted[vm.searchBy] = true;
        if (sharedService[vm.searchBy]) {
            sharedService[vm.searchBy].onEnter();
        }
        focusService.autofocus($element, 100);
    }

    function isSearchDisabled() {
        if (!sharedService[vm.searchBy]) {
            return true;
        }

        return sharedService[vm.searchBy].isSearchDisabled();
    }

    function validate() {
        if (!sharedService[vm.searchBy]) {
            return true;
        }

        return sharedService[vm.searchBy].validate();
    }

    function search() {
        vm.gridOptions.search().then(function () {
            vm.menu.clearAll();
            if (vm.gridOptions.data().length === 0) {
                if (sharedService[vm.searchBy]) {
                    if (sharedService[vm.searchBy].selectedMatchType() === 'best-criteria-only' ||
                        sharedService[vm.searchBy].selectedMatchType() === 'best-match') {
                        vm.noResultsHint = 'workflows.search.noResultsHintBestCriteriaAndMatch';
                    } else {
                        vm.noResultsHint = 'noResultsFound';
                    }
                }
            }
        });
    }

    function reset() {
        sharedService[vm.searchBy].reset();
        vm.gridOptions.clear();
        vm.menu.clearAll();
    }

    function prepareToGoDetail() {
        sharedService.selectedEventInDetail = sharedService.lastSearch.args[0].event;
        sharedService.activeTopicKey = null;
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            pageable: true,
            scrollable: true,
            navigatable: true,
            selectable: 'row',
            selectOnNavigate: true,
            onSelect: function () {
                var row = vm.gridOptions.selectFocusedRow();
                vm.prepareToGoDetail();
                $state.go('workflows.details', {
                    id: row.id
                });
            },
            read: function (queryParams) {

                if ($state.current && $state.current.name === 'workflows.details' && sharedService[vm.searchBy]) {
                    sharedService[vm.searchBy].onEnter();
                }

                return sharedService[vm.searchBy].search(queryParams).then(function (data) {
                    var pageSize = queryParams.take;
                    if (data.pagination.total <= pageSize) {
                        var ids = _.pluck(data.data, 'id');
                        if (sharedService.lastSearch) {
                            sharedService.lastSearch.setAllIds(ids);
                        }
                    }

                    return data;
                });
            },
            onDataCreated: function () {
                bulkMenuOperations.selectionChange(vm.gridOptions.data());
            },
            readFilterMetadata: function (column) {
                return workflowsSearchService.getColumnFilterData(column, this.getFiltersExcept(column));
            },
            columns: [{
                headerTemplate: '<bulk-actions-menu data-context="workflowSearch" data-actions="vm.menu.items" is-full-selection-possible="false" data-on-select-this-page="vm.menu.selectPage(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menuInitialised()">',
                template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">',
                width: '35px',
                fixed: true,
                locked: true,
                headerAttributes: {
                    'class': 'shorter'
                }
            }, {
                locked: true,
                fixed: true,
                sortable: false,
                field: 'isInherited',
                width: '28px',
                template: function (dataItem) {
                    return inheritanceIconTemplate(dataItem);
                }
            }, {
                locked: true,
                fixed: true,
                sortable: false,
                field: 'isProtected',
                width: '28px',
                template: function (dataItem) {
                    return iconTemplate(dataItem.isProtected);
                }
            }, {
                locked: true,
                fixed: true,
                title: 'Criteria No.',
                field: 'id',
                width: '110px',
                template: function () {
                    return '<a ui-sref="workflows.details({id: dataItem.id})" ng-click="vm.prepareToGoDetail(dataItem.id)">{{dataItem.id}}</a>';
                }
            }, {
                title: 'Criteria Name',
                field: 'criteriaName',
                width: '200px',
                template: function () {
                    return '<a ui-sref="workflows.details({id: dataItem.id})" ng-click="vm.prepareToGoDetail(dataItem.id)">{{dataItem.criteriaName}}</a>';
                }
            }, {
                title: 'Office',
                field: 'office',
                width: '120px',
                hidden: !viewData.hasOffices,
                template: function () {
                    return '<span>{{dataItem.office.description || \'\'}}</span>'
                }
            }, {
                title: 'Case Type',
                field: 'caseType',
                width: '200px',
                template: function () {
                    return '<span>{{dataItem.caseType.description || \'\'}}</span>'
                }
            }, {
                title: 'Jurisdiction',
                field: 'jurisdiction',
                width: '150px',
                filterable: true,
                template: function () {
                    return '<span>{{dataItem.jurisdiction.description || \'\'}}</span>'
                }
            }, {
                title: 'propertyType',
                field: 'propertyType',
                width: '150px',
                template: function () {
                    return '<span>{{dataItem.propertyType.description || \'\'}}</span>'
                }
            }, {
                title: 'Action',
                field: 'action',
                width: '200px',
                filterable: true,
                template: function () {
                    return '<span>{{dataItem.action.description || \'\'}}</span>'
                }
            }, {
                title: 'Case Category',
                field: 'caseCategory',
                width: '200px',
                template: function () {
                    return '<span>{{dataItem.caseCategory.description || \'\'}}</span>'
                }
            }, {
                title: 'Sub Type',
                field: 'subType',
                width: '200px',
                template: function () {
                    return '<span>{{dataItem.subType.description || \'\'}}</span>'
                }
            }, {
                title: 'Basis',
                field: 'basis',
                width: '200px',
                template: function () {
                    return '<span>{{dataItem.basis.description || \'\'}}</span>'
                }
            }, {
                title: 'Date of Law',
                field: 'dateOfLaw',
                width: '120px',
                template: '<span ng-bind="::dataItem.dateOfLaw | localeDate"></span>'
            }, {
                title: 'Local Client',
                field: 'isLocalClient',
                width: '110px',
                template: function (dataItem) {
                    return checkboxTemplate(dataItem.isLocalClient);
                }
            }, {
                title: 'Examination Type',
                field: 'examinationTypeDescription',
                width: '200px'
            }, {
                title: 'Renewal Type',
                field: 'renewalTypeDescription',
                width: '200px'
            }, {
                title: 'In Use',
                field: 'inUse',
                width: '100px',
                template: function (dataItem) {
                    return checkboxTemplate(dataItem.inUse);
                }
            }]
        });
    }

    function checkboxTemplate(fieldData) {
        return '<input ' + (fieldData === true ? 'checked' : '') + ' type="checkbox" disabled="true" />';
    }

    function iconTemplate(field) {
        if (!field) {
            return '';
        }

        return '<icon ip-tooltip="{{::\'Protected\' | translate}}" class="text-blue-secondary" name="protected"></icon>';
    }

    function inheritanceIconTemplate(dataItem) {
        if (dataItem.isInherited) {
            return '<a class="no-underline" ui-sref="workflows.inheritance({criteriaIds: dataItem.id})"><ip-inheritance-icon></ip-inheritance-icon></a>';
        } else if (dataItem.isHighestParent) {
            return '<a class="btn-no-bg" button-icon="inheritance" ip-tooltip="{{::\'HighestParent\' | translate }}"  ui-sref="workflows.inheritance({criteriaIds: dataItem.id})"><span class="cpa-icon cpa-icon-grey cpa-icon-inheritance" name="inheritance"></span></a>';
        } else {
            return '';
        }
    }

    function buildMenu() {
        return {
            context: 'workflowSearch',
            items: [{
                id: 'viewInheritance',
                text: 'workflows.search.viewInheritance',
                icon: 'inheritance',
                enabled: anySelected,
                click: openInheritsTree
            }],
            clearAll: function () {
                bulkMenuOperations.clearAll(vm.gridOptions.data());
            },
            selectPage: function (val) {
                bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
            },
            selectionChange: function (dataItem) {
                bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
            }
        };
    }

    function openInheritsTree() {
        var ids = _.pluck(bulkMenuOperations.selectedRecords(), 'id');
        $state.go('workflows.inheritance', {
            criteriaIds: ids.join(',')
        });
    }

    vm.menuInitialised = function () {
        bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
    };

    function getNoResultsHint() {
        if (sharedService[vm.searchBy]) {
            if (sharedService[vm.searchBy].selectedMatchType() === 'best-criteria-only' ||
                sharedService[vm.searchBy].selectedMatchType() === 'best-match') {
                return 'workflows.search.noResultsHintBestCriteriaAndMatch';
            }
        }

        return 'noResultsFound';
    }

    function anySelected() {
        return bulkMenuOperations.anySelected(vm.gridOptions.data());
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+i',
            description: 'shortcuts.add',
            callback: function () {
                vm.openCharacteristicModal();
            }
        });
    }

    function openCharacteristicModal() {
        modalService.open('CreateCharacteristics', $scope, {
            viewData: {
                maintainWorkflowRulesProtected: viewData.maintainWorkflowRulesProtected,
                hasOffices: viewData.hasOffices,
                canCreateNegativeWorkflowRules: viewData.canCreateNegativeWorkflowRules,
                selectedCharacteristics: sharedService[vm.searchBy].characteristicsSelected()
            }
        }).then(function () {
            optionChange();
        })
    }
});