angular.module('Inprotech.Integration.PtoAccess')
    .factory('keyLinkMap', [function() {
        'use strict';

        var dataSourceLinkMap = {
            'epo-missing-keys': {
                text: 'ConfigureEPOSetting',
                link: '../../#/pto-settings/epo'
            }
        };

        function getLinkFor(key, relatedTo) {
            if (relatedTo === 'DataSource') {
                return dataSourceLinkMap[key];
            }
        }

        return {
            getLinkFor: getLinkFor
        };
    }]);