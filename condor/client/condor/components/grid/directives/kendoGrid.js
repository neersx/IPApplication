angular.module('inprotech.components.grid').directive('ipKendoGrid', function ($compile, $timeout, $translate, ipKendoGridKeyboardShortcuts, bus) {
    'use strict';

    return {
        restrict: 'E',
        scope: {
            //gridOptions: expression
            id: '@',
            searchHint: '@',
            showAdd: '=?',
            addItemName: '@',
            onAddClick: '&',
            addDisabled: '<?',
            noResultsHint: '@'
        },
        templateUrl: function (element, attrs) {
            if (attrs.mode == 'search') {
                return 'condor/components/grid/directives/kendoSearchGrid.html';
            }
            return 'condor/components/grid/directives/kendoNormalGrid.html';
        },
        link: function (scope, element, attrs) {

            angular.element(".main-content-scrollable").scroll(function () {
                angular.element(document.body).find("[data-role=popup]")
                    .kendoPopup("close");
            });
            scope.hideSearchHint = false;
            scope.hideNoResults = true;
            scope.addLabelParams = {
                itemName: scope.addItemName ? scope.addItemName : $translate.instant('grid.messages.defaultItemName')
            };

            var gridOptions = scope.$parent.$eval(attrs.gridOptions);
            var rowToScrollTo = null;

            bus.singleSubscribe('grid.' + scope.id, scrollToRow);
            bus.singleSubscribe('gridRefresh.' + scope.id, refresh);

            /*
                args:  
                    relativeIndex, rowId - either can be used to select row
                    pageIndex - optional, change to page and set row to be selected (row will be selected on dataBound)
                    unselectRow - optional, unselect row after scrolling
            */
            function scrollToRow(args) {
                var pageIndex = args.pageIndex;

                var row = {
                    id: args.rowId,
                    relativeIndex: args.relativeIndex
                }

                if (pageIndex === 'current' || pageIndex == null) {
                    $timeout(function () {
                        selectAndScroll(row, args.unselectRow);
                    }, 0);
                    return;
                }

                var setRowThenPage = function (page) {
                    rowToScrollTo = row;
                    gridOptions.dataSource.page(page)
                }

                if (pageIndex !== 'last') {
                    setRowThenPage(pageIndex);
                } else if (!gridOptions.pageable) {
                    setRowThenPage(gridOptions.dataSource.totalPages());
                } else {
                    gridOptions.dataSource.fetch().then(function () { // fetch data again to get correct total page (ie. after adding)
                        setRowThenPage(gridOptions.dataSource.totalPages());
                    });
                }
            }

            function selectAndScroll(row, unselectRow) {
                if (gridOptions.onSelect) {
                    gridOptions.onSelect.disabled = true; // Prevent onSelect being triggered when levelling up.
                }

                selectRow(row);
                scrollToSelectedRow(unselectRow);

                if (gridOptions.onSelect) {
                    gridOptions.onSelect.disabled = false;
                }
            }

            function selectRow(row) {
                var grid = getGrid();
                grid.clearSelection();
                if (row.relativeIndex) {
                    var relativeIndex = row.relativeIndex;
                    if (row.relativeIndex === 'last') {
                        relativeIndex = gridOptions.data().length - 1;
                    }
                    gridOptions.selectRowByIndex(relativeIndex);
                } else {
                    selectRowById(row.id);
                }
            }

            function selectRowById(id) {
                var grid = getGrid();
                var item = grid.dataSource.get(id);

                if (!item) {
                    return;
                }
                grid.select('tr[data-uid=\'' + item.uid + '\']');
            }

            function isInView(yOffsetTop, elementHeight) {
                if (yOffsetTop) {
                    return window.pageYOffset < yOffsetTop && yOffsetTop + elementHeight < (window.pageYOffset + window.innerHeight);
                }
            }

            function scrollToSelectedRow(unselectRow) {
                var grid = getGrid();
                var row = grid.select();
                var offset = row.offset();

                if (!offset) {
                    rowToScrollTo = null;
                    return;
                }

                var scrollPosition = 0;
                if (!isInView(offset.top, row.height())) {
                    scrollPosition = offset.top + (row.height() * 2) - window.innerHeight;
                }

                if (scrollPosition > 0) {
                    if (unselectRow) {
                        grid.clearSelection();
                    }
                    $('#mainPane').animate({
                        scrollTop: scrollPosition
                    }, 200);
                }
                rowToScrollTo = null;
            }

            function refresh() {
                var grid = getGrid();
                grid.dataSource.read();
                grid.refresh()
            }

            gridOptions.hidePagerWhenNoResults = true;

            gridOptions.onDataBound = function (d, didSearch) {
                if (d.length === 0) {
                    scope.hideSearchHint = didSearch;
                    scope.hideNoResults = !didSearch;
                } else {
                    scope.hideSearchHint = true;
                    scope.hideNoResults = true;
                }

                if (attrs.mode == 'search') {
                    setTimeout(function() {
                        var lockedElements = element.find('.k-grid-content-locked tr');
                        if (lockedElements.length > 0) {
                            element.find('.k-grid-content tr').each(function(index, ele) {
                                lockedElements.eq(index).height($(ele).height());
                            });
                            element.resize();
                        }
                    }, 0);
                }
                if (attrs.mode == null) {
                    calculateLeftPaddingForNoResultNotification(element);
                }

                if (rowToScrollTo) {
                    selectAndScroll(rowToScrollTo);
                }
            };

            function getGrid() {
                return $('#' + scope.id).data('kendoGrid');
            }

            function calculateLeftPaddingForNoResultNotification(element) {
                var th_elements = element.find("table thead tr:first-child th");
                var i, th_element;

                var padding = 0;

                if (th_elements.eq(0).text().trim() === '') {
                    padding += th_elements.eq(0).outerWidth();
                } else {
                    padding += parseInt(th_elements.eq(0).css("paddingLeft"));
                }

                for (i = 1; i < th_elements.length; i++) {
                    th_element = $(th_elements[i]);
                    if (th_element.text().trim() === '') {
                        padding += th_element.outerWidth();
                    } else {
                        break;
                    }
                }

                if (th_elements.eq(i + 1) && th_elements.eq(i + 1).length > 0) {
                    padding += parseInt(th_elements.eq(i + 1).css("paddingLeft"));
                }

                element.find('div[ng-hide="hideNoResults"]').css({
                    paddingLeft: padding + 'px'
                });
            }

            ipKendoGridKeyboardShortcuts.bindShortcuts(scope.id, element, gridOptions);

            // compile the grid in the parent's scope to prevent grid binding issues
            var gridMarkUp = $('<kendo-grid id="' + scope.id + '" k-options="' + attrs.gridOptions + '"></kendo-grid>');
            element.find('.kendo-search-grid-placeholder').append(gridMarkUp);
            $compile(gridMarkUp)(scope.$parent);

            scope.$on('$destroy', function () {
                if (gridOptions.$destroy) {
                    gridOptions.$destroy();
                }
            });
        }
    };
});