angular.module('inprotech.components.login', []).run(function(modalService) {
    'use strict';

    modalService.register('Login', 'LoginController', 'condor/components/login/login.html', {
        windowClass: 'centered',
        backdropClass: 'centered',
        animation: false
    });
});
