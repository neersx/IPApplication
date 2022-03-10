//todo: change name to ipBulkActionsMenu
angular.module('inprotech.components.bulkactions').directive('bulkActionsMenu', function(commonActions, bus) {
    'use strict';
    return {
        restrict: 'EA',
        replace: true,
        scope: {
            actions: '=',
            initialised: '&',
            onClear: '&',
            onSelectAll: '&',
            onSelectThisPage: '&',
            onUpdateValues: '&'
        },
        templateUrl: 'condor/components/bulkactions/directives/menu.html',

        link: function(scope, element, attr) {
            scope.selectionOptions = {
                all: 'all',
                page: 'page',
                manual: 'manual',
                none: 'none'
            };

            scope.items = {
                totalCount: 0,
                currentCount: 0,
                selected: 0
            };

            scope.paging = {
                available: false,
                size: 0
            };

            scope.selectedItems = [];

            scope.isSelectPage = false;

            scope.currentMode = scope.selectionOptions.none;

            scope.tabIndex = 100;

            var update = function(data) {
                assignValIfDefined(data.totalCount, 'totalCount');
                assignValIfDefined(data.selected, 'selected');
                assignValIfDefined(data.currentCount, 'currentCount');

                if (scope.paging.available && scope.items.currentCount === scope.items.selected && scope.items.selected > 0 && data.pageSelected) {
                    scope.currentMode = scope.selectionOptions.page;
                } else if (scope.items.totalCount === scope.items.selected && scope.items.selected > 0 && !scope.isFullSelectionPossible) {
                    scope.currentMode = scope.selectionOptions.all;
                } else if (scope.items.selected > 0) {
                    scope.currentMode = scope.selectionOptions.manual;
                } else {
                    scope.currentMode = scope.selectionOptions.none;
                }
                scope.isSelectPage = data.pageSelected;


            };

            var assignValIfDefined = function(newValue, assignTo) {
                if (!angular.isUndefined(newValue)) {
                    scope.items[assignTo] = newValue;
                }
            };

            /*eslint no-unused-vars:0*/
            var updatePaginationInfo = function(data) {
                scope.paging.available = data.paging;
                scope.paging.size = data.pageSize;
            };

            var reset = function() {
                scope.currentMode = scope.selectionOptions.none;
                scope.doUpdateValues();
            };

            if (!attr.context) {
                throw 'context is required for bulk action menu';
            }

            bus.channel('bulkactions-selection-service').subscribe(subscribe);

            scope.isManualSelection = function() {
                return scope.currentMode === scope.selectionOptions.manual || scope.currentMode === scope.selectionOptions.page;
            };

            scope.isAllSelected = function() {
                return scope.currentMode === scope.selectionOptions.all;
            };

            scope.isPageSelected = function() {
                return scope.currentMode === scope.selectionOptions.page;
            };

            scope.doClear = function() {
                scope.items.selected = 0;
                scope.currentMode = scope.selectionOptions.none;
                scope.onClear();
            };

            scope.isClearDisabled = function() {
                return scope.items.selected === 0 && !scope.isAllSelected();
            };

            scope.doSelectAll = function(e) {
                scope.isSelectPage = !scope.isSelectPage;
                if (scope.isSelectPage) {
                    scope.currentMode = scope.selectionOptions.all;
                }
                scope.onSelectAll({
                    val: scope.isSelectPage
                });
            };

            scope.doSelectThisPage = function(e) {
                scope.isSelectPage = !scope.isSelectPage;

                if (scope.isSelectPage) {
                    scope.currentMode = scope.selectionOptions.page;
                }
                scope.onSelectThisPage({
                    val: scope.isSelectPage
                });
            };

            scope.doUpdateValues = function() {
                scope.onUpdateValues();
            };

            var buildActionItems = function() {
                var actionInfos = commonActions.get();

                var augment = function(item, shouldDisable) {
                    if (item.shouldDisable) {
                        return item;
                    }

                    item.shouldDisable = shouldDisable || function() {
                        return scope.items.selected === 0 && !scope.isAllSelected();
                    };

                    item.invokeIfEnabled = function() {
                        if (item.shouldDisable()) {
                            return;
                        }

                        item.click();
                        scope.doUpdateValues();
                    };

                    return item;
                };

                return _.map(scope.actions || [], function(item) {
                    var template = _.find(actionInfos, function(a) {
                        return a.id === item.id;
                    });

                    if (template) {
                        item.click = item.click || template.click;
                        item.text = item.text || template.text;
                        item.icon = item.icon || template.icon;
                    }

                    item.enabled = item.enabled || function() {
                        return true;
                    };

                    return augment(item, function() {
                        var selectionInvalid = function() {
                            var maxTemplateSelection = template && template.maxSelection;
                            var maxSelected = item.maxSelection || maxTemplateSelection;
                            if (!maxSelected) {
                                return scope.items.count === 0;
                            }

                            return scope.items.count === 0 || scope.items.selected > maxSelected;
                        };

                        if (angular.equals(item.id, 'case-export-excel')) {
                            item.text = scope.items.selected > 0 ? 'bulkactionsmenu.ExportSelectedToExcel' : 'bulkactionsmenu.ExportAllToExcel';
                        }

                        return !item.enabled() || selectionInvalid();
                    });
                });
            };

            scope.context = attr.context;
            scope.actionItems = buildActionItems();
            scope.isFullSelectionPossible = attr.isFullSelectionPossible || false;

            if (scope.initialised) {
                scope.initialised();
            }

            function subscribe(data) {
                if (data.context !== attr.context) {
                    return;
                }

                if (data.type === 'reset') {
                    reset();
                    return;
                }

                if (data.type === 'updatePaginationInfo') {
                    updatePaginationInfo(data);
                    return;
                }

                update(data);
            }

            scope.$on('$destroy', function() {
                bus.channel('bulkactions-selection-service').unsubscribe(subscribe);
            });

            scope.isEmptyList = function() {
                return scope.items.totalCount === 0;
            };

            var isMenuDisplayed = function() {
                return !element.find('.dd-dropdown').first().is(':hidden');
            };

            scope.element = element;

            element.on('click', function(e) {
                e.preventDefault();
                if (!scope.isEmptyList() && !isMenuDisplayed()) {
                    $(this).find('.dd-link').first().addClass('active').next('.dd-dropdown').fadeToggle(100, function() {
                        $(this).find('ul li a:first').focus();
                    });
                } else if (isMenuDisplayed()) {
                    $(this).find('.dd-dropdown').first().trigger('focusout');
                }
            }).on('click', '.dd-dropdown', function(e) {
                e.stopPropagation();
            }).on('focusout', '.dd-dropdown', function() {
                $(this).prev('.dd-link').removeClass('active');
                $(this).fadeOut(100);
            });
        }
    };
});