angular.module('Inprotech.Localisation')
    .factory('localisedResourcesInterceptor', [
        '$q', 'localise', '$rootScope',
        function($q, localise, $rootScope) {
            'use strict';
            return {
                response: function(response) {
                    if (response.data && response.data.__resources) {
                        localise.replace(response.data.__resources);

                        $rootScope.$broadcast('localise.resources.updated');
                    }
                    return response || $q.when(response);
                }
            };
        }
    ]);