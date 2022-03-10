(function() {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipCurrentStatusGraphController', ipCurrentStatusGraphController);

    ipCurrentStatusGraphController.$inject = ['$scope', 'kendoBarChartBuilder', 'statusGraphDataAdapterService'];

    function ipCurrentStatusGraphController($scope, kendoBarChartBuilder, statusGraphDataAdapterService) {

        var vm = this;
        var service = statusGraphDataAdapterService;
        var state = '';
        var raw;
        vm.$onInit = onInit;

        function onInit() {
            init();
        }

        function stateUpdated(data) {
            var newState = JSON.stringify(data);

            if (newState === state) {
                return false;
            }
            state = newState;
            raw = data;
            return true;
        }

        function buildChartOptions(optionParams) {
            return kendoBarChartBuilder.buildOptions({
                theme: optionParams.theme,
                id: optionParams.id,
                categoryAxis: {
                    translateCategories: true,
                    categories: service.getCategories(optionParams.isError),
                    title: {
                        text: optionParams.categoryAxisTitle,
                        color: optionParams.categoryAxisColour
                    },
                    line: {
                        visible: true
                    }
                },
                valueAxis: {
                    type: 'log',
                    min: 0.5,
                    axisCrossingValue: 0.50,
                    title: {
                        text: optionParams.valueAxisTitle
                    }
                },
                series: [{
                    field: 'stuck',
                    name: 'policing.dashboard.graph.stuck',
                    stack: true
                }, {
                    field: 'tolerable',
                    name: 'policing.dashboard.graph.tolerable',
                    stack: true
                }, {
                    field: 'fresh',
                    name: 'policing.dashboard.graph.fresh',
                    stack: true
                }],
                transitions: false,
                read: function() {
                    return service.prioritiseStatus(raw, optionParams.isError);
                }
            }); 
        }

        function init() {
            buildChartOptions({
                isError: false,
                theme: 'primary-multi-colour',
                id: 'currentStateChart',
                categoryAxisTitle: 'policing.dashboard.graph.progressing',
                categoryAxisColour: '#88CBF9',
                valueAxisTitle: 'policing.dashboard.graph.numberOfItems'
            }).then(function(chartOptions) {
                vm.chartOptions = chartOptions;

                raw = raw || $scope.data;
                vm.chartOptions.refreshData();
            });

            buildChartOptions({
                isError: true,
                theme: 'secondary-multi-colour',
                id: 'currentErrorStateChart',
                categoryAxisTitle: 'policing.dashboard.graph.needsAttention',
                categoryAxisColour: '#D87959',
                valueAxisTitle: ''
            }).then(function(chartOptions) {
                vm.errorChartOptions = chartOptions;

                raw = raw || $scope.data;
                vm.errorChartOptions.refreshData();
            });
        }

        $scope.$on('policing.dashboard.statusGraph', function(evt, data) {
            if (!stateUpdated(data.summary)) {
                return;
            }

            vm.chartOptions.refreshData();
            vm.errorChartOptions.refreshData();
        });
    }
})();
