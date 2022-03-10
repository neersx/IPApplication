angular.module('Inprotech.SchemaMapping')
    .factory('docItemHelper', [function() {
        'use strict';

        return {
            initColumns: function(docItem, node) {
                _.each(docItem.columns, function(column) {
                    column.nodeId = node.id;
                    column.docItemId = docItem.id;
                    column.group = node.name + ' - ' + docItem.code;
                    column.label = column.name + ' (' + column.type + ')';
                });
            }
        };
    }]);