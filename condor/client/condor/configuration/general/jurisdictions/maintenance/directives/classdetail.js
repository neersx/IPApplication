angular.module('inprotech.configuration.general.jurisdictions')
    .directive('iptJurisdictionClassDetail', function () {
        'use strict';
        return {
            restrict: 'E',
            scope: {
                content: '=',
                hasIntClasses: '='
            },
            controller: 'ClassDetailController',
            controllerAs: 'vm',
            templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/classdetail.html'
        };
    })
    .controller('ClassDetailController', function ($scope, kendoGridBuilder) {
        'use string';

        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.hasIntClasses = $scope.hasIntClasses;
            vm.notes = $scope.content.notes;

            if (vm.hasIntClasses) {
                vm.gridOptions = buildGridOptions();
            }
        }
        
        function buildGridOptions() {
            return kendoGridBuilder.buildOptions($scope, {
                id: 'internationalClasses',
                autoBind: true,
                pageable: false,
                read: function () {
                    return $scope.content.internationalClasses;
                },
                columns: [{
                    title: 'jurisdictions.maintenance.classes.classCode',
                    field: 'code',
                    width: '10%',
                    sortable: true
                }, {
                    title: 'jurisdictions.maintenance.classes.heading',
                    field: 'value',
                    width: '50%',
                    sortable: true
                }]
            });
        }

    });