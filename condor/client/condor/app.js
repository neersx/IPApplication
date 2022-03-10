(function () {
    'use strict';

    var deps = [
        'inprotech.api',
        'inprotech.core',
        'inprotech.http',
        'inprotech.localisation',
        'inprotech.components',
        'inprotech.configuration',
        'inprotech.dashboard',
        'inprotech.processing',
        'inprotech.names',
        'cpa.ui.icon',
        'angular-loading-bar',
        'inprotech.classic',
        'inprotech.portal',
        'inprotech.portfolio.cases',
        'ApplicationInsightsModule',
        'inprotech.accounting',
        'inprotech.filters',
        'ui.codemirror'
    ];

    if (window.INPRO_DEBUG) {
        deps.push('inprotech.dev');
    }
    if (window.INPRO_INCLUDE_E2E_PAGES) {
        deps.push('inprotech.deve2e')
    }

    var app = angular.module('inprotech', deps);

    app.config(function ($urlRouterProvider, $httpProvider, cfpLoadingBarProvider, $locationProvider, $compileProvider, $qProvider, applicationInsightsServiceProvider) {
        if (window.INPRO_DEBUG) {
            $urlRouterProvider.otherwise('/dashboard');
        }

        var statisticsConsented = window.localStorage.getItem('statisticsConsented');
        var firmConsentedToUserStatistics = window.localStorage.getItem('firmConsentedToUserStatistics');
        var options = {
            applicationName: 'inprotech',
            key: null,
            autoPageViewTracking: false,
            autoStateChangeTracking: false,
            autoLogTracking: false,
            autoExceptionTracking: false,
            sessionInactivityTimeout: 120000,
            developerMode: false
        };


        if (statisticsConsented) {
            var appInsightSettingsData = window.localStorage.getItem('appInsightsSettings');
            if (appInsightSettingsData && appInsightSettingsData !== 'NOT_AVAILABLE') {
                var appInsightSettings = JSON.parse(appInsightSettingsData);
                options.key = appInsightSettings.key;
                options.autoPageViewTracking = appInsightSettings.sessionTracking;
                options.autoStateChangeTracking = appInsightSettings.sessionTracking;
                options.autoExceptionTracking = appInsightSettings.exceptionTracking;
            }
        }

        if (firmConsentedToUserStatistics && statisticsConsented) {
            if (window.inproInitGtag) {
                inproInitGtag();
                inproInitGtag = undefined;
            }
        }

        applicationInsightsServiceProvider.configure(options.key, options);

        $httpProvider.interceptors.push('errorinterceptor');
        $httpProvider.useApplyAsync(true);
        $httpProvider.interceptors.push('blockUiInterceptor');
        cfpLoadingBarProvider.includeSpinner = false;
        cfpLoadingBarProvider.includeBar = true;

        // angular 1.5 to 1.6 migration
        $locationProvider.hashPrefix('');
        $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|mailto|ftp|inprotech-ext|iwl|file):/);
        // This swallows exceptions, commenting it for now
        // $qProvider.errorOnUnhandledRejections(false); //https://github.com/angular-ui/ui-router/issues/2889
    });

    app.config(['$urlServiceProvider', function ($urlService) {
        $urlService.deferIntercept();
    }]);

    app.run(function ($rootScope, $transitions, $filter, $state) {

        var setPageTitle = function () {
            var title = 'Inprotech';
            var state = $state.current;
            if (state.data) {
                if (state.data.pageTitle) {
                    // required to run after translations have loaded
                    var $translate = $filter('translate');
                    var translatedSubTitle = $translate(state.data.pageTitle);
                    if (translatedSubTitle) {
                        title = translatedSubTitle + ' - ' + title;
                    }
                }

                if (state.data.pageTitlePrefix) {
                    title = state.data.pageTitlePrefix + ' - ' + title;
                }
            }
            document.title = title;
            var statisticsConsented = window.localStorage.getItem('statisticsConsented');

            if (statisticsConsented && window.ga) {
                setTimeout(function () {
                    window.ga.getAll().forEach(function (tracker) {
                        tracker.set('page', window.location.href);
                        tracker.set('title', title);
                        tracker.send('pageview');
                    });
                }, 0);
            }
        };

        $rootScope.setPageTitlePrefix = function (prefix, stateName) {
            var state = stateName ? $state.get(stateName) : $state.current;
            if (state) {
                if (!state.data) {
                    state.data = {};
                }
                state.data['pageTitlePrefix'] = prefix;
            }
            setPageTitle();
        }

        var titleListener = function () {
            setPageTitle();
        };

        var titlePrefixCleaner = function (trans) {

            if (trans.from().name !== trans.to().name && trans.from().data) {
                trans.from().data.pageTitlePrefix = null;
            }
        };

        var titleIsProvided = {
            to: function (state) {
                if (state.data && state.data.pageTitle)
                    return state;
                else return null;
            },
            testId: 'titleListener'
        }

        var titlePrefixIsProvided = {
            from: function (state) {
                if (state.data && state.data.pageTitlePrefix)
                    return state;
                else return null;
            },
            testId: 'titlePrefixCleaner'
        }

        $transitions.onSuccess(titleIsProvided, titleListener);

        //This is to avoid getting previous prefix displayed for a fraction of second
        $transitions.onExit(titlePrefixIsProvided, titlePrefixCleaner);

        var addPageCssClass = function (trans) {
            var toState = trans.to();
            $rootScope.pageCssClass = toState.name.split('.').map(function (item) {
                return item.split(/(?=[A-Z])/).join('-').toLowerCase();
            }).join(' ');
        };
        $transitions.onSuccess({
            testId: 'addPageCssClass'
        }, addPageCssClass);

        var footprintsListenerOnEnter = function (trans, state) {
            var to = trans.to();
            var from = trans.from();
            var toParams = trans.params();
            var fromParams = trans.params('from');

            if (state.name !== to.name) {
                return;
            }

            to.footprints = from.footprints || [];
            if (!_.isEqual(from, to)) {
                if (to.footprints && to.footprints.length > 0 && (isLevellingUp(from, to, toParams) || isComingFromChildPage(from, to))) {
                    to.footprints.splice(-1, 1);
                } else if (from.name !== '') {
                    to.footprints.push({
                        from: from,
                        fromParams: fromParams
                    });
                }
            }

            _.each(to.footprints, function (f) {
                if (isInSameTree(to.name, f.from.name)) {
                    f.fromParams = _.extend({}, f.fromParams, _.pick(toParams, _.keys(f.fromParams)));
                }
            });
        };

        var footprintsListenerOnRetain = function (trans, state) {
            var to = trans.to();
            if (state.name !== to.name) {
                return;
            }

            var from = trans.from();
            var toParams = trans.params();
            if (to.footprints && to.footprints.length > 0 && (isLevellingUp(from, to, toParams) || isComingFromChildPage(from, to))) {
                to.footprints.splice(-1, 1);
            }
        };

        function isLevellingUp(from, to, toParams) {
            // when levelling up, the 'to' will be the same as the last footprint
            var previousFootprint = _.last(from.footprints);
            if (previousFootprint) {
                return _.isEqual(to, previousFootprint.from) && _.isEqual(toParams, previousFootprint.fromParams)
            }
            return false;
        }

        function isComingFromChildPage(from, to) {
            return from.name.indexOf(to.name) === 0 && from.name !== to.name;
        }

        function isInSameTree(fromName, toName) {
            var fromTree = fromName.split('.')[0];
            var toTree = toName.split('.')[0];

            return fromTree === toTree;
        }

        $transitions.onEnter({
            testId: 'footprintsListenerOnEnter'
        }, footprintsListenerOnEnter);

        $transitions.onRetain({
            testId: 'footprintsListenerOnRetain'
        }, footprintsListenerOnRetain);
    });

    app.run(function (localise, $window, $document, layout) {
        $($window).on('resize', layout.detectViewportChanges);
    });

    app.run(function ($transitions, $rootScope, $window, $state) {
        if ($window.location.hash.indexOf('/hosted/') > -1) {
            $rootScope.isHosted = true;
            $transitions.onBefore({}, function (transition) {
                if ($rootScope.isHosted && transition.from().name !== '') {
                    var url = $state.href(transition.to().name, transition.params(), {
                        absolute: true,
                        inherit: false
                    });
                    $window.open(url, '_blank');

                    return false;
                }
            });
        }

        $transitions.onError({}, function (transition) {
            var from = transition.from();
            var to = transition.to();
            $rootScope.toState, $rootScope.params = null;
            if (transition._error.detail && transition._error.detail.status === 401 && from.name !== to.name) {
                $rootScope.toState = to.name;
                $rootScope.params = transition.params('to');
            }
        });
    });

    app.run(['$state', '$transitions', 'store', 'appContext', 'applicationInsightsService', function ($state, $transitions, store, appContext, applicationInsightsService) {
        var defaultTarget = 'portal2';
        var homePageStateKey = 'homePageState';
        if (applicationInsightsService.options && applicationInsightsService.options.instrumentationKey) {
            applicationInsightsService.trackPageView();
        }

        $transitions.onBefore({
            to: 'home'
        },
            function (transition) {
                return appContext.then(function (response) {
                    var savedHomePage = response.user.preferences.homePageState;
                    if (savedHomePage) {
                        return transition.router.stateService.target(savedHomePage.name, savedHomePage.params);
                    } else {
                        return transition.router.stateService.target(defaultTarget);
                    }
                });
            });

        $transitions.onError({
            from: 'home'
        }, function (transition) {
            return appContext.then(function (response) {
                var savedHomePage = response.user.preferences.homePageState;
                if (savedHomePage && savedHomePage.name === transition.to().name) {
                    var saveState = {
                        name: defaultTarget
                    };
                    store.local.set(homePageStateKey, saveState);
                    $state.go('home');
                }
            });
        });
    }]);
})();