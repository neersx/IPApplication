angular
    .module('Inprotech')
    .factory('safeApply', [function() {
        'use strict';

        return function(scope, callback) {
            var phase = (scope.$root || {}).$$phase;
            if (phase === '$apply' || phase === '$digest') {
                return callback();
            }

            return scope.$apply(callback);
        };
    }]);

angular.module('Inprotech')
    .directive('inBaseUrl', ['url',
        function(url) {
            'use strict';
            return {
                restrict: 'E',
                scope: {
                    path: '='
                },
                link: function(scope) {
                    url.baseUrl = scope.path;
                }
            };
        }
    ])
    .service('url', ['$window',
        function($window) {
            'use strict';
            var normalise = function(path) {
                return !path || (/^.*\/$/).test(path) ? path : path + '/';
            };

            var url = {
                baseUrl: '',
                /*
                 * The format for constructing the url conforms to the following reference. Internally it calls sprintf to get path.
                 * http://www.diveintojavascript.com/projects/javascript-sprintf
                 * Example:
                 *   url.api('case/%d/summary', -23) => 'case/-23/summary'
                 * */
                api: function(path) {
                    return 'api/'+path;
                },
                of: function(path) {
                    return 'condor/classic/' + path;
                },
                app: function(inputUrl) {
                    var path = inputUrl || $window.location.pathname || '';
                    //if it is relative path return the first level straight away
                    if (path[0] !== '/') {
                        return (path.match(/[^\/]+/) || [])[0];
                    }

                    var parts = (inputUrl || $window.location.pathname).match(/[^\/]+/g) || [];
                    var levels = ('/' + url.baseUrl).match(/\//g).length - 1;

                    var app = parts.slice(parts.length - levels).join('/');

                    if (!app) {
                        app = '';
                    }

                    return app.toLowerCase();
                },
                query: function(obj) {
                    return _.chain(obj)
                        .map(function(value, key) {
                            if (_.isArray(value)) {
                                return _.map(value, function(v) {
                                    return key + '=' + v;
                                });
                            }

                            return key + '=' + value;
                        })
                        .flatten()
                        .value()
                        .join('&');
                },
                inprotech: function(path) {
                    return '../' + normalise(url.baseUrl) + path;
                }
            };

            return url;
        }
    ]);