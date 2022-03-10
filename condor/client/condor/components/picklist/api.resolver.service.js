(function() {
    'use strict';
    angular.module('inprotech.components.picklist')
        .service('apiResolverService', ['$injector', '$log', function($injector, $log) {
            return {
                resolve: function(name) {

                    var serviceName = name + 'Api';
                    var service = $injector.has(serviceName) ? $injector.get(serviceName) : null;

                    if (!service) {
                        $log.warn('Service ' + serviceName + ' not found');
                        return null;
                    }

                    return service;
                }
            };
        }]);
})();
