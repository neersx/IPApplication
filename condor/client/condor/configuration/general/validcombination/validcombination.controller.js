angular.module('inprotech.configuration.general.validcombination')
    .factory('selectedCaseType', function () {
        'use strict';
        var caseType;
        return {
            set: function (value) {
                caseType = value;
            },
            get: function () {
                return caseType;
            }
        };
    })
    .factory('defaultCountry', function () {
        'use strict';
        var defaultCountry;
        return {
            set: function (value) {
                defaultCountry = value;
            },
            get: function () {
                return defaultCountry;
            }
        };
    })
    .controller('ValidCombinationController', ValidCombinationController);



function ValidCombinationController($scope, kendoGridBuilder, $state, viewData, validCombinationConfig, validCombinationService, validCombinationMaintenanceService, modalService, selectedCaseType, $translate, defaultCountry, $transitions) {
    'use strict';

    var vm = this;

    vm.$onInit = onInit;

    function onInit() {
        vm.search = angular.noop;
        vm.refreshGrid = angular.noop;
        vm.isResetDisabled = isResetDisabled;
        vm.searchOptions = viewData;
        vm.onSearchbyChanged = onSearchbyChanged;
        vm.reset = reset;
        vm.evalPicklistVisibility = evalPicklistVisibility;
        vm.isDefaultSelection = isDefaultSelection;
        vm.isCaseCategoryDisabled = isCaseCategoryDisabled;
        vm.caseTypeChanged = caseTypeChanged;
        vm.extendCaseCategoryPicklsit = extendCaseCategoryPicklsit;
        vm.hasErrors = hasErrors;
        vm.gridOptions = buildGridOptions();
        vm.picklistErrors = {};
        vm.add = handleAdd;
        vm.launchActionOrder = launchActionOrder;
        vm.onViewDefaultChange = onViewDefaultChange;
        vm.onCountryChange = onCountryChange;
        vm.containsDefault = containsDefault;
        vm.noResultsHint = noResultsHint;

        initSearchOptions();
        init();
        initBulkMenuActions();
        ensureValidCombinationState();
        isCaseCategoryDisabled();
        validCombinationMaintenanceService.initialize(vm, $scope);
        setDefaultCountry();
    }

    function initSearchOptions() {
        vm.selectedSearchOption = {
            type: validCombinationConfig.searchType.default,
            description: ''
        };
        $scope.selectedCharacteristics = vm.selectedSearchOption;
        $scope.viewData = viewData;
    }

    function init() {
        vm.searchCriteria = {
            jurisdictions: [],
            propertyType: {},
            caseType: {},
            action: {},
            caseCategory: {},
            subType: {},
            basis: {},
            status: {},
            relationship: {},
            checklist: {},
            viewDefault: false
        };

        vm.typeaheadText = {};
        vm.typeaheadErrors = {};
    }

    function noResultsHint() {
        return $translate.instant('validcombinations.noResultsHint');
    }

    function setDefaultCountry() {
        validCombinationService.getDefaultCountry().then(function (jurisdiction) {
            defaultCountry.set(jurisdiction.value);
        });
    }

    function onViewDefaultChange() {
        if (!vm.searchCriteria.jurisdictions) {
            vm.searchCriteria.jurisdictions = [];
        }

        if (vm.searchCriteria.viewDefault) {
            if (!containsDefault()) {
                vm.searchCriteria.jurisdictions.push({
                    key: 'ZZZ',
                    code: 'ZZZ',
                    value: defaultCountry.get()
                });
            }
        } else {
            if (containsDefault()) {
                vm.searchCriteria.jurisdictions = _.without(vm.searchCriteria.jurisdictions, _.findWhere(vm.searchCriteria.jurisdictions, {
                    key: 'ZZZ'
                }));
            }
        }
    }

    function containsDefault() {
        return _.any(_.filter(vm.searchCriteria.jurisdictions, function (jurisdiction) {
            return jurisdiction.key === 'ZZZ';
        }));
    }

    function onCountryChange() {
        if (!vm.searchCriteria.jurisdictions || !containsDefault()) {
            vm.searchCriteria.viewDefault = false;
        } else {
            if (containsDefault()) {
                vm.searchCriteria.viewDefault = true;
            }
        }
    }

    function isResetDisabled() {
        return true;
    }

    function hasErrors() {
        return !vm.form.$valid;
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            pageable: {
                pageSize: 20
            },
            scrollable: false,
            columns: [{
                title: '',
                width: '60px',
                headerTemplate: '<div data-bulk-actions-menu data-context="validcombinations"></div>'
            }]
        });
    }

    function isDefaultSelection() {
        return vm.selectedSearchOption && (vm.selectedSearchOption.type === validCombinationConfig.searchType.default || vm.selectedSearchOption.type === '');
    }

    function ensureValidCombinationState() {
        vm.selectedSearchOption = getSelectedSearchOption($state.current.symbol);
        $scope.selectedCharacteristics = vm.selectedSearchOption;
        $transitions.onStart({}, function (trans) {
            var toState = trans.to();
            if (angular.isDefined(vm.selectedSearchOption) && vm.selectedSearchOption.type !== toState.symbol) {
                vm.selectedSearchOption = getSelectedSearchOption(toState.symbol);
                vm.reset();
                $scope.selectedCharacteristics = vm.selectedSearchOption;
                validCombinationMaintenanceService.modalOptions.selectedCharacteristic = vm.selectedSearchOption;
            }
        });
    }

    function getSelectedSearchOption(symbol) {
        return _.first(_.filter(vm.searchOptions, function (item) {
            return item.type === symbol;
        }));
    }

    function onSearchbyChanged() {
        if (vm.selectedSearchOption.type === validCombinationConfig.searchType.default) {
            $state.go(validCombinationConfig.baseStateName, {}, {
                reload: true
            });
        } else {
            $state.go(validCombinationConfig.baseStateName + '.' + vm.selectedSearchOption.type);
        }
        vm.reset();
        $scope.selectedCharacteristics = vm.selectedSearchOption;
        initBulkMenuActions();
        validCombinationMaintenanceService.modalOptions.selectedCharacteristic = vm.selectedSearchOption;

        vm.queryBuilder = null;
    }

    function isCaseCategoryDisabled() {
        return vm.searchCriteria.caseType == null || !angular.isDefined(vm.searchCriteria.caseType.value);
    }

    function caseTypeChanged() {
        if (vm.searchCriteria.caseType !== null) {
            selectedCaseType.set(vm.searchCriteria.caseType);
        } else vm.searchCriteria.caseCategory = null;
    }

    function reset(manualReset) {
        if (manualReset) {
            init();
            validCombinationMaintenanceService.resetSearchCriteria(vm.searchCriteria);
            $state.go(validCombinationConfig.baseStateName, {}, {
                reload: true
            });
        }
        resetErrors();
        vm.refreshGrid();
    }

    function resetErrors() {
        var typeaheads = Object.keys(vm.searchCriteria);
        _.each(typeaheads, function (typeahead) {
            if (angular.isDefined(vm.form) && vm.form[typeahead] && vm.form[typeahead].$invalid) {
                vm.form[typeahead].$reset();
            }
        });
    }

    function evalPicklistVisibility(picklist) {
        if (!vm.selectedSearchOption || vm.selectedSearchOption.type === validCombinationConfig.searchType.default) {
            return false;
        }

        switch (picklist) {
            case 'jurisdiction':
                return true;
            case 'propertytype':
                return vm.selectedSearchOption.type !== validCombinationConfig.searchType.allCharacteristics || vm.selectedSearchOption.type === validCombinationConfig.searchType.checklist;
            case 'casetype':
                return vm.selectedSearchOption.type !== validCombinationConfig.searchType.allCharacteristics && vm.selectedSearchOption.type !== validCombinationConfig.searchType.propertyType && vm.selectedSearchOption.type !== validCombinationConfig.searchType.relationship && vm.selectedSearchOption.type !== validCombinationConfig.searchType.dateOfLaw;
            case 'action':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.action;
            case 'casecategory':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.category || vm.selectedSearchOption.type === validCombinationConfig.searchType.subType || vm.selectedSearchOption.type === validCombinationConfig.searchType.basis;
            case 'subtype':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.subType;
            case 'basis':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.basis;
            case 'status':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.status;
            case 'relationship':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.relationship;
            case 'checklist':
                return vm.selectedSearchOption.type === validCombinationConfig.searchType.checklist;
        }
    }

    function exportToExcel() {
        return validCombinationService.exportToExcel();
    }

    function initBulkMenuActions() {
        vm.actions = [{
            id: 'export-excel',
            enabled: function () {
                return true;
            },
            click: exportToExcel
        }, {
            id: 'edit',
            icon: 'cpa-icon cpa-icon-pencil-square-o',
            enabled: angular.noop,
            maxSelection: 1,
            click: angular.noop
        }, {
            id: 'duplicate',
            maxSelection: 1,
            enabled: angular.noop,
            click: angular.noop
        }, {
            id: 'delete',
            enabled: angular.noop,
            click: angular.noop
        }];
    }

    function handleAdd() {
        return validCombinationMaintenanceService.handleAddFromMainController();
    }

    function launchActionOrder() {
        var items = allItems();
        var dataItem = _.first(items);
        modalService.openModal({
            launchSrc: 'search',
            id: 'ActionOrder',
            dataItem: angular.isDefined(dataItem) ? dataItem : {},
            allItems: items,
            controllerAs: 'ctrl'
        });
    }

    function allItems() {
        var items = [];
        _.each(vm.searchCriteria.jurisdictions, function (jurisdiction) {
            items.push({
                jurisdiction: jurisdiction,
                propertyType: vm.searchCriteria.propertyType == null ? {} : vm.searchCriteria.propertyType,
                caseType: vm.searchCriteria.caseType == null ? {} : vm.searchCriteria.caseType
            });
        });
        if (vm.searchCriteria.jurisdictions.length === 0 || vm.searchCriteria.jurisdictions === null || vm.searchCriteria.jurisdictions === undefined) {
            items.push({
                jurisdiction: {},
                propertyType: vm.searchCriteria.propertyType == null ? {} : vm.searchCriteria.propertyType,
                caseType: vm.searchCriteria.caseType == null ? {} : vm.searchCriteria.caseType
            });
        }
        return items;
    }

    function extendCaseCategoryPicklsit(query) {
        if (!isCaseCategoryDisabled()) {
            var extended = angular.extend({}, query, {
                caseType: vm.searchCriteria.caseType.code,
                latency: 888
            });
            return extended;
        }
    }
}