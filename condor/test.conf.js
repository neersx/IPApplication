//this file is used for overwritting some default settings for unit testing purpose.
(function() {
    'use strict';

    // angular 1.5 to 1.6 migration
    angular.module('ngMock').config(function($httpProvider, $locationProvider, $qProvider) {
		$httpProvider.useApplyAsync(false);
        $locationProvider.hashPrefix('');
        $qProvider.errorOnUnhandledRejections(false); //https://github.com/angular-ui/ui-router/issues/2889
	});
})();

