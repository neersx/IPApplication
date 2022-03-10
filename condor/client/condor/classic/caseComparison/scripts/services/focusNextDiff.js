angular.module('Inprotech.CaseDataComparison')
    .directive('focusNextDiff', ['$rootScope', '$timeout', 'hotkeys', function($rootScope, $timeout, hotkeys) {
        'use strict';

        return {
            link: function(scope, element, attrs) {
                var current;
                var eligibles = [];
                var keyCombo = 'd d';

                var bind = function() {

                    hotkeys.del(keyCombo);

                    var registerDiffReceivingFocus = function() {
                        current = $(this)[0];
                    };

                    if (eligibles.length > 0) {
                        eligibles.off('focus', registerDiffReceivingFocus);
                        current = null;
                    }

                    eligibles = $(':visible.diff');
                    if (eligibles.length === 0) {
                        return;
                    }

                    var selectNext = function() {
                        $timeout(function() {
                            var index = _.findIndex(eligibles, function(e) {
                                return e === current;
                            });

                            var c = (index === -1 || index === eligibles.length - 1) ?
                                eligibles.first() :
                                $(eligibles[index + 1]);

                            current = c[0];
                            current.focus();
                        }, 0);
                    };

                    hotkeys.bindTo(scope)
                        .add({
                            combo: keyCombo,
                            description: attrs.focusNextDiffHint,
                            callback: selectNext,
                            allowIn: ['INPUT']
                        });

                    eligibles.on('focus', registerDiffReceivingFocus);
                };

                scope.$watch(attrs.focusNextDiff,
                    function() {
                        $timeout(bind, 10);
                    });
            }
        };
    }]);