angular.module('inprotech.configuration.system.mui')
    .controller('ScreenTranslationsController', ScreenTranslationsController);

function ScreenTranslationsController($scope, $http, hotkeys, kendoGridBuilder, viewData, ScreenTranslationsService, notificationService) {
    'use strict';

    var vm = this;
    var service;
    vm.$onInit = onInit;

    function onInit() {
        service = new ScreenTranslationsService();

        $scope.service = service;

        vm.resetOptions = resetSearch;
        vm.search = search;
        vm.save = save;
        vm.discard = discard;
        vm.download = download;
        vm.isSearchDisabled = isSearchDisabled;
        vm.languages = viewData;
        vm.showNoResults = showNoResults;
        vm.gridOptions = buildGridOptions();
        vm.resultLanguageCode = null;
        vm.resultLanguageDescription = null;
        vm.heading = function () {
            if (!vm.resultLanguageCode) {
                return 'screenlabels.heading-default';
            }
            return 'screenlabels.heading-by-languageCode';
        };

        vm.searchCriteria = {
            text: ''
        };

        resetGridAndFilter();

        initShortcuts();
    }

    function showNoResults() {
        return vm.searchResults != null && vm.searchResults.length === 0;
    }

    function resetSearch() {
        if (!service.isDirty()) {
            resetGridAndFilter();
            return;
        }
        notificationService.unsavedchanges().then(function (result) {
            if (result === 'Save') {
                save().then(resetGridAndFilter);
            } else {
                service.discard();
                resetGridAndFilter();
            }
        });
        return;
    }

    function resetGridAndFilter() {
        if (vm.searchForm) {
            vm.searchForm.$reset();
        }
        vm.gridOptions.clear();
        vm.searchCriteria = {
            text: '',
            language: null,
            isRequiredTranslationsOnly: true
        };
        vm.selectedLanguage = null;
        vm.searchResults = null;
        vm.resultLanguageCode = null;
        vm.resultLanguageDescription = null;
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'searchResults',
            pageable: true,
            reorderable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: $parent.service.find(dataItem.id).isSaved(), edited: $parent.service.find(dataItem.id).isDirty(), error: $parent.service.find(dataItem.id).hasError()}"',
            read: function (queryParams) {
                var criteria = angular.extend(angular.copy(vm.searchCriteria), {
                    language: vm.resultLanguageCode || vm.selectedLanguage.culture
                });
                return service.search(criteria, queryParams);
            },
            columns: [{
                title: 'screenlabels.areaHeading',
                field: 'areaKey',
                width: '200px',
                template: '{{::dataItem.areaKey | translate}}'
            }, {
                title: 'screenlabels.resourceKey',
                field: 'key',
                width: '250px',
                sortable: true
            }, {
                title: 'screenlabels.original',
                field: 'original',
                width: '300px',
                oneTimeBinding: true
            }, {
                title: 'screenlabels.translation',
                field: 'translation',
                width: '300px',
                sortable: true,
                template: '<ip-editable-screen-label translation=\'dataItem\'><ip-editable-screen-label>'
            }]
        });
    }

    function search() {
        if (service.isDirty()) {
            notificationService.unsavedchanges().then(function (result) {
                if (result === 'Save') {
                    save().then(searchCore);
                } else {
                    service.discard();
                    searchCore();
                }
            });
            return;
        }

        searchCore();
    }

    function searchCore() {
        service.reset();
        vm.gridOptions.search().then(function () {
            vm.resultLanguageCode = vm.selectedLanguage.culture;
            vm.resultLanguageDescription = vm.selectedLanguage.description;
        });
    }

    function save() {
        return service.save(vm.resultLanguageCode)
            .then(function () {
                notificationService.success();
            });
    }

    function discard() {
        return notificationService.discard()
            .then(function () {
                service.discard();
            });
    }

    function isSearchDisabled() {
        return vm.searchForm.$loading || vm.searchForm.$invalid || !vm.selectedLanguage;
    }

    function download() {
        service.download();
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (service.isDirty()) {
                    vm.save();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.revert',
            callback: function () {
                if (service.isDirty()) {
                    vm.discard();
                }
            }
        });
    }
}