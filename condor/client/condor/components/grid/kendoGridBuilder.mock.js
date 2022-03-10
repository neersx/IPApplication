angular.module('inprotech.mocks.components.grid').factory('kendoGridBuilderMock', function() {
    'use strict';

    var r = {
        buildOptions: function(scope, options) {
            var data = function() {
                return [];
            };
            var r2 = {
                search: function() {
                    return {
                        then: function(cb) {
                            cb();
                        }
                    };
                },
                select: function() {
                    return 'selected';
                },
                dataItem: function() {
                    return 'dataItem';
                },
                data: data,
                dataSource: {
                    data: data,
                    pageSize: function() {
                        return;
                    }
                },
                clear: function() {
                    return;
                },
                $read: function() {
                    return;
                },
                getCurrentFilters: function() {
                    return;
                },
                insertRow: function() {
                    return;
                },
                getRelativeItemAbove: function() {
                    return;
                },
                selectRowByIndex: function() {
                    return;
                },
                $widget: {
                    refresh: function() {
                        return;
                    }
                }
            };

            spyOn(r2, 'search').and.callThrough();
            spyOn(r2, 'clear').and.callThrough();
            spyOn(r2, '$read').and.callThrough();
            spyOn(r2, 'insertRow').and.callThrough();

            angular.extend(r2, options);

            return r2;
        }
    };

    spyOn(r, 'buildOptions').and.callThrough();

    return r;
});