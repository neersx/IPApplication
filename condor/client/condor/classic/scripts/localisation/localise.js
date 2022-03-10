angular.module('Inprotech.Localisation')
    // Service used to hold resources loaded for an application.
    .factory('localise', [
        'globalResources',
        function (globalResources) {
            'use strict';
            var _resources = globalResources || {};

            var localise = {
                /*
                 Used during app startup to initialize the resources
                 by extending the global resource set with application specific resource entries.
                 */
                initialize: function (resources) {
                    _resources = _.extend(resources, _resources);
                },

                /*
                 Returns the localised value for the specified key.
                 Returns an empty string if the key was not found.
                 */
                getString: function (key) {

                    if (!key) {
                        throw 'key is required';
                    }

                    var result = _resources[key];

                    for (var i = 1; i < arguments.length; i++) {
                        result = result.replace('{' + (i - 1) + '}', arguments[i]);
                    }

                    return result;
                },

                /*
                 Used to replace the default resource set with a specific set of resources.
                 */
                replace: function (resources) {
                    if (!resources) {
                        return;
                    }

                    for (var key in resources) {
                        _resources[key] = resources[key];
                    }
                }
            };

            return localise;
        }
    ])
    // Filter used in markup to resolve localised text for an element.
    // Simple usage:
    // {{ 'lblGreeting' | loc }}
    // Advanced usage:
    // 'lblGreeting': 'Hi, {0}!'
    // {{ 'lblGreeting' | loc:'mike' }}
    .filter('loc', [
        'localise',
        function (localise) {
            'use strict';
            return function (key) {
                if (!key) {
                    throw 'key is required.';
                }

                var result = localise.getString(key);

                for (var i = 1; i < arguments.length; i++) {
                    result = result.replace('{' + (i - 1) + '}', arguments[i]);
                }

                return result || key;
            };
        }
    ]);
