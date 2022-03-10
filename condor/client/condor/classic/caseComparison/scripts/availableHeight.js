angular.module('Inprotech.CaseDataComparison')
    .directive('inAvailableHeight', ['$timeout', 'layout',

        function($timeout, layout) {
            'use strict';

            return {
                restrict: 'A',
                link: function(scope) {

                    var inboxContainer = angular.element('#inboxContainer');

                    var measure = function(viewport) {
                        var header = angular.element('#inboxHeader');
                        var offset = header.outerHeight(true) + 10;
                        var availableHeight = viewport.height - offset;

                        var filterBar = angular.element('#filterSelectionBar').height();
                        var searchBar = angular.element('#searchBar').height();

                        if (filterBar === 0) {
                            filterBar = angular.element('#noNotificationFoundBar').height();
                        }

                        return {
                            container: availableHeight,
                            notificationContainer: availableHeight - filterBar - searchBar,
                            comparisonContainer: availableHeight - filterBar + 4
                        };
                    };

                    var setHeights = function(ah) {
                        var notificationContainer = angular.element('#notificationsList');
                        var comparisonContainer = angular.element('.comparison-container');

                        if (ah.container < 0 || ah.notificationContainer < 0 || ah.comparisonContainer < 0) {
                            return;
                        }

                        inboxContainer.height(ah.container);
                        notificationContainer.height(ah.notificationContainer);
                        comparisonContainer.height(ah.comparisonContainer);
                    };

                    var watchHeight = function() {
                        return angular.element('#notificationsList > ul').height();
                    };

                    scope.$watch(watchHeight, function(newValue, oldValue) {
                        if (newValue !== oldValue) {
                            setHeights(measure(layout.contentSize()));
                        }
                    });

                    scope.$on('viewportResize', function(evt, viewport) {
                        setHeights(measure(viewport));
                    });

                    var setInitialHeight = $timeout(function() {
                        $timeout.cancel(setInitialHeight);
                        setHeights(measure(layout.viewport));
                    }, 500);
                }
            };
        }
    ]);