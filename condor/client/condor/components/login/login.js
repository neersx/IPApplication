angular.module('inprotech.components.login').controller('LoginController', function($rootScope, $scope, $http, modalService, $state, $timeout, hotkeys) {
    'use strict';

    $scope.autoLogin = false;
    $scope.error = '';
    $scope.form = {};
    $scope.credentials = {
        username: $rootScope.appContext.user.name,
        password: '',
        invalidPassword: false
    }
    var authModes = {
        forms: 1,
        windows: 2,
        sso: 3,
        adfs: 4
    };


    $scope.submit = function() {
        $http.post('api/signin', {
            username: $scope.credentials.username || '',
            password: $scope.credentials.password || '',
            sessionResume: true
        }).then(function(response) {
            if (response.data.status === 'success') {
                modalService.close('Login');
                if ($rootScope.toState) {
                    $state.go($rootScope.toState, $rootScope.params, {
                        location: 'replace'
                    });
                    $rootScope.toState = null;
                }
            } else if (response.data.requiresTwoFactorAuthentication && response.data.status === 'codeRequired') {
                modalService.cancel('Login');
            } else {
                $scope.credentials.invalidPassword = true;
            }
        });
    };

    $scope.cancel = function() {
        modalService.cancel('Login');
    };

    function windowsSignIn() {
        $http
            .post('../winAuth?extend=true', null, {
                handlesError: true
            })
            .then(function(resp) {
                var data = resp.data;
                if (data.status === 'success') {
                    modalService.close('Login');
                } else {
                    var failReason = data.failReasonCode || data.status;
                    $scope.error = 'authentication.' + failReason;
                    $scope.errorParam = data.parameter || '';
                }
            }, function() {
                $scope.error = 'authentication.server-error';
                $scope.errorParam = 'Windows Authentication';
            });
    }

    function ssoSignIn() {
        $http
            .post('api/signin/extendsso', null, {
                handlesError: true
            })
            .then(function(resp) {
                var data = resp.data;
                if (data.status === 'success') {
                    modalService.close('Login');
                } else {
                    var failReason = data.failReasonCode || data.status;
                    $scope.error = 'authentication.' + failReason;
                    $scope.errorParam = data.parameter || '';
                }
            }, function() {
                var prefix = 'authentication.';
                if (isAuthMethodSaved(authModes.adfs)) {
                    prefix += 'adfs.';
                }
                $scope.error = prefix + 'sso-error';
            });
    }

    function init() {
        if (isAuthMethodSaved(authModes.windows)) {
            $scope.autoLogin = true;
            windowsSignIn();
            return;
        }
        if (isAuthMethodSaved(authModes.sso) || isAuthMethodSaved(authModes.adfs)) {
            $scope.autoLogin = true;
            ssoSignIn();
            return;
        }
        $timeout(initShortcuts, 500);
    }

    function initShortcuts() {
        hotkeys.add({
            combo: 'enter',
            description: 'shortcuts.login',
            callback: function() {
                if (!$scope.form.loginForm.$invalid) {
                    $scope.submit();
                }
            }
        });
    }

    function isAuthMethodSaved(authenticationMethod) {
        var obj = JSON.parse(window.localStorage.getItem('signin')) || {};
        return obj.authMode === authenticationMethod;
    }

    init();
});