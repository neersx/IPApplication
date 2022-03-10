angular.module('Inprotech.Integration.PtoAccess')
    .component('ipScheduleMessageAlert', {
        templateUrl: 'condor/classic/integration/ptoaccess/schedule-message-alert.html',
        bindings: {
            message: '<'
        },
        controllerAs: 'vm',
        controller: function() {
            'use strict';            
        }
    });