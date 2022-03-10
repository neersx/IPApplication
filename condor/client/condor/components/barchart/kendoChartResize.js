angular.module('inprotech.components.barchart').directive('kendoChartResize', function() {
    'use strict';

    return {
        restrict: 'A',
        link: function() {
            $(window).resize(function() {
                kendo.resize($("div.k-chart[data-role='chart']"));
            });
        }
    };
});
