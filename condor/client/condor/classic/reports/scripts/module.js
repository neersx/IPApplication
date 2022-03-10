angular.module('inprotech.financialReports', []).config(function($stateProvider) {
    $stateProvider
        .state('financialReports', {
            url: '/reports',
            templateUrl: 'condor/classic/reports/financial-reports.html',
            controller: 'availableReportsController',       
            resolve: {
                viewInitialiser: function(http) {
                    return http.get('api/reports/availableReportsView').success(function(data) {
                        return data;
                    });
                }
            },
            data: {
                pageTitle: 'financialReports.pageTitle'
            }
        })
});