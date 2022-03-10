(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingRateGraphController', ipPolicingRateGraphController);

    ipPolicingRateGraphController.$inject = ['$scope', 'kendoBarChartBuilder', 'rateGraphItemFormatterService'];

    function ipPolicingRateGraphController($scope, kendoBarChartBuilder, rateGraphItemFormatterService) {

        var vm = this;
        var service = rateGraphItemFormatterService;
        var state = '';
        var raw;
        vm.$onInit = onInit;

        function onInit() {         

            vm.rateGraph = {
                historicalDataAvailable: true,
                error: false
            };

            $scope.$on('policing.dashboard.rateGraph', function (evt, data) {
                if (!stateUpdated(data.trend)) {
                    return;
                }
    
                vm.chartOptions.refreshData();
            });
    
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

        function process() {
            if (!raw) {
                return null;
            }

            if (!raw.historicalDataAvailable || raw.hasError) {
                vm.rateGraph.error = raw.hasError;
                vm.rateGraph.historicalDataAvailable = raw.historicalDataAvailable;

                return null;
            }

            vm.rateGraph.historicalDataAvailable = raw.historicalDataAvailable;
            vm.rateGraph.error = raw.hasError;

            return service.format(raw.items);
        }

        function init() {
            kendoBarChartBuilder.buildOptions({
                theme: 'primary-multi-colour',
                id: 'rateChart',
                categoryAxis: {
                    title: {
                        text: 'policing.dashboard.graph.dateTime'
                    },
                    field: 'timeSlotLabel'
                },
                valueAxis: {
                    title: {
                        text: 'policing.dashboard.graph.numberOfItems'
                    }
                },
                series: [{
                    field: 'enterQueue',
                    name: 'policing.dashboard.graph.entered',
                    spacing: 0
                }, {
                    field: 'exitQueue',
                    name: 'policing.dashboard.graph.exited'
                }],
                sort: {
                    field: 'timeSlot',
                    dir: 'asc'
                },
                transitions: false,
                read: function () {
                    return process();
                }
            }).then(function (chartOptions) {
                vm.chartOptions = chartOptions;

                raw = raw || $scope.data;
                vm.chartOptions.refreshData();
            });
        }        
    }
})();