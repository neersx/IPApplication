(function() {
    'use strict';
    angular.module('inprotech.http')
        .factory('errorinterceptor', function($q, $translate, $injector, $rootScope, $window) {

            var translateErrorMessage = function(status, correlationId) {
                var prefix = 'common.errors.status-';
                var id;
                var notificationService = $injector.get('notificationService');

                if (status === 500 && correlationId) {
                    id = '500-with-token';
                } else if (_.contains([1, 403, 404, 500], status)) {
                    id = status;
                } else {
                    id = 'other';
                }

                id = prefix + id;

                $translate(id, {
                    correlationId: correlationId
                }).then(function(msg) {
                    notificationService.alert({
                        message: msg
                    });
                }, function() {
                    notificationService.alert({
                        title: 'Error',
                        message: 'An unexpected error has occured. Please try again. If the problem persists, contact an Administrator',
                        okButton: 'Ok'
                    });
                });
            };

            return {
                request: function(request) {
                    return request || $q.when(request);
                },

                requestError: function(rejection) {
                    translateErrorMessage(1, null);

                    return $q.reject(rejection);
                },

                responseError: function(rejection) {
                    var cancelled = rejection.status === -1;
                    var handlesError = rejection.config.handlesError;
                    var error = rejection.data || {};

                    if (rejection.status === 401) {
                        var modalService = $injector.get('modalService');
                        var rootScope = $injector.get('$rootScope');

                        if (rootScope.appContext) {
                            if (!modalService.isOpen('Login')) {
                                modalService.open('Login').catch(function() {
                                    window.location.href = 'signin#/?goto=' + encodeURIComponent($window.location);
                                });
                            }
                        } else {
                            window.location.href = 'signin#/?goto=' + encodeURIComponent($window.location);
                        }
                    } else if (!(cancelled || handlesError === true || _.isObject(handlesError) && handlesError(error, rejection.status, rejection))) {
                        translateErrorMessage(rejection.status === 0 ? 1 : rejection.status, error.correlationId);
                    }

                    return $q.reject(rejection);
                }
            };
        });
})();