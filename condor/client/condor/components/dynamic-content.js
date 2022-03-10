/*
This is a copy of angular's include directive. We extended following features:
- Reloading
*/
angular.module('inprotech.components').directive('ipDynamicContent', function($templateRequest, $anchorScroll, $animate) {
    'use strict';

    return {
        restrict: 'ECA',
        priority: 400,
        terminal: true,
        transclude: 'element',
        controller: angular.noop,
        compile: function(element, attr) {
            var srcExp = attr.ngInclude || attr.src,
                onloadExp = attr.onload || '',
                autoScrollExp = attr.autoscroll;

            return function(scope, $element, $attr, ctrl, $transclude) {
                var changeCounter = 0,
                    currentScope,
                    previousElement,
                    currentElement;

                var cleanupLastIncludeContent = function() {
                    if (previousElement) {
                        previousElement.remove();
                        previousElement = null;
                    }
                    if (currentScope) {
                        currentScope.$destroy();
                        currentScope = null;
                    }
                    if (currentElement) {
                        $animate.leave(currentElement).then(function() {
                            previousElement = null;
                        });
                        previousElement = currentElement;
                        currentElement = null;
                    }
                };

                scope.$watch(srcExp, ngIncludeWatchAction);

                scope.$on('dynamicContent.reload', function() {
                    var src = scope.$eval(srcExp);
                    ngIncludeWatchAction(src);
                });

                function ngIncludeWatchAction(src) {
                    var afterAnimation = function() {
                        if (angular.isDefined(autoScrollExp) && (!autoScrollExp || scope.$eval(autoScrollExp))) {
                            $anchorScroll();
                        }
                    };
                    var thisChangeId = ++changeCounter;

                    if (src) {
                        //set the 2nd param to true to ignore the template request error so that the inner
                        //contents and scope can be cleaned up.
                        $templateRequest(src, true).then(function(response) {
                            if (scope.$$destroyed) return;

                            if (thisChangeId !== changeCounter) return;
                            var newScope = scope.$new();
                            ctrl.template = response;

                            // Note: This will also link all children of ng-include that were contained in the original
                            // html. If that content contains controllers, ... they could pollute/change the scope.
                            // However, using ng-include on an element with additional content does not make sense...
                            // Note: We can't remove them in the cloneAttchFn of $transclude as that
                            // function is called before linking the content, which would apply child
                            // directives to non existing elements.
                            var clone = $transclude(newScope, function(clone) {
                                cleanupLastIncludeContent();
                                $animate.enter(clone, null, $element).then(afterAnimation);
                            });

                            currentScope = newScope;
                            currentElement = clone;

                            currentScope.$emit('$includeContentLoaded', src);
                            scope.$eval(onloadExp);
                        }, function() {
                            if (scope.$$destroyed) return;

                            if (thisChangeId === changeCounter) {
                                cleanupLastIncludeContent();
                                scope.$emit('$includeContentError', src);
                            }
                        });
                        scope.$emit('$includeContentRequested', src);
                    } else {
                        cleanupLastIncludeContent();
                        ctrl.template = null;
                    }
                }
            };
        }
    };
});

angular.module('inprotech.components').directive('ipDynamicContent', function($compile) {
    return {
        restrict: 'ECA',
        priority: -400,
        require: 'ipDynamicContent',
        link: function(scope, $element, $attr, ctrl) {
            $element.html(ctrl.template);
            $compile($element.contents())(scope);
        }
    };
});
