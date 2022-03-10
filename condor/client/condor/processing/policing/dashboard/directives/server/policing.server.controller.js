(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingServerStatusController', ipPolicingServerStatusController);

    ipPolicingServerStatusController.$inject = ['$scope', '$rootScope', 'policingServerService', 'notificationService'];

    function ipPolicingServerStatusController($scope, $rootScope, policingServerService, notificationService) {

        var policingStatus = {
            waiting: 0,
            running: 1,
            stopped: 2
        };

        var serverStates = [{
            state: policingStatus.waiting,
            confirmMessage: '',
            action: function () {
                return function () { };
            },
            data: {
                'message': 'policing.serverStatus.checking',
                'radioClass': ''
            }
        }, {

            state: policingStatus.running,
            confirmMessage: 'modal.policingOff.message',
            action: function () {
                return service.turnOff().then(function () {
                    notificationService.success('modal.policingOff.success');
                });
            },
            data: {
                'message': 'policing.serverStatus.running',
                'radioClass': 'saved'

            }
        }, {
            state: policingStatus.stopped,
            confirmMessage: 'modal.policingOn.message',
            action: function () {
                return service.turnOn();
            },
            data: {
                'message': 'policing.serverStatus.stopped',
                'radioClass': 'error'
            }
        }];

        var vm = this;
        var service;

        service = policingServerService;
        vm.canAdminister = false;
        vm.currentState = {};
        setState(policingStatus.waiting);

        function setState(newState) {
            vm.currentState = _.find(serverStates, function (item) {
                return item.state === newState;
            });
        }

        vm.changeServerStatus = function () {
            notificationService.confirm({
                message: vm.currentState.confirmMessage
            }).then(function () {
                vm.currentState.action().then(function () {
                    setState(policingStatus.waiting);
                });
            });
        };

        vm.isWaiting = function () {
            return vm.currentState.state === policingStatus.waiting;
        };

        vm.isRunning = function () {
            return vm.currentState.state === policingStatus.running;
        };

        service.canAdminister().then(function (response) {
            vm.canAdminister = response.data.canAdminister;
            $rootScope.$emit('onPolicingPermissionsReturned', response.data.canManageExchangeRequests);
        });

        $scope.$on('policing.server.status', function (evt, data) {
            if (vm.currentState.state === data) {
                return;
            }
            setState(data);
        });
    }
})();
