angular.module('inprotech.configuration.general.jurisdictions')
    .controller('AddressSettingsController', function ($scope, ExtObjFactory) {
        'use strict';

        var vm = this;
        var extObjFactory = new ExtObjFactory().useDefaults();
        var state = extObjFactory.createContext();
        vm.$onInit = onInit;

        function onInit() {
            vm.form = {};
            vm.formData = {};
            vm.topic.isDirty = isDirty;
            vm.topic.discard = discard;
            vm.topic.getFormData = angular.noop;
            vm.topic.afterSave = afterSave;
            vm.topic.hasError = hasError;
            vm.topic.validate = validate;
            vm.onPicklistChange = onPicklistChange;

            init();
        }

        function init() {
            var data = $scope.viewData;
            vm.formData = state.attach(data);
            vm.topic.initialised = true;
        }

        function validate() {
            return vm.form.$validate();
        }

        function onPicklistChange() {
            vm.form.$validate();
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

        function hasError() {
            return vm.form.$invalid && vm.form.$dirty;
        }
    })
    .directive('ipJurisdictionAddressSettings', function () {
        'use strict';
        return {
            restrict: 'E',
            scope: {
                viewData: '='
            },
            controller: 'AddressSettingsController',
            controllerAs: 'vm',
            bindToController: {
                topic: '='
            },
            templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/addresssettings.html'
        };
    });
