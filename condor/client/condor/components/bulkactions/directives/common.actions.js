(function() {
    'use strict';
    angular.module('inprotech.components.bulkactions')
        .factory('commonActions', function() {

            var clickNotDefined = function() {
                throw new Error('action not defined!');
            };

            return {
                get: function() {
                    return [{
                        id: 'edit',
                        icon: 'cpa-icon cpa-icon-pencil-square-o',
                        text: 'Edit',
                        maxSelection: 1,
                        click: clickNotDefined
                    }, {
                        id: 'export-excel',
                        icon: 'file-excel-o',
                        text: 'bulkactionsmenu.ExportToExcel',
                        click: clickNotDefined
                    }, {
                        id: 'export',
                        icon: 'file-word-o',
                        text: 'ExportHtml',
                        click: clickNotDefined
                    }, {
                        id: 'delete',
                        icon: 'cpa-icon cpa-icon-trash-o',
                        text: 'Delete',
                        click: clickNotDefined
                    }, {
                        id: 'move-right',
                        icon: 'arrow-right',
                        text: 'Move to Right',
                        click: clickNotDefined
                    }, {
                        id: 'move-left',
                        icon: 'arrow-left',
                        text: 'Move to Left',
                        click: clickNotDefined
                    }, {
                        id: 'duplicate',
                        icon: 'cpa-icon cpa-icon-file-stack-o',
                        text: 'Duplicate',
                        maxSelection: 1,
                        click: clickNotDefined
                    }];
                }
            };
        });
})();
