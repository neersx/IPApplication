(function() {
    'use strict';

    angular.module('inprotech.api', ['inprotech.core', 'inprotech.api.extensions']);

    angular.module('inprotech.api').config(function(restmodProvider) {
        restmodProvider.rebase({
            $config: {
                style: 'DotNetStyle',
                urlPrefix: 'api',
                primaryKey: 'id'
            },
            $extend: {
                Model: {
                    encodeUrlName: function(_name) {
                        return _name.toLowerCase();
                    }
                }
            }
        });
    });
})();
