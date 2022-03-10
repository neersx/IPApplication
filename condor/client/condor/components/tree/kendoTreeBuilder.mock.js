angular.module('inprotech.mocks.components.tree').factory('kendoTreeBuilderMock', function() {
    'use strict';

    var r = {
        buildOptions: function(scope, options) {
            var r2 = {
                $widget: {
                    dataSource: {
                        data: jasmine.createSpy()
                    }
                },
                showLoading: jasmine.createSpy(),
                hideLoading: jasmine.createSpy(),
                scrollToSelected: jasmine.createSpy()
            };

            angular.extend(r2, options);

            return r2;
        }
    };

    spyOn(r, 'buildOptions').and.callThrough();

    return r;
});