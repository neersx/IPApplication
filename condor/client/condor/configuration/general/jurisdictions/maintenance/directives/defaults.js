angular.module('inprotech.configuration.general.jurisdictions').directive('ipJurisdictionDefaults', function () {
    'use strict';
    return {
        restrict: 'E',
        scope: {
            viewData: '='
        },
        controller: 'BillingDefaultsController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/defaults.html',
        bindToController: {
            topic: '='
        }
    };
})
    .controller('BillingDefaultsController', function ($scope, $http, ExtObjFactory) {
        'use strict';

        var vm = this;
        var extObjFactory = new ExtObjFactory().useDefaults();
        var state = extObjFactory.createContext();
        vm.$onInit = onInit;

        function onInit() {            
            vm.formData = {};
            vm.topic.isDirty = isDirty;
            vm.topic.discard = discard;
            vm.topic.getFormData = angular.noop;
            vm.topic.afterSave = afterSave;
            vm.topic.hasError = hasError;

            initialize();
        }

        function initialize() {
            var data = $scope.viewData;
            vm.formData = state.attach(data);
            vm.topic.initialised = true;

            $http.get('api/configuration/jurisdictions/taxexemptoptions')
                .then(function (response) {
                    vm.taxExemptOptions = response.data;
                });
        }

        function hasError() {
            return vm.form && vm.form.$dirty && vm.form.$invalid;
        }

        function isDirty() {
            return state.isDirty();
        }

        function discard() {
            vm.form.$reset();
            state.restore();
        }

        function afterSave() {
            state.save();
        }
    });