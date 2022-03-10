angular.module('inprotech.configuration.rules.workflows').component('ipDefaultJurisdiction', {
	templateUrl: 'condor/configuration/rules/workflows/search/valid-default-jurisdiction.html',
	bindings: {
		results: '<'
	},
	controllerAs: 'vm',
	controller: function () {
		'use strict';

		var vm = this;
		vm.$onInit = onInit;

		function onInit() {

			vm.isDefaultJurisdiction = function () {
				return _.all(vm.results, function (result) {
					return result.isDefaultJurisdiction && result.isDefaultJurisdiction === true;
				});
			};
		}
	}
});