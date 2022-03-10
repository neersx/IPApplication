angular.module('Inprotech.SchemaMapping')
    .factory('schemaNode', ['$http', 'url', 'docItemHelper', 'notificationService', function($http, url, docItemHelper, notificationService) {
        'use strict';

        return function(scope, schema, node) {
            return {
                node: node,
                type: schema.type(node.typeName),
                isRequired: node.isRequired,
                underlyingType: function() {
                    if (this.type.unionTypes) {
                        return schema.type(scope.model.selectedUnionTypes[node.id]);
                    }

                    return this.type;
                },
                docItem: function(docItemId, docItemName) {
                    if (docItemId == null) {
                        var nodeKeys = Object.keys(scope.model.docItemColumns);
                        _.each(nodeKeys, function(key) {
                            if (scope.model.docItemColumns[key] && scope.model.docItemColumns[key].nodeId === node.id) {
                                scope.model.docItemColumns[key] = null;
                            }
                        });
                        return;
                    }
                    var self = this;
                    $http
                        .get(url.api('schemamapping/docItem?id=' + docItemId))
                        .then(function(response) {
                            var docItem = response.data;
                            scope.model.docItems[node.id] = docItem;

                            docItemHelper.initColumns(docItem, node);

                            if (self.type && self.type.canHaveValue && docItem.columns.length === 1) {
                                scope.model.docItemColumns[node.id] = docItem.columns[0];
                            }
                        }, function(response) {
                            if (response.data.status === 'FailedToReadDocItem') {
                                notificationService.alert({
                                    message: 'schemaMapping.mpLblFailedToReadDocItem',
                                    messageParams: {
                                        name: docItemName,
                                        error: response.data.error
                                    }
                                })
                            }
                            return true;
                        });
                },
                docItemColumns: function() {
                    var path = schema.path(node).reverse();
                    var results = [];

                    _.each(path, function(node) {
                        var docItem = scope.model.docItems[node.id];
                        if (!docItem) {
                            return;
                        }

                        _.each(docItem.columns, function(column) {
                            results.push(column);
                        });
                    });

                    return results;
                },
                setDirty: function() {
                    schema.dirty = true;
                }
            };
        };
    }]);