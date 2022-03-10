angular.module('inprotech.components.grid').factory('ipKendoGridKeyboardShortcuts', function() {
    var bindShortcuts = function(elementId, element, gridOptions) {

        element.on('setFocus', function() {
            var grid = $('#' + elementId).data('kendoGrid');
            if (grid.dataSource.total() > 0) {
                var cell = grid.tbody.find('tr:first td:first');
                grid.current(cell);
                grid.table.focus();
                var tableHeader = grid.table.closest('ip-kendo-grid, ip-kendo-search-grid').prev('.table-container');
                if (tableHeader.length > 0) {
                    var stickyHeader = $('ip-sticky-header:visible');
                    document.body.scrollTop = tableHeader.offset().top - stickyHeader.height();
                }
            }
        });

        element.on('nextPage', function() {
            var currentPage = gridOptions.dataSource.page();
            if (currentPage < gridOptions.dataSource.totalPages()) {
                hijackDataBoundEvent(gridOptions);
                gridOptions.dataSource.page(currentPage + 1);
            }
        });

        element.on('previousPage', function() {
            var currentPage = gridOptions.dataSource.page();
            if (currentPage > 1) {
                hijackDataBoundEvent(gridOptions);
                gridOptions.dataSource.page(currentPage - 1);
            }
        });

        element.on('firstPage', function() {
            var currentPage = gridOptions.dataSource.page();
            if (currentPage > 1) {
                hijackDataBoundEvent(gridOptions);
                gridOptions.dataSource.page(1);
            }
        });

        element.on('lastPage', function() {
            var currentPage = gridOptions.dataSource.page();
            if (currentPage < gridOptions.dataSource.totalPages()) {
                hijackDataBoundEvent(gridOptions);
                gridOptions.dataSource.page(gridOptions.dataSource.totalPages());
            }
        });

        element.on('select', function() {
            if (gridOptions.onSelect && !gridOptions.onSelect.disabled) {
                gridOptions.onSelect();
            }
        });

        element.bind('keydown', function($event) {
            var triggerEvent;
            switch ($event.keyCode) {
                case 35: // end
                    triggerEvent = 'lastPage';
                    break;
                case 36: // home
                    triggerEvent = 'firstPage';
                    break;
                case 13: // enter
                    triggerEvent = 'select';
                    break;
            }

            if (triggerEvent) {
                element.trigger(triggerEvent);
                $event.preventDefault();
            }
        });
    };

    // hijack onDataBound event to prevent focusing on the grid when paging
    function hijackDataBoundEvent(gridOptions) {
        var dataBound = gridOptions.onDataBound;
        gridOptions.onDataBound = function() {
            gridOptions.onDataBound = dataBound;
        };
    }

    return {
        bindShortcuts: bindShortcuts
    };
});