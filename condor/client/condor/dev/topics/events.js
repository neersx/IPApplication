angular.module('inprotech.dev').directive('ipDevTopicsEvents', function() {
    'use strict';

    return {
        restrict: 'AE',
        templateUrl: 'condor/dev/topics/events.html',
        scope: {},
        controller: 'ipDevTopicsEventsController',
        controllerAs: 'vm'
    };
}).controller('ipDevTopicsEventsController', function($scope, $http, kendoGridBuilder) {
    'use strict';

    var vm = this;
    vm.errors = {};

    vm.gridOptions = kendoGridBuilder.buildOptions($scope, {
        id: 'eventResults',
        autoBind: true,
        pageable: true,
        read: function(queryParams) {
            return vm.search(queryParams);
        },
        columns: [{
            title: 'Case Type',
            field: 'caseType',
            width: '200px',
            template: '<span>{{dataItem.caseType.description}}</span>'
        }, {
            title: 'Jurisdiction',
            field: 'jurisdiction',
            width: '150px',
            template: '<span>{{dataItem.jurisdiction.description}}</span>'
        }, {
            title: 'propertyType',
            field: 'propertyType',
            width: '150px',
            template: '<span>{{dataItem.propertyType.description}}</span>'
        }]
    });

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
});
