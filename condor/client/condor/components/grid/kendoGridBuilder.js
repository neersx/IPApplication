angular.module('inprotech.components.grid').factory('kendoGridBuilder', function($compile, columnFilterHelper, commonQueryHelper, $q, $translate, columnPickerHelper) {
    'use strict';

    var defaultOptions = {
        autoBind: false,
        resizable: true,
        reorderable: true,
        editable: false,
        groupable: false,
        scrollable: false,
        columnResizeHandleWidth: 6,
        serverFiltering: true,
        oneTimeBinding: false,
        sortable: {
            allowUnsort: false
        },
        data: function() {
            return this.dataSource.data();
        },
        detailExpand: function(args) {
            if (args.detailRow) {
                var inputElem = args.detailRow.find('*[ip-autofocus]');
                if (inputElem) {
                    inputElem.trigger('setFocus');
                }
            }
        },
        onGridCreated: angular.noop,
        onDataCreated: angular.noop,
        onDropCompleted: angular.noop,
        columnReorder: function(e) {
            var grid = e.sender.wrapper.data('kendoGrid');
            if (e.sender.columns[e.newIndex].fixed) {
                var targetCol = e.sender.columns[e.newIndex];
                var sourceCol = e.sender.columns[e.oldIndex];

                if (!targetCol.fixed) {
                    return;
                }

                setTimeout(function() {
                    var columns = grid.columns;
                    var pos;

                    // wont swap with fixed column
                    if (sourceCol === columns[e.newIndex]) {
                        pos = e.newIndex;
                    } else if (sourceCol === columns[e.newIndex + 1]) {
                        pos = e.newIndex + 1;
                    }

                    var newPos = pos;
                    while (newPos + 1 < columns.length && columns[newPos + 1].fixed) {
                        newPos++;
                    }

                    if (newPos === pos) {
                        return;
                    }
                    grid.options.columnSelection.helper.updateColumnOrder(e.oldIndex, newPos, e.column);
                    grid.reorderColumn(newPos, columns[pos]);
                }, 0);
            } else {
                grid.options.columnSelection.helper.updateColumnOrder(e.oldIndex, e.newIndex, e.column);
            }
        },
        hideExpand: false,
        showExpandAll: false,
        getCurrentFilters: angular.noop,
        hidePagerWhenNoResults: false,
        expandAll: expandAll,
        filterOptions: {
            keepFiltersAfterRead: false,
            sendExplicitValues: false
        },
        columnSelection: {
            localSetting: null,
            localSettingSuffix: null
        },
        topicItemNumberKey: null,
        $destroy: angular.noop
    };

    return {
        buildOptions: buildKendoGridOptions
    };

    function initOptions() {
        var options = angular.extend({}, defaultOptions);
        var array = [];

        Object.defineProperty(options, 'onDataBound', {
            get: function() {
                return array;
            },

            set: function(val) {
                array.push(val);
            }
        });

        return options;
    }

    function buildKendoGridOptions(scope, gridOptions) {
        gridOptions = angular.extend(initOptions(), gridOptions);
        gridOptions = initColumnSelection(gridOptions);
        gridOptions = initGridMethods(gridOptions);

        if (gridOptions.topicItemNumberKey) {
            if (typeof gridOptions.topicItemNumberKey === 'string') {
                gridOptions.topicItemNumberKey = {
                    key: gridOptions.topicItemNumberKey
                };
            }
            gridOptions.topicItemNumberKey = angular.extend({
                isSubSection: false
            }, gridOptions.topicItemNumberKey);
        }

        if (gridOptions.pageable) {
            gridOptions.pageable = angular.extend({
                pageSize: 20,
                pageSizes: [10, 20, 50, 100],
                messages: {
                    itemsPerPage: ''
                }
            }, gridOptions.pageable);
        }

        if (gridOptions.actions) {
            var onClick, template = '',
                width = 20;

            if (gridOptions.actions.edit) {
                onClick = '';
                width += 30;
                if (gridOptions.actions.edit.onClick) {
                    onClick = ' data-ng-click="' + gridOptions.actions.edit.onClick + '"';
                }

                template += '<ip-icon-button class="btn-no-bg" ng-disabled="dataItem.deleted" button-icon="pencil-square-o" ip-tooltip="{{::\'Edit\' | translate }}" ' + onClick + '></ip-icon-button>';
            }

            if (gridOptions.actions.delete) {
                onClick = '';
                width += 30;

                var onRowDelete = 'kendoGridOnRowDelete_' + gridOptions.id;

                scope[onRowDelete] = function(dataItem) {
                    if (dataItem.isAdded || dataItem.added) {
                        gridOptions.dataSource.remove(dataItem);
                    }
                };

                if (gridOptions.actions.delete.onClick) {
                    onClick = gridOptions.actions.delete.onClick;
                }
                template += '<ip-kendo-toggle-delete-button data-model="dataItem" data-has-detail="' + Boolean(gridOptions.detailTemplate) + '" data-ng-click="' + onRowDelete + '(dataItem);' + onClick + '"></ip-kendo-toggle-delete-button>';
            }

            if (gridOptions.actions.custom) {
                width += 30;

                template += gridOptions.actions.custom.template;
            }

            gridOptions.columns.unshift({
                width: width + 'px',
                template: template,
                fixed: true,
                locked: true
            });
        }

        var processColumnHeadings = function(columns) {
            _.each(columns, function(col) {
                if (gridOptions.titlePrefix && col.title && col.title[0] === '.') {
                    col.title = gridOptions.titlePrefix + col.title;
                }

                col.title = col.title ? $translate.instant(col.title) : ' ';
                if (!col.filterable) {
                    col.filterable = false;
                } else {
                    gridOptions.filterable = true;
                }

                // all of fixed columns should be grouped to left
                if (col.fixed) {
                    col.headerAttributes = angular.extend(col.headerAttributes || {}, {
                        'data-fixed': true
                    });
                }

                if ((col.oneTimeBinding === true || gridOptions.oneTimeBinding === true) && !col.template) {
                    col.template = '<span ng-bind="::dataItem.' + col.field + '">';
                }

                if (col.columns) {
                    processColumnHeadings(col.columns);
                }
            });
        };

        processColumnHeadings(gridOptions.columns);

        if (gridOptions.autoGenerateRowTemplate) {

            if (gridOptions.reorderable === true) {
                gridOptions.rowTemplate = function() {
                    return buildRowTemplate(gridOptions, true);
                };
                gridOptions.altRowTemplate = function() {
                    return buildAltRowTemplate(gridOptions, true);
                };
            } else {
                gridOptions.rowTemplate = buildRowTemplate(gridOptions);
                gridOptions.altRowTemplate = buildAltRowTemplate(gridOptions);
            }

        }

        var dataSourceOptions = initGridDataSourceOptions(scope, gridOptions);
        gridOptions.dataSource = new kendo.data.DataSource(dataSourceOptions);

        if (gridOptions.onPageSizeChanged) {
            var existingDataBinding = gridOptions.dataBinding;
            gridOptions.dataBinding = function(e) {
                var pageSize = e.sender.dataSource.pageSize();
                if (pageSize !== gridOptions.pageable.pageSize) {
                    gridOptions.pageable.pageSize = pageSize;
                    gridOptions.onPageSizeChanged(pageSize);
                }
                if (existingDataBinding && _.isFunction(existingDataBinding)) {
                    existingDataBinding.apply(this, arguments);
                }
            };
        }

        if (gridOptions.selectable === 'row' && gridOptions.navigatable &&
            gridOptions.selectOnNavigate && !gridOptions.navigate) {
            gridOptions.navigate = function($event) {
                this.select($event.element.parent());
            };
        }

        gridOptions = columnFilterHelper.init(gridOptions);

        gridOptions = initWidgetCreatedEvent(gridOptions, scope);

        gridOptions.$destroy = function() {
            var garbage = gridOptions.$customFilterScopes || [];
            garbage.forEach(function(each) {
                each.$destroy();
            });
        };

        return gridOptions;
    }

    function initColumnSelection(gridOptions) {
        var selector = gridOptions.columnSelection;
        if (selector.localSetting) {
            selector.helper = columnPickerHelper.init(selector.localSetting, selector.localSettingSuffix);
            gridOptions.columns = selector.helper.initColumnDisplay(gridOptions.columns);
        } else {
            selector.helper = {
                updateColumnOrder: angular.noop,
                reset: angular.noop
            };
        }
        return gridOptions;
    }

    function initGridMethods(gridOptions) {
        var runSearch = initSearch(gridOptions);
        gridOptions.search = function(args) {
            gridOptions.$setLoadingState('ip-data-pending');
            return runSearch(args);
        };

        gridOptions.clear = function() {
            gridOptions.$didSearch = false;
            gridOptions.$resetPage();
            gridOptions.dataSource.data([]);

            if (gridOptions.$widget) {
                gridOptions.$widget.dataSource._sort = null;
                gridOptions.$widget.element.find('.k-grid .k-header .k-i-arrow-s, .k-grid .k-header .k-i-arrow-n').remove();

                if (gridOptions.$widget.pager) {
                    gridOptions.$widget.pager.element.hide();
                }
            }

            columnFilterHelper.reset(gridOptions);
            gridOptions.$setLoadingState('ip-data-initial');
        };

        gridOptions.$resetPage = function() {
            if (gridOptions.$widget && gridOptions.$widget.pager) {
                gridOptions.$widget.pager.dataSource._page = 1;
                gridOptions.$widget.pager.dataSource._skip = 0;
            }
        };

        gridOptions.$setLoadingState = function(state) {
            setLoadingState(this.id, state);
        };

        gridOptions.$read = function() {
            gridOptions.$setLoadingState('ip-data-loading');
            return gridOptions.$widget.dataSource.read();
        };

        gridOptions.getCurrentFilters = function() {
            return columnFilterHelper.buildQueryParams(gridOptions.$widget.dataSource.filter(), gridOptions);
        };

        gridOptions.selectRowByIndex = function(index) {
            return gridOptions.$widget.select('tbody tr.k-master-row:eq(' + index + ')');
        };

        gridOptions.getSelectedRow = function() {
            return gridOptions.$widget.dataItem(gridOptions.$widget.select());
        };

        gridOptions.selectFocusedRow = function() {
            var row = gridOptions.$widget.element.find('#' + this.id + '_active_cell').parent('tr');
            gridOptions.$widget.select(row);
            return gridOptions.getSelectedRow();
        };

        gridOptions.clickHyperlinkedCell = function() {
            var selected = $.map(gridOptions.$widget.element.find('#' + this.id + '_active_cell'), function(item) {
                return $(item);
            });
            if (selected.length > 0) {
                var hrefCon = $(selected)[0].find("a").not(".k-grid-filter");
                if (hrefCon.length > 0) {
                    hrefCon[0].click();
                }
            }
        };

        gridOptions.selectRowAndScrollByIndex = function(offsetElem, index) {
            var selector = 'tbody tr.k-master-row:eq(' + index + ')';
            gridOptions.$widget.select(selector);

            var scrollTop = $(selector).position().top;

            $('#mainPane').scrollTop(scrollTop);
        };

        gridOptions.removeDeletedRows = function() {
            var data = gridOptions.dataSource.data();

            for (var i = data.length - 1; i >= 0; i--) {
                var item = data[i];
                if (item && item.deleted) {
                    gridOptions.dataSource.remove(item);
                }
            }

            if (gridOptions.dataSource.data().length === 0 && gridOptions.pageable) {
                gridOptions.dataSource.fetch(); // refresh pager when all items have been deleted on a page
            }
        };

        gridOptions.insertAfterSelectedRow = function(newItem) {
            var relativeIndex = gridOptions.dataSource.data().length;
            var selectedRow = gridOptions.getSelectedRow();
            if (selectedRow !== null) {
                relativeIndex = gridOptions.dataSource.indexOf(selectedRow);
            }
            gridOptions.dataSource.insert(relativeIndex + 1, newItem);
            gridOptions.selectRowByIndex(relativeIndex + 1);
        };

        gridOptions.getRelativeItemAbove = function(item) {
            var currentIndex = _.indexOf(gridOptions.dataSource.data(), item);
            if (currentIndex > 0) {
                var relativeIndex = _.chain(gridOptions.dataSource.data())
                    .first(currentIndex)
                    .findLastIndex(function(i) {
                        return i.deleted === undefined || i.deleted === false;
                    })
                    .value();
                if (relativeIndex >= 0) {
                    return gridOptions.dataSource.data()[relativeIndex];
                }
            }
            return null;
        };

        gridOptions.insertRow = function(insertIndex, item) {
            gridOptions.dataSource.insert(insertIndex, item);
            setTimeout(function() {
                var el = gridOptions.$widget.element.find('tr.k-master-row').eq(insertIndex).find('*[focus-on-add]');
                if (el.find('input').length > 0) {
                    el.find('input').focus();
                } else {
                    el.find('select').focus();
                }
            }, 400);
        };

        gridOptions.getQueryParams = function() {
            if (gridOptions.$widget === null || gridOptions.$widget === undefined ||
                gridOptions.$widget.dataSource._sort === undefined || gridOptions.$widget.dataSource._sort === null)
                return null;
            return {
                sortBy: gridOptions.$widget.dataSource._sort[0].field,
                sortDir: gridOptions.$widget.dataSource._sort[0].dir
            };
        };

        gridOptions.highlightAfterEditing = function(dataItem) {
            var oldItem = gridOptions.dataSource.get(dataItem.key);

            if (oldItem) {
                // item was edited, it is in the list
                var idx = gridOptions.dataSource.indexOf(oldItem);
                gridOptions.dataSource.remove(oldItem);
                gridOptions.dataSource.insert(idx, dataItem);
            } else {
                // item was added, it is not in the list
                gridOptions.dataSource.insert(0, dataItem);
            }

            gridOptions.highlightSingleItem(dataItem.key);
        };

        gridOptions.highlightSingleItem = function(key) {
            var rows = gridOptions.$widget.element.find('tr');
            _.each(rows, function(row) {
                $(row).removeClass('k-state-selected');
            });

            var gridItem = gridOptions.dataSource.get(key);
            if (gridItem) {
                var row = gridOptions.$widget.element.find('tr[data-uid=\'' + gridItem.uid + '\']');
                if (row.length > 0) {
                    row.addClass('k-state-selected');
                    row[0].scrollIntoView();
                }
            }
        };

        gridOptions.selectLastNavigatedItem = function(lastNavigatedId, rowKey) {
            var grid = gridOptions.$widget;
            grid.items().each(function(idx, item) {
                var dataItem = grid.dataItem(item);
                if (dataItem.id === lastNavigatedId) {
                    // select grid item
                    var rows = grid.element.find('tr');
                    _.each(rows, function(row) {
                        $(row).removeClass('k-state-selected');
                    });
                    grid.select(item);

                    // scroll to grid item
                    var activeRow = gridOptions.$widget.element.find('#' + rowKey).parent('td');
                    if (activeRow.length > 0) {
                        activeRow[0].scrollIntoView(false);
                    }
                }
            });
        };

        gridOptions.highlightItemByIndex = function(index) {
            if (gridOptions.$widget.element) {
                var rows = gridOptions.$widget.element.find('tr');
                _.each(rows, function(row) {
                    $(row).removeClass('k-state-selected');
                });
                var dataItem = gridOptions.dataSource.data()[index];
                if (dataItem) {
                    var row = gridOptions.$widget.element.find('tr[data-uid=\'' + dataItem.uid + '\']');
                    if (row.length > 0) {
                        row.addClass('k-state-selected');
                        row[0].scrollIntoView();
                        gridOptions.$widget.select(row[0]);
                    }
                }
            }
        };

        gridOptions.findAndHighlightItemByIndex = function(index) {
            if (gridOptions.$widget && gridOptions.$widget.element) {
                var rows = gridOptions.$widget.element.find('tr');
                _.each(rows, function(row) {
                    $(row).removeClass('k-state-selected');
                });
                var requiredPage = Math.ceil((index + 1) / gridOptions.dataSource.pageSize());
                var currentPage = gridOptions.dataSource.page();
                var dataItem = gridOptions.dataSource.data()[index];
                if (currentPage !== 1 && requiredPage === 1) {
                    dataItem = null;
                }
                if (dataItem) {
                    var row = gridOptions.$widget.element.find('tr[data-uid=\'' + dataItem.uid + '\']');
                    if (row.length > 0) {
                        row.addClass('k-state-selected');
                        row[0].scrollIntoView();
                        gridOptions.$widget.select(row[0]);
                    }
                } else {
                    gridOptions.page(requiredPage);
                    gridOptions.dataSource.page(requiredPage);
                }
            }
        };

        gridOptions.removeItem = function(dataItem) {
            var oldItem = gridOptions.dataSource.get(dataItem.key);
            gridOptions.dataSource.remove(oldItem);
        };

        return gridOptions;
    }

    function initGridDataSourceOptions(scope, gridOptions) {
        var lastSort;

        var result = {
            serverFiltering: gridOptions.serverFiltering,
            serverSorting: gridOptions.pageable ? true : gridOptions.serverSorting,
            transport: {
                read: function(e) {
                    gridOptions.$didSearch = true;

                    var thisSort = JSON.stringify(e.data.sort);

                    if (thisSort === "null") {
                        thisSort = null;
                    }

                    if (lastSort != thisSort) {
                        e.data.page = 1;
                        e.data.skip = 0;
                        lastSort = thisSort;
                    }

                    var args = commonQueryHelper.buildQueryParams(e, gridOptions);

                    return $q.when(gridOptions.read(args)).then(function(d) {
                        if (gridOptions.pageable) {
                            d.data = new kendo.data.ObservableArray(d.data || []);
                            raiseDataCountEvent(scope, gridOptions, d.pagination ? d.pagination.total : d.data.length);
                        } else {
                            d = new kendo.data.ObservableArray(d || []);
                            raiseDataCountEvent(scope, gridOptions, d.length);
                        }
                        e.success(d);
                        gridOptions.onDataCreated();
                        setPagerTooltips(scope, gridOptions.$widget.pager);
                    }, function() {
                        e.error();
                    });
                }
            }
        };

        if (gridOptions.pageable) {
            result = angular.merge({
                schema: {
                    data: 'data',
                    total: function(args) {
                        if (args.pagination) {
                            return args.pagination.total;
                        }

                        return args.total;
                    },
                    model: {
                        id: 'id'
                    } // required by kendoGrid.js.selectRowById()
                },
                serverPaging: true,
                pageSize: gridOptions.pageable.pageSize
            }, result);

            if (gridOptions.schema) {
                result = angular.merge(result, {
                    schema: gridOptions.schema
                });
            }
        }

        return result;
    }

    function initWidgetCreatedEvent(gridOptions, scope) {
        scope.$on('kendoWidgetCreated', function(evt, widget) {
            // this instance must match the widget firing the event
            if (gridOptions.id !== widget.options.id) {
                return;
            }

            var id = gridOptions.id;

            gridOptions.$setLoadingState('ip-data-initial');
            gridOptions.$widget = widget;

            if (widget.element.attr('id') !== gridOptions.id) {
                widget.element.attr('id', gridOptions.id);
            }

            if (widget.pager) {
                widget.pager.element.hide();
                widget.element.find('th.k-header:has(a.k-link)').on('click', function() {
                    gridOptions.$resetPage();
                    widget.pager.refresh();
                });

                setPagerTooltips(scope, gridOptions.$widget.pager);
            }

            widget.element.data('kendoGrid').bind('dataBound', function() {
                var boundData = widget.element.data('kendoGrid').dataSource.data();

                if (widget.pager) {
                    if (boundData.length > 0) {
                        $('#' + id).removeClass('ip-data-no-results');
                        if (widget.element.data('kendoGrid').dataSource.total() >= 5) {
                          var mainElement=  widget.pager.element;
                          if( mainElement.find('select.k-dropdown')[0]){
                            mainElement.find('select.k-dropdown')[0].remove();
                          }
                         if(mainElement.find('ul.k-pager-numbers')){
                            mainElement.find('ul.k-pager-numbers').css('list-style', 'none').css('padding-left','0');
                         }
                         if( mainElement.find('.k-pager-first span.k-i-arrow-end-left')){
                                mainElement.find('.k-pager-first span').addClass('k-i-seek-w !important');
                             }
                                 if(mainElement.find('.k-pager-first+.k-pager-nav span.k-i-arrow-60-left')){
                            mainElement.find('.k-pager-first+.k-pager-nav span').addClass('k-i-arrow-w !important');
                         }

                         if(mainElement.find('.k-pager-nav span.k-i-arrow-60-right')){
                            mainElement.find('.k-pager-nav span').addClass('k-i-arrow-e !important');
                         }

                         if(mainElement.find('.k-pager-last span.k-i-arrow-end-right')){
                            mainElement.find('.k-pager-last span').addClass('k-i-seek-e !important');
                         }
                            widget.pager.element.show();
                        }
                        else {
                            widget.pager.element.hide();
                        }
                    } else {
                        $('#' + id).addClass('ip-data-no-results');
                        if (gridOptions.hidePagerWhenNoResults) {
                            widget.pager.element.hide();
                        } else {
                            widget.pager.element.show();
                        }
                    }
                }

                if (!gridOptions.hideExpand) {
                    addExpandRowIcon(id);
                } else {
                    hideExpandsIconColumn(id, gridOptions.$widget.columns.length);
                }

                if (gridOptions.showExpandAll) {
                    toggleExpandCollapse();
                }

                /*eslint no-constant-condition:0*/
                if (!gridOptions.autoGenerateRowTemplate && gridOptions.rowAttributes) {
                    if (typeof gridOptions.rowAttributes === 'function') {
                        gridOptions.$widget.items().each(function(idx, tr) {
                            var dataItem = gridOptions.$widget.dataItem(tr);
                            gridOptions.rowAttributes(dataItem, tr);
                        });
                    }
                }

                gridOptions.$setLoadingState('ip-data-loaded');

                _.each(gridOptions.onDataBound, function(fn) {
                    if (_.isFunction(fn)) {
                        fn(boundData, gridOptions.$didSearch);
                    }
                });

                $('#' + id).find('table').on('keydown', function(e) {
                    if (e.keyCode === 13) {
                        e.stopImmediatePropagation();
                        initiateEnterDownOnActiveCell(id);
                    }
                    if ((e.keyCode === 40 || e.keyCode === 38) && gridOptions.navigatable) {
                        initiateScorllUpDownOnGrid(id, gridOptions);
                    }
                });

                $('#' + id).find('table a').each(function() {
                    $(this).on('keydown', function(e) {
                        if (e.keyCode === 13) {
                            e.stopImmediatePropagation();
                            initiateEnterDownOnActiveCell(id);
                        }
                    });
                });
            });

            if (gridOptions.hideExpand) {
                addRowClickHandler(id);
            }

            widget.element.find('th[data-role=columnsorter] a.k-link:not(:has(span.col-sortable))').append('<span class="k-icon col-sortable"></span>');

            if (gridOptions.showExpandAll) {
                widget.element.find('thead.k-grid-header tr th.k-hierarchy-cell.k-header').append('<a tabindex="-1" class="k-icon k-i-expand no-underline" href="javascript:void(0)" id="expandCollapseAll"></a>').on('click', function(e) {
                    expandCollapseAll(id);
                    e.stopImmediatePropagation();
                });
            }

            widget.element.find('.k-header, .k-grid-header .k-link, .k-grid-header .k-filter').on('click', function(e) {
                if (!gridOptions.$didSearch) {
                    e.stopPropagation();
                    e.preventDefault();
                }
            });

            //prevent from row selection on action button clicked
            widget.element.on('click', '.grid-actions', function(e) {
                e.stopPropagation();
            });

            // if column is set to fixed it's not able to reorder or resize
            widget.element.find('th[data-fixed]').each(function() {
                var stopPropagation = function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    return false;
                };

                $(this).on('mousedown mousemove mouseup pointerdown MSPointerDown', stopPropagation);
            });

            if (gridOptions.dragDropRows) {
                widget.element.data('kendoGrid').table.kendoDraggable({
                    filter: 'tbody > tr',
                    group: 'gridGroup',
                    threshold: 100,
                    axis: 'y',
                    hint: function(e) {
                        return '<div class="k-grid k-widget"><table role="grid" class="k-selectable" width="100%"><tbody role="rowgroup"><tr class="k-master-row ng-scope k-state-selected" role="row">' + e.html() + '</tr></tbody></table></div>';
                    }
                });
                widget.element.data('kendoGrid').table.kendoDropTargetArea({
                    filter: 'td',
                    group: 'gridGroup',
                    drop: function(e) {
                        e.draggable.hint.hide();
                        if (!$(e.draggable.currentTarget).data().$$kendoScope && !$(e.dropTarget).closest('tr').data().$$kendoScope) {
                            return false;
                        }
                        var grid = widget.element.data('kendoGrid');
                        var args = {};
                        args.sender = grid;
                        var target = grid.dataSource.getByUid($(e.draggable.currentTarget).data().$$kendoScope.dataItem.uid),
                            destElement = $(e.dropTarget).closest('tr'),
                            dest = grid.dataSource.getByUid(destElement.data().$$kendoScope.dataItem.uid),
                            destPosition = grid.dataSource.indexOf(dest);

                        if ($(e.draggable.currentTarget).data().$$kendoScope.dataItem.uid !== destElement.data().$$kendoScope.dataItem.uid) {
                            args.selectedDataItem = $(e.draggable.currentTarget).data().$$kendoScope.dataItem;
                            grid.dataSource.remove(target);
                            grid.dataSource.insert(destPosition, target);
                            args.hasSelectedRowChanges = true;
                            args.maxIndex = grid.dataSource._data.length - 1;
                            args.currentTarget = destPosition;
                            gridOptions.onDropCompleted(args);
                        }
                    }
                });
            }

            widget.autoFillGrid = function() {
                var $gridHeaderTable = widget.thead.closest('table');
                var gridDataWidth = $gridHeaderTable.width();
                var gridWrapperWidth = $gridHeaderTable.closest('.k-grid-header-wrap').innerWidth();
                if (gridDataWidth < gridWrapperWidth) {
                    var $headerCols = $gridHeaderTable.find('colgroup > col');
                    var $tableCols = widget.table.find('colgroup > col');
                    var sizeFactor = (gridWrapperWidth / gridDataWidth);

                    $headerCols.add($tableCols).not('.k-group-col').each(function() {
                        var currentWidth = $(this).width();
                        var newWidth = (currentWidth * sizeFactor);
                        $(this).css({
                            width: newWidth
                        });
                    });
                }
            };

            //new version of dragDropRows with simplified implementation
            if (gridOptions.rowDraggable) {
                var grid = widget.element.data('kendoGrid');
                grid.table.find('tbody').addClass('draggable');
                grid.table.kendoSortable({
                    filter: 'tbody > tr:not(.deleted)',
                    axis: 'y',
                    hint: function(elm) {
                        var table = $('<table class="k-grid k-widget"></table>');
                        var clonedElm = elm.clone();
                        var tds = elm.find('td');
                        var clonedTds = clonedElm.find('td');

                        //adjust width for each cell
                        for (var i = 0; i < tds.length; i++) {
                            $(clonedTds[i]).width($(tds[i]).width());
                        }

                        clonedElm.addClass('k-state-selected');

                        table.append(clonedElm);
                        table.width(elm.width());

                        return table;
                    },
                    start: function() {
                        $('body').addClass('dragging');
                    },
                    end: function() {
                        $('body').removeClass('dragging');
                    },
                    change: function(e) {
                        var data = gridOptions.dataSource.data();
                        var source = data[e.oldIndex];
                        var target = data[e.newIndex];

                        preventUpdate(grid, function() {
                            grid.dataSource.remove(source);
                            grid.dataSource.insert(e.newIndex, source);
                        });

                        if (gridOptions.onDropCompleted) {
                            scope.$evalAsync(function() {
                                gridOptions.onDropCompleted({
                                    source: source,
                                    target: target,
                                    insertBefore: e.newIndex < e.oldIndex,
                                    evt: e
                                });
                            });
                        }
                    }
                });
            }

            //fix style for bulk menu header
            widget.element.find('.k-grid-header th.k-header > bulk-actions-menu, .k-grid-header th.k-header > *[data-bulk-actions-menu]').each(function() {
                $(this).parent('th').css('overflow', 'visible');
            });

            widget.element.find('.k-grid-header > .k-grid-header-locked').each(function() {
                $(this).css('overflow', 'visible');
            });


            gridOptions.onGridCreated();
        });

        return gridOptions;
    }

    function initSearch(gridOptions) {
        var runSearch = function(args) {
            args = args || {};

            if (!args.preventPageReset) {
                gridOptions.$resetPage();
            }

            if (gridOptions.filterOptions.keepFiltersAfterRead) {
                columnFilterHelper.resetFilterSourceOnly(gridOptions);
            } else {
                columnFilterHelper.reset(gridOptions);
            }

            return gridOptions.$read();
        };

        if (gridOptions.debounce != null) {
            return _.debounce(runSearch, gridOptions.debounce);
        } else {
            return runSearch;
        }
    }

    function setLoadingState(id, state) {
        $('#' + id)
            .removeClass('ip-data-initial')
            .removeClass('ip-data-pending')
            .removeClass('ip-data-loading')
            .removeClass('ip-data-loaded')
            .addClass(state);
    }

    function buildAltRowTemplate(gridOptions, useWidgetColumns) {
        var template = buildRowTemplate(gridOptions, useWidgetColumns);
        return template.replace('k-master-row', 'k-master-row k-alt');
    }

    function buildRowTemplate(gridOptions, useWidgetColumns) {
        var template = '<tr class="k-master-row" role="row"';
        if (gridOptions.rowAttributes) {
            if (typeof gridOptions.rowAttributes === 'string') {
                template += ' ' + gridOptions.rowAttributes;
            } else {
                throw "rowAttributes must be a string if autoGenerateRowTemplate=true"
            }
        }

        template += '>';

        if (gridOptions.detailTemplate) {
            if (gridOptions.showExpandIfCondition) {
                template += '<td class="k-hierarchy-cell"><a ng-if="' + gridOptions.showExpandIfCondition + '" class="k-icon k-i-expand no-underline" href="javascript:void(0)" aria-label="{{:: \'collapseExpand\' | translate}}" tabindex="-1"></a></td>';
            } else {
                template += '<td class="k-hierarchy-cell"><a class="k-icon k-i-expand" href="javascript:void(0)" aria-label="{{:: \'collapseExpand\' | translate}}" tabindex="-1"></a></td>';
            }
        }

        var buildColumn = function(col) {
            template += '<td role="gridCell"';
            if (col.hidden) {
                template += ' style="display:none"';
            }
            if (col.wrapText) {
                template += ' style="word-break:break-all"';
            }
            template += '>';
            if (col.template) {
                template += col.template;
            } else {
                template += (gridOptions.oneTimeBinding === true) ? '{{::dataItem.' : '{{dataItem.';
                template += col.field;
                template += '}}';
            }

            template += '</td>';
        };

        if (useWidgetColumns === true && gridOptions.$widget) {
            gridOptions.$widget.columns.forEach(function(col) {
                if (_.isArray(col.columns)) {
                    col.columns.forEach(buildColumn);
                } else {
                    buildColumn(col);
                }
            });
        } else {
            gridOptions.columns.forEach(function(col) {
                if (_.isArray(col.columns)) {
                    col.columns.forEach(buildColumn);
                } else {
                    buildColumn(col);
                }
            });
        }

        template += '</tr>';
        return template;
    }

    function addExpandRowIcon(id) {
        $('#' + id + ' .k-hierarchy-cell a' + ', ' + '#' + id + ' .k-hierarchy-cell a').addClass('k-i-expand no-underline');
    }

    function expandCollapseAll(id) {
        var grid = $("#" + id).data("kendoGrid");
        if (!_.any(grid.dataSource.data())) {
            return;
        }
        toggleExpandCollapse(grid);
    }

    function toggleExpandCollapse(grid) {
        var expandCollapseAll = $("#expandCollapseAll");
        var expanded = expandCollapseAll.hasClass("k-i-expand") && grid !== undefined;

        expandCollapseAll.removeClass(expanded ? "k-i-expand" : "k-i-collapse").addClass(expanded ? "k-i-collapse" : "k-i-expand");
        if (grid != undefined) {
            if (!expanded) {
                grid.collapseRow(grid.tbody.find(' > tr.k-master-row'));
            } else {
                grid.expandRow(grid.tbody.find("tr.k-master-row"));
            }
        }
    }

    function addRowClickHandler(id) {
        $('#' + id).on('click', 'tr', function(e) {
            var $target = $(e.target);

            if ($target.hasClass('expand-btn-header')) {
                expandAll(id);
                e.stopPropagation();
            }
            if ($target.hasClass('expand-btn')) {
                var $this = $(this);
                var $link = $this.find('td.k-hierarchy-cell .k-icon');
                $link.click();
                $this.next('.k-detail-row').find('.k-hierarchy-cell').addClass('hidden');

                var expandBtnWithError = $this.find('.expand-btn.error');
                if (expandBtnWithError.length > 0 && !$this.hasClass('error')) {
                    $this.addClass('error');
                }
            }
        });
    }

    function expandAll(gridId) {
        $('#' + gridId).find('td button .expand-btn').each(function() {
            $(this).click();
            unselectRow($(this).closest('tr'));
        });
    }

    function unselectRow(elem) {
        elem.removeClass('k-state-selected');
    }

    function hideExpandsIconColumn(id, colCount) {
        var index = colCount - 1;
        $('#' + id + ' .k-hierarchy-cell').each(function() {
            $(this).insertAfter($(this).siblings().eq(index));
            $(this).addClass('hidden');
            $(this).click(function(e) {
                if ($(this).parent().find('.expand-btn').length == 0) {
                    e.stopImmediatePropagation();
                }
                initiateEnterDownOnActiveCell(id);
            });
        });

        $('#' + id + ' .k-hierarchy-col').each(function() {
            $(this).insertAfter($(this).siblings().eq(index));
            $(this).addClass('hidden');
        });
    }

    function initiateEnterDownOnActiveCell(id) {
        var ev = jQuery.Event("keydown");
        ev.which = 13;
        ev.keyCode = 13;
        ev.target = $('#' + id + '_active_cell');
        $('#' + id).trigger(ev);
    }

    function initiateScorllUpDownOnGrid(id, gridOptions) {
        var rowId = id + '_active_cell';
        var activeRow = gridOptions.$widget.element.find("td[id='" + rowId + "']");
        if (activeRow.length > 0) activeRow[0].scrollIntoView(false);

    }

    function setPagerTooltips(scope, pager) {
        if (pager) {
            pager.element.find('a.k-link[title]').each(function() {
                var el = $(this);
                el.attr('ip-tooltip', '{{:: "' + el.attr('title') + '" | translate }}');
                el.removeAttr('title');
                $compile(el)(scope);
            });
        }
    }

    function preventUpdate(grid, fn) {
        var handler = function(e) {
            e.preventDefault();
        };

        grid.bind('dataBinding', handler);

        fn();

        grid.unbind('dataBinding', handler);
    }

    function raiseDataCountEvent(scope, gridOptions, total) {
        if (gridOptions.topicItemNumberKey) {
            gridOptions.topicItemNumberKey.total = total > 0 ? total : null;
            var data = angular.extend({
                total: total > 0 ? total : null
            }, gridOptions.topicItemNumberKey);
            scope.$emit('topicItemNumbers', data);
            var tabItem = $('.topics.ipx-topics>.topic-menu .tab-content li[data-topic-ref="' + data.key + '"] #topicDataCount');
            if (tabItem && tabItem.length > 0) {
                tabItem[0].innerHTML = data.total ? data.total : '';
            }
            var headerItem = $('.topics.ipx-topics .topics-container div[data-topic-key="' + data.key + '"] #topicDataCount');
            if (headerItem && headerItem.length > 0) {
                headerItem[0].innerHTML = data.total ? data.total : '';
            }
        }
    }
});