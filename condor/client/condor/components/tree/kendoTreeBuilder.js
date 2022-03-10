angular.module('inprotech.components.tree').factory('kendoTreeBuilder', function(utils) {
    'use strict';

    var defaultOptions = {
        loadOnDemand: true,
        animation: false
    };

    return {
        buildOptions: buildOptions
    };

    /* custom options: 
    - expandedByDefault: all nodes will be expanded in initial load.    
    */
    function buildOptions(scope, options) {
        var suppressDigest = false;
        options = angular.extend({}, defaultOptions, options);

        if (options.expandedByDefault) {
            options.loadOnDemand = false;
            _.each(options.dataSource, setExpanded);
        }

        //automatically trigger digest loop in select event
        if (options.select) {
            var oldSelect = options.select;
            options.select = function() {
                oldSelect.apply(this, arguments);
                scope.$digest();
            };
        }

        if (!options.expand) {
            options.expand = angular.noop;
        }

        var oldExpand = options.expand;
        options.expand = function() {
            oldExpand.apply(this, arguments);
            if (suppressDigest) {
                return;
            }
            utils.safeApply(scope);
        };

        if (!options.collapse) {
            options.collapse = angular.noop;
        }

        var oldCollapse = options.collapse;
        options.collapse = function() {
            oldCollapse.apply(this, arguments);
            if (suppressDigest) {
                return;
            }
            utils.safeApply(scope);
        };

        if (options.drop) {
            var oldDrop = options.drop;
            options.drop = function() {
                var evt = arguments[0];
                evt.complete = function() {
                    moveNode(evt);
                };

                oldDrop.apply(this, arguments);
            };
        }

        options.scrollToSelected = function() {
            if (options.$widget && options.$widget.select().length) {
                var widgetTop = $(options.$widget.element).offset().top;
                var item = $(options.$widget.select()[0]);
                var rowHeight = item.find('div').height()
                var itemScrollBottom = item.offset().top + rowHeight;

                if (itemScrollBottom > $(window).height() || itemScrollBottom < ($(window).scrollTop() + widgetTop)) {
                    var scrollFixedTop = options.$widget.element.offset().top || 0;
                    $('html,body').animate({
                        scrollTop: itemScrollBottom - scrollFixedTop
                    });
                }

                // hack to prevent window from scrolling on focus.
                var x = window.pageXOffset,
                    y = window.pageYOffset;
                options.$widget.wrapper.focus();
                window.scrollTo(x, y);
            }
	};

        options.showLoading = function() {
            kendo.ui.progress(options.$widget.element, true);
        };
	
        options.hideLoading = function() {
            kendo.ui.progress(options.$widget.element, false);
        };

        scope.$on('kendoWidgetCreated', function(evt, widget) {
            // this instance must match the widget firing the event
            if (options.id !== widget.options.id) {
                return;
            }

            options.$widget = widget;
            options.scrollToSelected();

            options.expandAll = function() {
                suppressDigest = true;
                widget.expand('.k-item');
                suppressDigest = false;
            };

            options.collapseAll = function() {
                suppressDigest = true;
                widget.collapse('.k-item');
                suppressDigest = false;
            };

            options.deselect = function() {
                widget.select($());
            };
        });

        return options;
    }

    function setExpanded(item) {
        item.expanded = true;
        if (item.items) {
            _.each(item.items, setExpanded);
        }
    }

    function moveNode(evt) {
        var widget = evt.sender;
        switch (evt.dropPosition) {
            case 'before':
                widget.insertBefore(evt.sourceNode, $(evt.destinationNode));
                break;
            case 'after':
                widget.insertAfter(evt.sourceNode, $(evt.destinationNode));
                break;
            case 'over':
                widget.append(evt.sourceNode, $(evt.destinationNode));
                break;
        }
    }
});
