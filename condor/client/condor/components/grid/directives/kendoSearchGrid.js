angular.module('inprotech.components.grid').directive('ipKendoSearchGrid', function ($compile, ipKendoGridKeyboardShortcuts) {
    'use strict';

    return {
        restrict: 'E',
        scope: {
            //gridOptions: expression
            id: '@',
            searchHint: '@',
            noResultsHint: '@'
        },
        templateUrl: 'condor/components/grid/directives/kendoSearchGrid.html',
        link: function (scope, element, attrs) {

            angular.element(".main-content-scrollable").scroll(function () {
                angular.element(document.body).find("[data-role=popup]")
                    .kendoPopup("close");
            });

            scope.hideSearchHint = false;
            scope.hideNoResults = true;

            var gridOptions = scope.$parent.$eval(attrs.gridOptions);
            gridOptions.hidePagerWhenNoResults = true;
            gridOptions.onDataBound = function (d, didSearch) {
                if (d.length === 0) {
                    scope.hideSearchHint = didSearch;
                    scope.hideNoResults = !didSearch;
                } else {
                    scope.hideSearchHint = true;
                    scope.hideNoResults = true;
                }

                var lockedElements = element.find('.k-grid-content-locked tr');
                if (lockedElements.length > 0) {
                    element.find('.k-grid-content tr').each(function (index, ele) {
                        lockedElements.eq(index).height($(ele).height());
                    });
                }
            };

            ipKendoGridKeyboardShortcuts.bindShortcuts(scope.id, element, gridOptions);
            // compile the grid in the parent's scope to prevent grid binding issues
            var grid = $('<kendo-grid id="' + scope.id + '" k-options="' + attrs.gridOptions + '"></kendo-grid>');
            element.find('.kendo-search-grid-placeholder').append(grid);
            $compile(grid)(scope.$parent);

            scope.$on('$destroy', function () {
                if (gridOptions.$destroy) {
                    gridOptions.$destroy();
                }
            });
        }
    };
});