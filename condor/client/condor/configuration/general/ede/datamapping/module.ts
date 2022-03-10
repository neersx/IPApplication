angular.module('inprotech.configuration.general.ede.datamapping', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components'
]);

angular.module('inprotech.configuration.general.ede.datamapping')
    .run((modalService) => {
        modalService.register('DataMappingMaintenance', 'DataMappingMaintenanceController', 'condor/configuration/general/ede/datamapping/datamapping.maintenance.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('inprotech.configuration.general.ede.datamapping').config(($stateProvider) => {
    $stateProvider.state('datamapping', {
        url: '/configuration/general/ede/datamapping/{name}',
        templateUrl: 'condor/configuration/general/ede/datamapping/datamappingtopics.html',
        controller: 'DataMappingTopicsController',
        controllerAs: 'vm',
        resolve: {
            viewData: ($http, $stateParams) => {
                return $http.get('api/configuration/ede/datamapping/datasource/' + encodeURIComponent($stateParams.name)).then((response) => {
                    return response.data;
                });
            }
        },
        data: {
            pageTitle: 'dataMapping.pageTitle'
        }
    });
});