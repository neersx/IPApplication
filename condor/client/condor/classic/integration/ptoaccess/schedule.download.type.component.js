angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleDownloadType', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-download-type-component.html',
        bindings: {
            schedule: '<',
            maintenance: '='
        },
        controllerAs: 'vm',
        controller: function($scope, $translate, knownValues, dataSourceMap, comparisonDataSourceMap) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                vm.selectedDownloadType = null;
                vm.isDataSourceIpOne = false;
                vm.downloadTypeChanged = downloadTypeChanged;
            }

            $scope.$watch('vm.schedule.dataSource', function(sourceSelected) {
                var dt = dataSourceMap.downloadTypes(sourceSelected);
                vm.isDataSourceIpOne = comparisonDataSourceMap.showTooltip(sourceSelected);
                if (!dt) {
                    vm.downloadTypes = null;
                    vm.selectedDownloadType = null;
                    return;
                }

                vm.downloadTypes = _.map(dt, function(item) {
                    return {
                        type: item,
                        label: $translate.instant('dataDownload.downloadType.' + sourceSelected + '.' + item)
                    };
                });
            });

            function downloadTypeChanged() {
                vm.schedule.downloadType = vm.selectedDownloadType ? vm.selectedDownloadType.type : null;
                var dt = dataSourceMap.downloadTypes(vm.schedule.dataSource);
                if (!dt) {
                    vm.schedule.downloadType = knownValues.downloadTypes.All;
                }
            }
        }
    });