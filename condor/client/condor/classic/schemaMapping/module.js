angular.module('Inprotech.SchemaMapping', [
    'inprotech.core',
    'inprotech.api',
    'inprotech.components',
    'Inprotech'
]);

angular.module('Inprotech.SchemaMapping')
    .run(function(modalService) {
        modalService.register('SchemaMappingEditor', 'SchemaEditorController', 'condor/classic/schemaMapping/lists/schema-editor.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'xl'
        });

        modalService.register('AddMapping', 'AddMappingController', 'condor/classic/schemaMapping/lists/add-mapping.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            backdrop: 'static',
            size: 'lg'
        });
    });

angular.module('Inprotech.SchemaMapping')
    .config(['$stateProvider', function($stateProvider) {
        $stateProvider.state('schemamapping', {
                url: "/schemamapping",
                abstract: true,
                template: '<ui-view/>'
            })
            .state('schemamapping.list', {
                url: '/list',
                templateUrl: 'condor/classic/schemaMapping/lists/upload.html',
                controller: 'uploadController',
                controllerAs: 'vm',
                data: {
                    pageTitle: 'schemaMapping.usLblTitle'
                }
            })
            .state('schemamapping.mapping', {
                url: '/mapping/:id',
                templateUrl: 'condor/classic/schemaMapping/mapping/mapping.html',
                controller: 'mappingController',
                cache: false,
                resolve: {
                    viewInitialiser: function(http, url, $stateParams) {
                        return http.get(url.api('schemamappings/mappingView/' + $stateParams.id));
                    }
                }
            })
            .state('schemamapping.xml', {
                url: '/:id/xml',
                templateUrl: 'condor/classic/schemaMapping/xmlgeneration/generateXml.html',
                controller: 'xmlController',
                controllerAs: 'vm',
                resolve: {
                    viewInitialiser: function(http, url, $stateParams) {
                        return http.get(url.api('schemamappings/xmlview/' + $stateParams.id));
                    }
                }
            });
    }]);