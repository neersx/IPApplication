angular.module('inprotech.processing.policing')
    .controller('PolicingDashboardController',
        function ($scope, $rootScope, messageBroker, policingDashboardService, scheduler) {
            'use strict';

            var vm = this;

            vm.$onInit = onInit;

            function onInit() {

                vm.summary = {};

                vm.graphSelected = 'statusGraph';
                vm.canManageExchangeRequests = false;
                vm.isServiceBrokerEnabled = true;

                $scope.$on('$destroy', function () {
                    messageBroker.disconnect();
                });
    
                initializeDashboard();
                receiveStatusUpdate();
    
                $rootScope.$on('onPolicingPermissionsReturned', function (event, data) {
                    vm.canManageExchangeRequests = data;
                });
            }

            var propagate = function (topic, data) {
                $scope.$broadcast(topic, data);
            };

            var receiveStatusUpdate = function () {
                var topic = 'policing.dashboard.' + vm.graphSelected;
                var topicStatus = 'policing.server.status';
                var topicServiceBroker = 'processing.backgroundServices.status';

                messageBroker.disconnect();
                messageBroker.subscribe(topic, function (data) {
                    scheduler.runOutsideZone(function () {
                        $scope.$apply(function () {
                            vm.summary = data.summary;
                            propagate(topic, data);
                        });
                    });
                });

                messageBroker.subscribe(topicStatus, function (data) {
                    scheduler.runOutsideZone(function () {
                        $scope.$apply(function () {
                            propagate(topicStatus, data);
                        });
                    });
                });

                messageBroker.subscribe(topicServiceBroker, function (data) {
                    scheduler.runOutsideZone(function () {
                        $scope.$apply(function () {
                            vm.isServiceBrokerEnabled = data;
                        });
                    });
                });

                messageBroker.connect();
            };

            var initializeDashboard = function () {
                policingDashboardService.dashboard().then(function (data) {
                    vm.summary = data.summary;
                    vm.trend = data.trend;
                });
            };

            vm.chartTypeChanged = function () {
                receiveStatusUpdate();
            };            
        });