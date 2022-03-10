angular.module('inprotech.components.grid')
    .directive('ipKendoColumnFilterDatePicker', function() {
        'use strict';

        function hideDefaultListbox(filterMenu) {
            var listbox = $(filterMenu)
                .find('[role=listbox]');

            $('span', listbox).hide();
            listbox.unbind().hide();
        }

        function reconfigureFilterMenu(scope, filterMenu) {
            scope.$on('FilterPopUp', function(event, val) {
                if (!val || scope !== event.currentScope) {
                    return;
                }

                hideDefaultListbox(filterMenu);
            });
        }

        return {
            restrict: 'E',
            templateUrl: 'condor/components/grid/directives/kendoColumnFilterDatePicker.html',
            link: function(scope, element) {

                var col = scope.column;
                var filter = (col.filter = col.filter || {});

                var filterMenu = $(element)
                    .parentsUntil('form.k-filter-menu')
                    .parent();

                filterMenu.find('[role=listbox]')
                    .unbind()
                    .hide();

                reconfigureFilterMenu(scope, filterMenu);

                filter.$formattedValue = function() {
                    if (!filter.date) {
                        return null;
                    }
                    
                    return moment(filter.date).format('YYYY-MM-DD');
                }

                filter.$clear = function() {
                    filter.operator = "gte";
                    filter.date = null;
                }

                filter.operator = "gte";
            }
        }
    });
