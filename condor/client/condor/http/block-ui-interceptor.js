angular.module('inprotech.http')
    .factory('blockUiInterceptor', function($q, $injector) {
        'use strict';

        var modalInstance;
        var requestDone;

        function closeBlock() {
            if (modalInstance) {
                    setTimeout(function() {
                        // give the block modal time to load
                    if (modalInstance) {
                        modalInstance.close();
                    }
                        modalInstance = null;
                    }, 100);
            } else {
                requestDone = true;
            }
        }

        function isBlockingMethod(config) {
          return config.method === 'PUT' || config.method === 'POST' || config.method === 'DELETE';
        }

        function reject(rejection) {
            requestDone = true;
            closeBlock();
            return $q.reject(rejection);
        }

        return {
            'request': function(config) {
                if (isBlockingMethod(config)) {
                    var uibModal = $injector.get('$uibModal');
                    requestDone = false;
                    setTimeout(function() {
                        if (!requestDone) {
                            modalInstance = uibModal.open({
                                templateUrl: 'condor/http/block.html',
                                windowClass: 'block-modal-window',
                                backdrop: 'static',
                                size: 's'
                            });
                        }
                    }, 300);
                }
                return config;
            },
            'response': function(response) {
                requestDone = true;
                if (isBlockingMethod(response.config)) {
                    closeBlock();
                }
                return response;
            },
            'requestError': reject,
            'responseError': reject
        };
    });
