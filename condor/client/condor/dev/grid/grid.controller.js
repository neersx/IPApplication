angular.module('inprotech.dev').controller('GridController', function($scope, kendoGridBuilder, $http) {
    'use strict';

    var vm = this;
    vm.addCount = 0;

    vm.search = function(queryParams) {
        return $http.get('/api/dev/grid/results', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            })
            .then(function(response) {
                return response.data;
            });
    };

    vm.getFilterDataForColumn = function(column) {
        return $http.get('/api/dev/grid/filtermetadata/' + column.field)
            .then(function(response) {
                return response.data;
            });
    };

    vm.addGridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'add-grid',
        autoBind: true,
        read: function() {
            return $http.get('/api/dev/grid/results').then(function(response) {
                return response.data;
            });
        },
        columns: [{
            fixed: true,
            width: '35px',
            template: '<ip-inheritance-icon ></ip-inheritance-icon>'
        }, {
            title: 'Case Type',
            field: 'caseType',
            template: function(dataItem) {
                return fieldTemplate(dataItem.caseType);
            },
            filterable: true
        }, {
            title: 'Jurisdiction',
            field: 'jurisdiction',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.jurisdiction);
            }
        }, {
            title: 'propertyType',
            field: 'propertyType',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.propertyType);
            }
        }]
    });

    vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'the-grid',
        autoBind: true,
        pageable: {
            pageSize: 5,
            pageSizes: [5, 10]
        },
        read: function(queryParams) {
            return vm.search(queryParams);
        },
        readFilterMetadata: function(queryParams, column) {
            return vm.getFilterDataForColumn(queryParams, column);
        },
        filterable: true,
        serverFiltering: true,
        columns: [{
            title: 'Case Type',
            field: 'caseType',
            template: function(dataItem) {
                return fieldTemplate(dataItem.caseType);
            },
            filterable: true
        }, {
            title: 'Jurisdiction',
            field: 'jurisdiction',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.jurisdiction);
            }
        }, {
            title: 'propertyType',
            field: 'propertyType',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.propertyType);
            }
        }]
    });

    vm.deleteGridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'the-delete-grid',
        autoBind: true,
        read: function() {
            return $http.get('api/configuration/sitecontrols').then(function(response) {
                return response.data.data.slice(0, 5);
            });
        },
        deletable: true,
        rowDraggable: true,
        detailTemplate: '<ip-dev-grid-detail>',
        columns: [{
            title: 'Name',
            template: '<a href="/"><span>{{dataItem.name}}</span></a>'
        }, {
            title: 'Description',
            field: 'description'
        }, {
            title: 'Release',
            field: 'release'
        }, {
            title: 'Components',
            field: 'components'
        }]
    });

    vm.onAdd = function() {
        vm.addCount++;
    };

    vm.save = function() {
        vm.deleteGridOptions.removeDeletedRows();
    };

    function fieldTemplate(field) {
        if (!field) {
            return '';
        }

        return '<span>' + (field.description || '') + '</span>';
    }

    vm.searchGridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'the-search-grid',
        pageable: true,
        scrollable: true,
        read: function(queryParams) {
            if (returnNothing) {
                return {
                    then: function(callback) {
                        return callback([]);
                    }
                };
            }

            return vm.search(queryParams);
        },
        readFilterMetadata: function(queryParams, column) {
            return vm.getFilterDataForColumn(queryParams, column);
        },
        filterable: true,
        serverFiltering: true,
        columns: [{
            title: 'Case Type',
            field: 'caseType',
            width: '200px',
            template: function(dataItem) {
                return fieldTemplate(dataItem.caseType);
            },
            filterable: true
        }, {
            title: 'Jurisdiction',
            field: 'jurisdiction',
            width: '150px',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.jurisdiction);
            }
        }, {
            title: 'propertyType',
            field: 'propertyType',
            width: '150px',
            filterable: true,
            template: function(dataItem) {
                return fieldTemplate(dataItem.propertyType);
            }
        }]
    });

    var returnNothing = false;
    vm.runSearch = function() {
        returnNothing = false;
        vm.searchGridOptions.search();
    };

    vm.resetSearch = function() {
        vm.searchGridOptions.clear();
    };

    vm.runSearchNoResults = function() {
        returnNothing = true;
        vm.searchGridOptions.search('something');
    };
}).directive('ipDevGridDetail', function() {
    'use strict';
    return {
        templateUrl: 'condor/configuration/general/sitecontrols/directives/detailView.html',
        controller: function($scope) {
            $scope.canUpdate = true
        }
    };
});
