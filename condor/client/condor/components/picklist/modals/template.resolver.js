(function() {
    'use strict';

    angular.module('inprotech.components.picklist')
        .service('templateResolver', ['$log', function($log) {

            var buildFromConvention = function(baseName, operation) {
                if (!operation || operation === '') {
                    return null;
                }

                var basename = baseName.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
                var template = 'condor/picklists/' + basename + '/' + basename + '.html';
                $log.debug('resolved template for ' + baseName + ' and operation ' + operation + ': ' + template);
                return template;
            };

            return {
                resolve: buildFromConvention
            };

        }]);

})();
