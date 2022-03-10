angular.module('inprotech.deve2e').controller('GridTestController', function ($scope, kendoGridBuilder, BulkMenuOperations, $q, $timeout) {
    'use strict';
    var vm = this;
    var bulkMenuOperations;
    vm.$onInit = onInit;

    function onInit() {

        vm.menu = buildMenu();
        vm.gridOptions = buildGridOptions();

        bulkMenuOperations = new BulkMenuOperations(vm.menu.context);

        vm.actionClicked = false;
        vm.selectedItems = 'Nothing to see here';
    }

    function buildGridOptions() {
        var columns = [
            {
                headerTemplate: '<bulk-actions-menu data-context="pagableGridTest" data-is-full-selection-possible="false" data-actions="vm.menu.items" data-on-select-this-page="vm.menu.selectPage(val)" data-on-clear="vm.menu.clearAll()" data-initialised="vm.menuInitialised()">',
                template: '<ip-checkbox ng-model="dataItem.selected" ng-change="vm.menu.selectionChange(dataItem)">',
                width: '35px',
                fixed: true,
                locked: true
            }, {
                title: 'id',
                field: 'id',
                template: '{{::dataItem.id}}',
                oneTimeBinding: true
            }, {
                title: 'description',
                field: 'description',
                template: '{{::dataItem.description}}',
                oneTimeBinding: true
            }, {
                title: 'code',
                field: 'code',
                template: '{{::dataItem.code}}',
                oneTimeBinding: true
            }];

        return kendoGridBuilder.buildOptions($scope, {
            id: 'pagableGridTest',
            autoBind: true,
            pageable: {
                pageSize: 10,
                pageSizes: [5, 10, 15, 20]
            },
            sortable: false,
            autoGenerateRowTemplate: true,
            read: function (queryParams) {
                var data = getFakeData(queryParams);
                return $q(function (resolve) {
                    resolve({
                        data: data,
                        total: gridData.length
                    });
                    $timeout(function () {
                        $scope.$apply();
                    });
                });
            },
            onDataCreated: function () {
                $timeout(function () {
                    bulkMenuOperations.selectionChange(vm.gridOptions.data());
                }, 100);
            },
            columns: columns
        });
    }

    function clickAction() {
        vm.selectedItems = _.pluck(bulkMenuOperations.selectedRecords(), 'id');
    }

    function buildMenu() {
        return {
            context: 'pagableGridTest',
            items: [{
                id: 'action',
                text: 'Action',
                enabled: function () {
                    return bulkMenuOperations.anySelected(vm.gridOptions.data());
                },
                click: clickAction
            }],
            clearAll: function () {
                return bulkMenuOperations.clearAll(vm.gridOptions.data());
            },
            selectPage: function (val) {
                return bulkMenuOperations.selectPage(vm.gridOptions.data(), val);
            },
            selectionChange: selectionChange
        };
    }

    function getFakeData(queryParams) {
        return gridData.slice(queryParams.skip, queryParams.skip + queryParams.take);
    }

    vm.menuInitialised = function () {
        bulkMenuOperations.initialiseMenuForPaging(vm.gridOptions.pageable.pageSize);
    };

    function selectionChange(dataItem) {
        return bulkMenuOperations.singleSelectionChange(vm.gridOptions.data(), dataItem);
    }

    var gridData = [{
        id: 0,
        description: 'aaa',
        code: 'a'
    }, {
        id: 1,
        description: 'bbb',
        code: 'b'
    }, {
        id: 2,
        description: 'ccc',
        code: 'c'
    }, {
        id: 3,
        description: 'ddd',
        code: 'd'
    }, {
        id: 4,
        description: 'eee',
        code: 'e'
    }, {
        id: 5,
        description: 'fff',
        code: 'f'
    }, {
        id: 6,
        description: 'ggg',
        code: 'g'
    }, {
        id: 7,
        description: 'hhh',
        code: 'h'
    }, {
        id: 8,
        description: 'iii',
        code: 'i'
    }, {
        id: 9,
        description: 'jjj',
        code: 'j'
    }, {
        id: 10,
        description: 'kkk',
        code: 'k'
    }, {
        id: 11,
        description: 'lll',
        code: 'l'
    }, {
        id: 12,
        description: 'mmmm',
        code: 'm'
    }, {
        id: 13,
        description: 'nnn',
        code: 'n'
    }, {
        id: 14,
        description: 'ooo',
        code: 'o'
    }];
});