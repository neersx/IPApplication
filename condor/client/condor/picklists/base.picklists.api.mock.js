angular.module('inprotech.mocks')
    .factory('BasePicklistApiMock',
    function () {
        'use strict';

        var someColumns = [{
            field: 'key',
            key: true,
            description: true
        }];

        var someMaintainability = {
            canAdd: false,
            canEdit: false,
            canDelete: false
        };

        var someApiMockSearchReturn = {
            $then: function (fn) {
                fn({
                    somes: [],
                    $metadata: {
                        columns: someColumns,
                        maintainability: someMaintainability
                    }
                });
            },
            $asPromise: function () {
                return {
                    then: function (fn) {
                        return fn({
                            $encode: function () {
                                return [{
                                    data: 'data'
                                }];
                            },
                            $metadata: {
                                pagination: {}
                            }
                        });
                    }
                };
            }
        };

        var SomeApiMock = {
            resolve: function () {
                return this;
            },
            $search: function () {
                return someApiMockSearchReturn;
            },
            $find: function () {
                return {
                    $then: function (fn) {
                        fn({});
                    }
                };
            },
            $build: function () {
                return {};
            },
            $duplicate: function () {
                return {};
            },
            init: function (cb) {
                cb({
                    columns: someColumns,
                    maintainability: someMaintainability
                });
            }
        };

        spyOn(SomeApiMock, '$search').and.callThrough();
        spyOn(someApiMockSearchReturn, '$then').and.callThrough();
        spyOn(someApiMockSearchReturn, '$asPromise').and.callThrough();
        spyOn(SomeApiMock, '$find').and.callThrough();
        spyOn(SomeApiMock, '$build').and.callThrough();

        return SomeApiMock;
    });
