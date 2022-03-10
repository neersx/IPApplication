angular.module('inprotechSigninRedirect', [])
    .config(function($locationProvider) {
        'use strict';
        $locationProvider.hashPrefix("");
    });