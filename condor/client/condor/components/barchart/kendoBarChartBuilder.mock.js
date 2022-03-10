angular.module('inprotech.mocks.components.barchart').factory('kendoBarChartBuilderMock', function() {
    'use strict';

    var r = {
        buildOptions: function(scope, options) {
            var r2 = {
                refreshData: function() {
                    return;
                }
            };

            spyOn(r2, 'refreshData').and.callThrough();
            angular.extend(r2, options);

            return {
                then: function() {
                    return r2;
                }
            };
        }
    };

    spyOn(r, 'buildOptions').and.callThrough();

    return r;
});
