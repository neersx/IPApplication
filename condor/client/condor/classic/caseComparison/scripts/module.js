(function() {
    angular.module('Inprotech.CaseDataComparison', ['inprotech.components', 'Inprotech'])
        .config(function($stateProvider) {
            $stateProvider
                .state('inbox', {
                    url: '/casecomparison/inbox?:caselist&:ts&:se&:dataSource',
                    templateUrl: 'condor/classic/caseComparison/inbox.html',
                    controller: 'inboxController',
                    params: {
                        restore: {
                            value: false
                        },
                        se: {
                            value: null
                        },
                        dataSource: {
                            value: null
                        }
                    },
                    resolve: {
                        viewInitialiser: function(http, url) {
                            return http.get(url.api('CaseComparison/inboxView')).success(function(data) {
                                return data;
                            });
                        }
                    },
                    data: {
                        pageTitle: 'caseComparison.pageTitle'
                    }
                })
                .state('duplicates', {
                    url: '/duplicates/:dataSource/:forId',
                    templateUrl: 'condor/classic/caseComparison/duplicate-view.html',
                    controller: 'duplicatesController',
                    resolve: {
                        viewInitialiser: function(http, $stateParams, url) {
                            return http.get(url.api('CaseComparison/duplicatesView/' + $stateParams.dataSource + '/' + $stateParams.forId)).success(function(data) {
                                return data;
                            });
                        }
                    },
                    data: {
                        pageTitle: 'caseComparison.pageTitle'
                    }
                })
        });
    angular.module('Inprotech.CaseDataComparison')
        .run(function(modalService) {
            modalService.register('ImportDocument', 'importDocumentController', 'condor/classic/caseComparison/import-document.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
            modalService.register('GoodsServicesComparison', 'goodsServicesComparisonPopupController', 'condor/classic/caseComparison/goods-services-comparison-popup.html', {
                windowClass: 'centered picklist-window',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
            modalService.register('ComparisonErrorDetails', 'comparisonErrorDetailsController', 'condor/classic/caseComparison/error-details.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
            modalService.register('ImageView', 'caseImageViewController', 'condor/classic/caseComparison/case-image-view.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                backdrop: 'static',
                size: 'lg'
            });
        });
})();