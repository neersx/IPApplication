describe('inprotech.components.grid.columnFilterHelper', function () {
    'use strict';

    var helper;
    beforeEach(module('inprotech.components.grid'));

    beforeEach(inject(function (columnFilterHelper) {
        helper = columnFilterHelper;
    }));

    describe('buildQueryParams', function () {
        var gridOptions;
        beforeEach(function () {
            gridOptions = {
                filterable: true,
                serverFiltering: true,
                $getAllColumnFilterValues: function () {
                    return ['AU', 'UK', 'US', 'CN', 'JP'];
                },
                getFiltersCustom: function () {
                    return [];
                },
                filterOptions: {
                    sendExplicitValues: false
                },
                dataSource: {
                    _filter: []
                },
                columns: [
                    {
                        title: 'defaultFilters',
                        field: 'default',
                        filterable: true,
                        defaultFilters: ['AU']
                    }
                ]
            };
        });
        it('should build params using "in" operator if selected items are less than half of total options', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }, {
                    field: 'country',
                    value: 'UK'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function () {
                return ['AU', 'UK', 'US', 'CN', 'JP'];
            };

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'country',
                    operator: 'in',
                    value: 'AU,UK'
                }]
            });
        });

        it('should build params using "not in" operator if selected items are greater than half of total options', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }, {
                    field: 'country',
                    value: 'UK'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function () {
                return ['AU', 'UK', 'US'];
            };

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'country',
                    operator: 'notIn',
                    value: 'US'
                }]
            });
        });

        it('should build params using "in" operator, even if selected items are greater than half of total options, if sendExplicitValues is set', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }, {
                    field: 'country',
                    value: 'UK'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function () {
                return ['AU', 'UK', 'US'];
            };
            gridOptions.filterOptions.sendExplicitValues = true;

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'country',
                    operator: 'in',
                    value: 'AU,UK'
                }]
            });
        });

        it('should build params for custom filters in the same way they are made available', function () {
            var filter = {
                filters: [{
                    field: 'startDateTime',
                    value: '2001-01-01',
                    operator: 'gt',
                    type: 'date'
                }]
            };

            gridOptions.getFiltersCustom = function () {
                return [{
                    field: 'startDateTime',
                    filterable: {
                        type: 'date'
                    }
                }];
            };

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'startDateTime',
                    operator: 'gt',
                    value: '2001-01-01',
                    type: 'date'
                }]
            });
        });

        it('should support multiple columns', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }, {
                    field: 'propertyType',
                    value: 'A'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function (field) {
                if (field === 'country') {
                    return ['AU', 'UK', 'US'];
                } else if (field === 'propertyType') {
                    return ['A', '~'];
                }
            };

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'country',
                    operator: 'in',
                    value: 'AU'
                }, {
                    field: 'propertyType',
                    operator: 'in',
                    value: 'A'
                }]
            });
            expect(gridOptions.filterOptions.filters).toEqual([{
                field: 'country',
                value: 'AU',
                operator: 'in'
            }, {
                field: 'propertyType',
                value: 'A',
                operator: 'in'
            }]);
        });

        it('should ignore filter if select all', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function () {
                return ['AU'];
            };

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: []
            });
        });

        it('should send all records in filter if sendExplicitValues flag is set', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }]
            };

            gridOptions.$getAllColumnFilterValues = function () {
                return ['AU'];
            };
            gridOptions.filterOptions.sendExplicitValues = true;

            var result = helper.buildQueryParams(filter, gridOptions);

            expect(result).toEqual({
                filters: [{
                    field: 'country',
                    operator: 'in',
                    value: 'AU'
                }]
            });
            expect(gridOptions.filterOptions.filters).toEqual([{
                field: 'country',
                value: 'AU',
                operator: 'in'
            }]);
        });

        it('should append getFiltersExcept method to gridOptions', function () {
            helper.init(gridOptions);
            expect(gridOptions.getFiltersExcept).toBeDefined();

            expect(gridOptions.dataSource._filter).toEqual([{ field: 'default', operator: 'eq', value: 'AU' }]);

            gridOptions.filterOptions.filters = [{
                field: 'a'
            }, {
                field: 'b'
            }, {
                field: 'c'
            }];

            var result = gridOptions.getFiltersExcept({
                field: 'b'
            });
            expect(result.length).toBe(2);
            expect(result).not.toContain({
                field: 'b'
            });
        });

        it('should mark all filters for refresh after filtering', function () {
            var filter = {
                filters: [{
                    field: 'country',
                    value: 'AU'
                }, {
                    field: 'propertyType',
                    value: 'X'
                }]
            };
            gridOptions.columns = [{
                field: 'country',
                filterable: {
                    $initialised: true,
                    $refreshDataSource: null
                }
            }, {
                field: 'action',
                filterable: {
                    $initialised: true,
                    $refreshDataSource: null
                }
            }, {
                field: 'propertyType',
                filterable: {
                    $initialised: true,
                    $refreshDataSource: null
                }
            }];

            helper.buildQueryParams(filter, gridOptions);

            expect(gridOptions.columns[0].filterable.$refreshDataSource).toBe(true);
            expect(gridOptions.columns[1].filterable.$refreshDataSource).toBe(true);
            expect(gridOptions.columns[2].filterable.$refreshDataSource).toBe(true);
        });
    });
});
