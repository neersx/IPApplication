'use strict';

angular.module('inprotech.portal', ['inprotech.core',
    'inprotech.api',
    'inprotech.components']);

angular.module('inprotech.portal').config(function ($stateProvider) {
    $stateProvider
        .state('home', {
            url: '/home',
            templateUrl: 'condor/portal/home.html',
            data: {
                pageTitle: 'Home'
            }
        })
});
