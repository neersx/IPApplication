angular.module('inprotech.dev').controller('DevLoginController', function($http, $injector) {
    'use strict';
    var vm = this;
    vm.logout = function() {
        $http.get('/api/signout');
    };

    var modalService = $injector.get('modalService');
    vm.showLogin = function() {
        modalService.open('Login');
    };
});
