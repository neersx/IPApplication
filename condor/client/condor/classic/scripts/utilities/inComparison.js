angular.module('Inprotech.Utilities')
    .directive('inComparison', [
        function() {
            'use strict';

            return {
                restrict: 'A',
                scope: {
                    text: '='
                },

                link: function(scope, element) {
                    var cleanUp = function() {
                        $('span', element).remove();
                    };

                    var doComparison = function() {
                        // eslint-disable-next-line no-undef
                        var diff = JsDiff.diffWords(scope.text.left, scope.text.right);

                        diff.forEach(function(part) {
                            var css = part.added ? 'diff-added' :
                                part.removed ? 'diff-deleted' : 'diff-unchanged';

                            element.append($('<span></span>')
                                .text(part.value)
                                .addClass(css)
                            );
                        });
                    };

                    scope.$watch('text', function() {
                        cleanUp();
                        doComparison();
                    });
                }
            };
        }
    ]);