angular.module('inprotech.components.page').directive('ipPageTitle', function() {
    'use strict';

    return {
        restrict: 'EA',
        transclude: {
            beforeTitle: '?beforeTitle',
            afterTitle: '?afterTitle',
            actionButtons: '?actionButtons'
        },
        scope: {
            pageTitle: '@',
            pageSubtitle: '@',
            pageSubtitleTranlslateValues: '@',
            pageDescription: '@'
        },
        templateUrl: 'condor/components/page/title/page-title.html'
    };
});