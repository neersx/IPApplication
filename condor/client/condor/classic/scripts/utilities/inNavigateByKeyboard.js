angular.module('Inprotech.Utilities')
    .directive('inNavigateByKeyboard', ['$rootScope', '$timeout', 'hotkeys', 'localise', function($rootScope, $timeout, hotkeys, localise) {
        'use strict';

        return function(scope, element, attrs) {
            var selectedSelector = attrs.selectedSelector;
            var supported = [{
                tagName: 'TABLE',
                item: 'tr'
            }, {
                tagName: 'UL',
                item: 'li'
            }];

            var matched = _.find(supported, function(s) {
                return s.tagName === element[0].tagName;
            });

            if (!selectedSelector || !matched) {
                return;
            }

            $rootScope.$broadcast('keyboard-binding', true);

            var resolve = function(direction, eligibles, current) {
                var index = _.findIndex(eligibles, function(e) {
                    return e === current || $(e).has(current).length > 0;
                });

                return (direction === 'prev') ?
                    (index === 0 ? eligibles[0] : eligibles[index - 1]) :
                    (index === eligibles.length - 1 ? eligibles[index] : eligibles[index + 1]);
            };

            var selector = function() {
                /* supports descendant selector */
                var tag = matched.item;
                return tag + selectedSelector + ', ' + tag + ' ' + selectedSelector;
            };

            var get = function(direction) {
                var tag = matched.item;
                var eligibles = $(tag, element);
                var selected = $(selector(), element).first();
                var item = selected.length === 0 ?
                    eligibles.first() :
                    resolve(direction, eligibles, selected[0]);

                if (item.offsetParent) {
                    scrollTo (item, item.offsetParent, direction);
                }
                return $(item);
            };

            var scrollTo = function(element, parent, direction) {
                if(parent.tagName == "TABLE")
                {
                    parent = parent.parentElement;
                }
                var parentBottom = parent.offsetTop + parent.offsetHeight;

                var elementTop = element.offsetTop;
                var elementBottom = elementTop + element.offsetHeight;

                if (elementTop > parent.scrollTop && elementBottom < parent.scrollTop + parent.offsetHeight) {
                    return;
                }

                var scrollTop;
                if (direction === 'prev') {
                    scrollTop = { scrollTop: elementTop };
                } else {
                    scrollTop = { scrollTop: parent.scrollTop + (elementBottom - parentBottom) };
                }

                $(parent).animate(scrollTop, 100);
                return this;
            };

            var selectNext = function() {
                $timeout(function() {
                    get('next').click();
                }, 0);
            };

            var selectPrevious = function() {
                $timeout(function() {
                    get('prev').click();
                }, 0);
            };

            var itemLiteral = attrs.itemLiteral || localise.getString('keyboardBindingDefaultItemLiteral');
            var nextItemLiteral = localise.getString('keyboardBindingNextItem', itemLiteral);
            var previousItemLiteral = localise.getString('keyboardBindingPreviousItem', itemLiteral);
            var modifier = attrs.keyModifier ? (attrs.keyModifier + '+') : '';
            var allowIn = _.isUndefined(attrs.preventHotkeyInInput) || _.isNull(attrs.preventHotkeyInInput) ? ['INPUT'] : null;

            hotkeys.bindTo(scope)
                .add({
                    combo: modifier + 'up',
                    description: previousItemLiteral,
                    allowIn: allowIn,
                    callback: selectPrevious
                })
                .add({
                    combo: modifier + 'down',
                    description: nextItemLiteral,
                    allowIn: allowIn,
                    callback: selectNext
                });

        };
    }]);