angular.module('Inprotech', ['Inprotech.Infrastructure', 'Inprotech.Utilities', 'Inprotech.Localisation']);


var classic = angular.module('inprotech.classic', [
    'ui.router',
    'ui.router.upgrade',
    'Inprotech',
    'inprotech.financialReports',
    'Inprotech.BulkCaseImport',
    'Inprotech.Integration.PtoAccess',
    'Inprotech.CaseDataComparison',
    'Inprotech.Integration.ExternalApplication',
    'Inprotech.SchemaMapping'
]);

classic.config(function($httpProvider) {
    $httpProvider.interceptors.push('localisedResourcesInterceptor');
});