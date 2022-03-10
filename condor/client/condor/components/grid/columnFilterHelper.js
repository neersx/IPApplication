angular.module('inprotech.components.grid').factory('columnFilterHelper', function ($rootScope, $compile) {
    'use strict';

    function getColumn(gridOptions, field) {
        return _.find(gridOptions.columns, function (c) {
            return c.field === field;
        });
    }

    function createCustomFilter(gridOptions, col, controlFn) {
        return {
            extra: false,
            ui: function (e) {
                var scope = $rootScope.$new();
                scope.column = col;
                gridOptions.$customFilterScopes.push(scope);
                var customControl = controlFn(scope);
                e.before(customControl).hide();
                scope.$apply();
            }
        };
    }

    function resetCustomFilterValue(column, gridOptions, field) {
        var c = column || getColumn(gridOptions, field);
        if (c.filter && c.filter.$clear) {
            c.filter.$clear();
            var filterColumn = $("th[data-field='" + c.field + "'] > a");
            if (filterColumn)
                filterColumn.removeClass('k-state-active');
        }
    }

    function addOrEditFilter(gridOptions, field, operator, value, type) {
        var all = gridOptions.dataSource.filter() || {
            filters: []
        };

        var filter = _.findWhere(all.filters, {
            field: field
        });

        if (!filter) {
            all.filters.push(filter = {
                field: field
            });
        }

        filter.operator = operator;
        filter.value = value;
        filter.type = type || null;
        gridOptions.dataSource._filter = all;
    }

    function removeFilter(gridOptions, field) {
        var all = gridOptions.dataSource.filter() || {
            filters: []
        };

        all.filters = _.reject(all.filters, function (item) {
            return item.field === field;
        });

        gridOptions.dataSource._filter = all;
    }

    function doCustomFilter(e, callback) {
        e.preventDefault();
        e.stopPropagation();

        callback(fieldFromEventTarget(e));

        /* KendoFilterMenu close, assumes e.target is the form element with k-popup */
        $(e.target).data('kendoPopup').close();
    }

    function fieldFromEventTarget(e) {
        return e.target.getAttribute('field');
    }

    return {
        init: function (gridOptions) {
            if (!gridOptions.filterable || !gridOptions.serverFiltering) {
                return gridOptions;
            }

            gridOptions.$customFilterScopes = [];

            gridOptions.$setCustomFilter = function (e) {
                doCustomFilter(e, function (field) {
                    var column = getColumn(gridOptions, field);
                    if (!column.filter.operator) {
                        return;
                    }

                    var formattedValue = (column.filter.$formattedValue || angular.noop)();
                    if (!formattedValue) {
                        return;
                    }

                    addOrEditFilter(gridOptions, field, column.filter.operator, formattedValue, column.filterable.type);
                    gridOptions.$read();
                });
            };

            gridOptions.$clearCustomFilter = function (e) {
                var field = fieldFromEventTarget(e);
                resetCustomFilterValue(null, gridOptions, field);
                removeFilter(gridOptions, field);
            };

            gridOptions.getFiltersExcept = function (except) {
                return _.filter(gridOptions.filterOptions.filters, function (f) {
                    return f.field !== except.field;
                });
            };

            gridOptions.getFiltersCustom = function () {
                return _.filter(gridOptions.columns, function (col) {
                    return col.filterable && _.has(col.filterable, 'type');
                });
            };

            gridOptions.filterMenuInit = function (e) {
                e.container.attr('id', gridOptions.$widget.wrapper.attr('id') + '_filter_' + e.field);

                e.container.find('.k-filter-help-text').hide();

                e.container.data('kendoPopup').bind('open', function () {
                    e.container.find('.k-textbox input').val('');
                    e.container.find('ul li').show();

                    var actionButtonsEl = e.container.find('.k-action-buttons');
                    actionButtonsEl.removeClass('k-action-buttons');

                    var col = getColumn(gridOptions, e.field);
                    if(gridOptions.filterable){
                        angular.element(document.querySelector('.main-content-scrollable')).on('scroll', function(){
                            var elems=document.querySelectorAll('.k-animation-container');
                            _.each(elems,function(el){
                                angular.element(el).css('display','none');
                            });
                          });
                    }
                    // if init first time
                    if (col.filterable.$initialised && col.filterable.$refreshDataSource) {
                        col.filterable.dataSource.read();
                    }
                    col.filterable.$refreshDataSource = false;
                    col.filterable.$initialised = true;

                    if (_.has(col.filterable, 'type')) {
                        /* existence of type indicates custom, currently includes 'date' */
                        col.filterable.dataSource = new kendo.data.DataSource();
                        e.container.attr('field', e.field);
                        e.container.find('[type="reset"]')
                            .attr('field', e.field)
                            .on('click', gridOptions.$clearCustomFilter);

                        /* stealing the kendo filter menu on-submit, we are going alone! */
                        e.container.off('submit');
                        e.container.on('submit', gridOptions.$setCustomFilter);
                    }

                    $rootScope.$broadcast('FilterPopUp', true);
                });

                e.container.data('kendoPopup').bind('close', function () {
                    e.container.find('[type="reset"]').off("click", gridOptions.$clearCustomFilter);
                    e.container.off('submit', gridOptions.$setCustomFilter);
                    $rootScope.$broadcast('FilterPopUp', false);
                });
            };

            gridOptions.columns = _.map(gridOptions.columns, function (col) {
                if (!col.filterable) {
                    return col;
                }
               
                var defaultFilter = {
                    multi: true,
                    search: true,
                    code: 'code',
                    description: 'description'
                };
                
                if (col.filterable && col.filterable.type === 'date') {
                    var datePickerFilter = createCustomFilter(gridOptions, col, function (scope) {
                        return $compile('<ip-kendo-column-filter-date-picker></ip-kendo-column-filter-date-picker>')(scope);
                    });
                    col.filterable = angular.extend(datePickerFilter, col.filterable);
                } else if (typeof filterable && col.filterable.type === 'text') {
                    var textFilter = createCustomFilter(gridOptions, col, function (scope) {
                        return $compile('<ip-kendo-column-filter-text-filter></ip-kendo-column-filter-text-filter>')(scope);
                    });
                    col.filterable = angular.extend(textFilter, col.filterable);
                } else if (typeof col.filterable === 'object') {
                    col.filterable = angular.extend(defaultFilter, col.filterable);
                } else {
                    col.filterable = defaultFilter;
                }

                if (!col.filterable.dataSource) {
                    var filterDataSourceOptions = {
                        transport: {
                            read: function (options) {
                                return gridOptions.readFilterMetadata(col).then(function (d) {
                                    options.success(new kendo.data.ObservableArray(d || []));
                                }).catch(function (error) {
                                    options.error(error);
                                });
                            }
                        }
                    };

                    col.filterable.dataSource = new kendo.data.DataSource(filterDataSourceOptions);

                    if (col.filterable.code && col.filterable.description) {
                        col.filterable.itemTemplate = function (e) {
                            return '#var filterValue = data["' + col.filterable.code + '"] || (data.all ? "all" : null);#' +
                                '#var id="_kendo_col_filter_val" + Math.random()#' +
                                '<li class="k-item">' +
                                '   <input type="checkbox" name="' + e.field + '" id="#=id#" value="#=filterValue#" />' +
                                '   <label for="#=id#">' +
                                '   #if(data["' + col.filterable.description + '"]) {#' +
                                '       #= $(\'<div/>\').text(data["' + col.filterable.description +'"]).html()#' +
                                '   #} else if(data.all) {#' +
                                '       #= data.all #' +
                                '   #} else {#' +
                                '       (empty) ' +
                                '   #}#' +
                                '   </label>' +
                                '</li>';
                        };
                    }
                }

                if (col.filterable && col.defaultFilters) {
                    if (!gridOptions.dataSource._filter) {
                        gridOptions.dataSource._filter = [];
                    }

                    gridOptions.dataSource._filter.push({
                        field: col.field,
                        operator: 'eq',
                        value: col.defaultFilters.join(',')
                    });
                }

                return col;
            });

            gridOptions.$getAllColumnFilterValues = function (field) {
                var column = _.find(gridOptions.columns, function (c) {
                    return c.field === field;
                });

                var all = _.pluck(column.filterable.dataSource.data(), 'code');

                all = _.map(all, function (c) {
                    return c || 'null';
                });

                return all;
            };


            return gridOptions;
        },
        resetFilterSourceOnly: function (gridOptions) {
            _.each(gridOptions.columns, function (col) {
                if (col.filterable && col.filterable.dataSource) {
                    col.filterable.$refreshDataSource = true;
                }
            });
        },
        reset: function (gridOptions) {
            if (!gridOptions.filterable) {
                return;
            }

            if (gridOptions.dataSource._filter && gridOptions.dataSource._filter.filters) {
                gridOptions.dataSource._filter.filters = [];
            }

            if (!gridOptions.serverFiltering) {
                return;
            }

            _.each(gridOptions.columns, function (col) {
                if (col.filterable && col.filterable.dataSource) {
                    col.filterable.dataSource.data([]);
                    col.filterable.$refreshDataSource = true;
                    resetCustomFilterValue(col);
                }
            });
        },
        buildQueryParams: function (filter, gridOptions) {
            var queryParams = {};

            if (filter) {

                var customFilters = _.map(gridOptions.getFiltersCustom(), function (c) {
                    return {
                        field: c.field,
                        type: c.filterable.type
                    };
                });

                var filterMap = mapFilter(filter, {});

                var newFilters = _.map(_.pairs(filterMap), function (f) {
                    var field = f[0];
                    var values = f[1].values;
                    var op = f[1].operator;

                    var custom = _.findWhere(customFilters, {
                        field: field
                    });

                    if (custom) {
                        return {
                            field: field,
                            value: values[0],
                            operator: op,
                            type: custom.type
                        }
                    }

                    if (angular.isDefined(gridOptions.filterOptions.sendExplicitValues) && gridOptions.filterOptions.sendExplicitValues) {
                        op = 'in';
                    } else {
                        var all = gridOptions.$getAllColumnFilterValues(field);

                        if (values.length === all.length) {
                            return null;
                        } else if (values.length > all.length / 2) {
                            values = _.difference(all, values);
                            op = 'notIn';
                        } else {
                            op = 'in';
                        }
                    }

                    return {
                        field: field,
                        value: values.join(','),
                        operator: op
                    };
                });

                queryParams.filters = _.without(newFilters, null);
                gridOptions.filterOptions.filters = queryParams.filters;
            } else {
                gridOptions.filterOptions.filters = [];
            }

            _.each(gridOptions.columns, function (c) {
                if (c.filterable.$initialised) {
                    c.filterable.$refreshDataSource = true;
                }
            });

            return queryParams;
        }
    };

    function mapFilter(f, map) {
        if (!f.filters) {
            if (!map[f.field]) {
                map[f.field] = {
                    values: []
                };
            }

            map[f.field].operator = f.operator || map[f.field].operator;
            map[f.field].values.push(f.value);

            return map;
        }

        _.each(f.filters, function (subFilter) {
            mapFilter(subFilter, map);
        });

        return map;
    }
});