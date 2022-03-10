angular.module('inprotech.components.form').directive('ipAutocomplete', function () {
    'use strict';

    return {
        scope: {
            items: '=',
            total: '=',
            searchValue: '=',
            // keyField: parent,
            // codeField: parent,
            // textField: parent,
            // itemTemplateUrl: parent,
            onSelect: '&',
            onClick: '&',
            onClickOff: '&',
            onViewAll: '&'
        },
        templateUrl: 'condor/components/form/autocomplete.html',
        link: function (scope, element) {
            scope.itemTemplateUrl = scope.$parent.itemTemplateUrl;
            scope.keyField = scope.$parent.keyField;
            scope.codeField = scope.$parent.codeField;
            scope.textField = scope.$parent.textField;

            // move element to document and subscribe to resize/scroll

            scope.parentTextbox = element.parent();
            scope.$parent.linkedAutocomplete = element;

            $('body').append(element);

            $(window).scroll(updateSize);
            $(window).resize(updateSize);
            $(scope.parentTextbox).find('input').focus(updateSize);
            window.setTimeout(updateSize, 500);

            var $e = scope.parentTextbox;
            while ($e && $e.length){
                if ($e.get(0).scrollHeight > $e.height()){
                    $e.scroll(updateSize);
                }
                $e = $e.parent();
            }

            function updateSize(){
                var offset = scope.parentTextbox.offset();
                var width = scope.parentTextbox.width();
                var height = scope.parentTextbox.height();
                element.css({position: 'absolute', 'z-index': 10000, top: offset.top + height, left: offset.left, width: width, overflow: 'visible' });
            }

            //

            element.on('mouseover', '.autocomplete .suggestion-item:not(.highlighted)', function (evt) {
                if (!hasItems()) {
                    return;
                }

                element.find('.autocomplete .suggestion-item.highlighted').removeClass('highlighted');
                $(evt.target).addClass('highlighted');
            });

            element.data('autocomplete', {
                next: function () {
                    if (!hasItems()) {
                        return;
                    }

                    var highlighted = element.find('.autocomplete .suggestion-item.highlighted');
                    var next = highlighted.next();

                    if (!next.length) {
                        next = element.find('.autocomplete .suggestion-item:first');
                    }

                    element.find('.autocomplete .suggestion-item.highlighted').removeClass('highlighted');
                    next.addClass('highlighted');

                    scrollToView(next);
                },

                prev: function () {
                    if (!hasItems()) {
                        return;
                    }

                    var highlighted = element.find('.autocomplete .suggestion-item.highlighted');
                    var prev = highlighted.prev();

                    if (!prev.length) {
                        prev = element.find('.autocomplete .suggestion-item:last');
                    }

                    element.find('.autocomplete .suggestion-item.highlighted').removeClass('highlighted');
                    prev.addClass('highlighted');

                    scrollToView(prev);
                },

                select: function () {
                    if (!hasItems()) {
                        return false;
                    }

                    var highlighted = element.find('.autocomplete .suggestion-item.highlighted');

                    if (highlighted.length) {
                        var s = highlighted.data('$scope');
                        if (s) {
                            scope.onSelect({
                                item: s.item
                            });
                            return true;
                        }
                    }

                    return false;
                },
                hasItems: hasItems
            });

            scope.$on('$destroy', function () {
                element.off();
                element.removeData('autocomplete');
            });

            function scrollToView(elm) {
                if (!elm || !elm.length) {
                    return;
                }

                var height = elm.outerHeight();
                var offsetTop = elm.offset().top - element.find('.suggestion-list').offset().top;
                var scrollTop = element.find('.suggestion-list').scrollTop();
                var containerHeight = element.find('.suggestion-list').height();
                var top = offsetTop;
                var bottom = top + height;

                if (bottom > containerHeight) {
                    element.find('.suggestion-list').scrollTop(scrollTop + bottom - containerHeight);
                }

                if (top < 0) {
                    element.find('.suggestion-list').scrollTop(scrollTop + top);
                }
            }

            function hasItems() {
                return Boolean(scope.items && scope.items.length);
            }
        }
    };
});
