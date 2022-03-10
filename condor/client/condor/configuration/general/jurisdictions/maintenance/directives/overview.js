angular.module('inprotech.configuration.general.jurisdictions')
    .controller('JurisdictionOverviewController', function ($scope, ExtObjFactory, dateHelper) {
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
            vm.topic.getFormData = getFormData;
            vm.topic.afterSave = afterSave;
            vm.topic.hasError = hasError;

            init();
        }

        function init() {
            var data = $scope.viewData;
            data.dateCommenced = data.dateCommenced ? new Date(dateHelper.convertForDatePicker(data.dateCommenced)) : null;
            data.dateCeased = data.dateCeased ? new Date(dateHelper.convertForDatePicker(data.dateCeased)) : null;
            vm.formData = state.attach(data);
            vm.topic.initialised = true;
        }

        function isDirty() {
            return state.isDirty();
        }

        function discard() {
            vm.form.$reset();
            state.restore();
        }

        function getFormData() {
            return vm.formData.getRaw();
        }

        function afterSave() {
            state.save();
        }

        function hasError() {
            return vm.form.$invalid && vm.form.$dirty;
        }
    })
    .directive('ipJurisdictionOverview', function () {
        'use strict';
        return {
            restrict: 'E',
            scope: {
                viewData: '='
            },
            controller: 'JurisdictionOverviewController',
            controllerAs: 'vm',
            bindToController: {
                topic: '='
            },
            templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/overview.html'
        };
    });