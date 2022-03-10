angular.module('inprotech.processing.exchange')
    .controller('ExchangeConfigurationController', function ($scope, viewData, ExtObjFactory, exchangeSettingsService, notificationService, $translate, $state) {
        'use strict';
        var vm = this;
        var extObjFactory;
        var state;
        vm.$onInit = onInit;

        function onInit() {
            extObjFactory = new ExtObjFactory().useDefaults();
            state = extObjFactory.createContext();
            vm.form = {};
            vm.formData = {};
            vm.passwordExists = viewData.passwordExists;
            vm.clientSecretExists = viewData.clientSecretExists;
            vm.statusCheckInProgress = false;
            vm.hasValidSettings = viewData.hasValidSettings;

            init();
        }

        function init() {
            vm.defaultRedirectUri = (viewData.defaultSiteUrls || []).map(function (url) {
                return url + '/api/graph/auth/redirect';
            }).join('\r\n');

            var formSettings = viewData.settings;
            formSettings.tenantId = formSettings.exchangeGraph.tenantId;
            formSettings.clientId = formSettings.exchangeGraph.clientId;
            formSettings.clientSecret = formSettings.exchangeGraph.clientSecret;
            vm.formData = state.attach(formSettings);
        }

        function validate() {
            if (vm.formData.serviceType === 'Graph') {
                return vm.form.tenantId.$valid && vm.form.clientId.$valid && clientSecretValid();
            } else {
                return vm.form.userName.$valid && vm.form.server.$valid && passwordValid();
            }
        }

        function clientSecretValid() {
            return ((!vm.clientSecretExists || vm.formData.isDirty('clientSecret')) && !_.isEmpty(vm.formData.clientSecret)) || (vm.clientSecretExists && !vm.formData.isDirty('clientSecret'));
        }

        function passwordValid() {
            return ((!vm.passwordExists || vm.formData.isDirty('password')) && !_.isEmpty(vm.formData.password)) || (vm.passwordExists && !vm.formData.isDirty('password'));
        }       

        vm.save = function () {
            if (validate()) {
                var formData = vm.formData.getRaw();
                if (formData.serviceType === 'Graph') {
                    formData.exchangeGraph = {
                        tenantId: formData.tenantId,
                        clientId: formData.clientId,
                        clientSecret: formData.clientSecret
                    };
                }

                return exchangeSettingsService.save(formData).then(function (response) {
                    if (response.data.result.status === 'success') {
                        state.save();
                        notificationService.success();
                        clearStatus();
                        $state.reload($state.current.name);
                    }
                });
            }
        };

        vm.discard = function () {
            state.restore();
        };

        vm.isSaveEnabled = function () {
            if (state.isDirty() && validate()) {
                return true;
            }
            return false;
        };

        vm.isDiscardEnabled = function () {
            return state.isDirty() && validate();
        };

        vm.passwordPlaceholder = function () {
            var text = $translate.instant('exchangeIntegration.settings.administrator-details.password.placeholder');
            if (vm.passwordExists) {
                if (vm.formData.isDirty('password') && vm.form.password.$invalid)
                    return text;
                else
                    return '************';
            } else {
                return text;
            }
        };

        vm.clientSecretPlaceholder = function () {
            var text = $translate.instant('exchangeIntegration.settings.exchangeGraph.clientSecretPlaceholder');
            if (vm.clientSecretExists) {
                if (vm.formData.isDirty('clientSecret') && vm.form.clientSecret.$invalid)
                    return text;
                else
                    return '************';
            } else {
                return text;
            }
        };

        vm.checkStatus = function () {
            vm.statusCheckInProgress = true;
            clearStatus();
            var formData = vm.formData.getRaw();
            return exchangeSettingsService.checkStatus(formData).then(function (response) {
                setStatus(response.data.result);
                vm.statusCheckInProgress = false;
            });
        };

        vm.canCheckStatus = function () {
            return vm.hasValidSettings && !vm.statusCheckInProgress && !state.isDirty();
        };

        function clearStatus() {
            vm.isConnectionOk = false;
            vm.isConnectionFail = false;
        }

        function setStatus(status) {
            vm.isConnectionOk = status;
            vm.isConnectionFail = !status;
        }

    });
