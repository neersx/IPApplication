angular.module('Inprotech.Integration.ExternalApplication', ['Inprotech']).config(function($stateProvider) {
    $stateProvider
        .state('externalApplication', {
            url: '/integration/externalapplication',
            templateUrl: 'condor/classic/integration/externalApplication/external-application-token.html',
            controller: 'externalApplicationTokenController',
            controllerAs: 'vm',
            resolve: {
                viewInitialiser: function(http) {
                    return http.get('api/externalApplication/externalApplicationTokenView').success(function(data) {
                        return data;
                    });
                }
            },
            data: {
                pageTitle: 'externalApplication.pageTitle'
            }
        })
});

angular.module('Inprotech.Integration.ExternalApplication')
.run(function(modalService) {
    modalService.register('ExternalApplicationEdit', 'externalApplicationTokenEditController', 'condor/classic/integration/externalApplication/external-application-token-edit.html', {
        windowClass: 'centered picklist-window',
        backdropClass: 'centered',
        backdrop: 'static',
        size: 'lg'
    });
});