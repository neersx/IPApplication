angular.module('Inprotech.SchemaMapping')
    .factory('persistence', ['$http', 'url', 'notificationService', 'docItemHelper', 'dateHelper', function($http, url, notificationService, docItemHelper, dateHelper) {
        'use strict';
        var _scope, _schema;

        function convertToPersistFormat(model) {
            var mappingEntries = {};

            function isGlobalParam(name) {
                return name === 'gstrEntryPoint';
            }

            function entry(id) {
                if (!mappingEntries[id]) {
                    mappingEntries[id] = {};
                }

                return mappingEntries[id];
            }

            _.each(model.fixedValues, function(value, nodeId) {
                if (!_schema.node(nodeId)) {
                    return;
                }

                entry(nodeId).fixedValue = value;
            });

            _.each(model.docItemColumns, function(column, nodeId) {
                if (!column) {
                    return;
                }

                var node = _schema.node(nodeId);

                if (!node) {
                    return;
                }

                if (!_schema.type(node.typeName).canHaveValue) {
                    return;
                }

                var docItem = model.docItems[column.nodeId];

                if (!docItem || docItem.columns.indexOf(column) === -1) {
                    return;
                }

                entry(nodeId).docItemBinding = {
                    nodeId: column.nodeId,
                    columnId: column.index,
                    docItemId: docItem.id
                };
            });

            _.each(model.docItems, function(docItem, nodeId) {
                if (!docItem) {
                    return;
                }

                if (!_schema.node(nodeId)) {
                    return;
                }

                entry(nodeId).docItem = {
                    id: docItem.id,
                    parameters: _.map(docItem.parameters, function(param) {
                        var name = param.name;

                        if (isGlobalParam(name)) {
                            return {
                                id: name,
                                type: 'global'
                            };
                        }

                        return {
                            id: name,
                            type: 'fixed',
                            value: !param.value && param.value !== 0 ? null : param.value
                        };
                    })
                };
            });

            _.each(model.selectedUnionTypes, function(unionType, nodeId) {
                if (!unionType) {
                    return;
                }

                if (!_schema.node(nodeId)) {
                    return;
                }

                entry(nodeId).selectedUnionType = unionType;
            });

            return {
                mappingEntries: mappingEntries
            };
        }

        function buildFixedValues(mappingEntries, schema) {
            var results = {};

            _.each(mappingEntries, function(mapping, nodeId) {
                if (!mapping.fixedValue) {
                    return;
                }
                var subType = {};
                var nodeDetails = schema.node(nodeId) || {};
                if (mapping.selectedUnionType) {
                    subType = schema.type(mapping.selectedUnionType);
                }
                if (nodeDetails.typeName == "Date" || nodeDetails.typeName == "DateTime" || nodeDetails.typeName == "Time" || subType.inputType == "date") {
                    results[nodeId] = dateHelper.convertForDatePicker(mapping.fixedValue);
                } else {
                    results[nodeId] = mapping.fixedValue;
                }
            });

            return results;
        }

        function buildDocItems(schema, mappingEntries, docItemDetails) {
            var results = {};

            _.each(mappingEntries, function(mapping, nodeId) {
                if (!mapping.docItem) {
                    return;
                }

                var node = schema.node(nodeId);

                if (!node) {
                    return;
                }

                var docItem = angular.copy(docItemDetails[mapping.docItem.id]);

                if (!docItem) {
                    results[nodeId] = {
                        id: mapping.docItem.id,
                        error: 'NotFound'
                    };
                    return;
                }

                _.each(docItem.parameters, function(param1) {
                    var p = _.find(mapping.docItem.parameters, function(param2) {
                        return param2.id === param1.name;
                    });
                    if (p) {
                        param1.value = p.value;
                    }
                });

                docItemHelper.initColumns(docItem, node);

                results[nodeId] = docItem;
            });

            return results;
        }

        function buildDocItemColumns(mappingEntries, docItems) {
            var results = {};

            _.each(mappingEntries, function(mapping, nodeId) {
                if (!mapping.docItemBinding) {
                    return;
                }

                var docItem = docItems[mapping.docItemBinding.nodeId];
                if (!docItem) {
                    return;
                }

                var column = _.find(docItem.columns, function(column) {
                    var binding = mapping.docItemBinding;

                    return binding.nodeId === column.nodeId &&
                        binding.docItemId === column.docItemId &&
                        binding.columnId === column.index;
                });

                results[nodeId] = column;
            });

            return results;
        }

        function buildSelectedUnionTypes(mappingEntries) {
            var results = {};

            _.each(mappingEntries, function(mapping, nodeId) {
                results[nodeId] = mapping.selectedUnionType || null;
            });

            return results;
        }

        function monitorChanges(scope) {
            scope.$watch(function() {
                if (!scope.current || !scope.current.node) {
                    return null;
                }

                return {
                    nodeId: scope.current.node.id,
                    fixedValue: scope.model.fixedValues[scope.current.node.id],
                    docItemColumn: scope.model.docItemColumns[scope.current.node.id],
                    docItem: scope.model.docItems[scope.current.node.id]
                };
            }, function(newVal, oldVal) {
                if (!scope.current || !oldVal || !newVal || newVal.nodeId !== oldVal.nodeId) {
                    return;
                }

                scope.current.setDirty();

            }, angular.equals);
        }

        return {
            init: function(scope, schema, mappingEntries, docItemDetails) {
                mappingEntries = mappingEntries || {};
                _scope = scope;
                _schema = schema;

                var docItems = buildDocItems(schema, mappingEntries, docItemDetails);

                scope.model = {
                    fixedValues: buildFixedValues(mappingEntries, schema),
                    docItems: docItems,
                    docItemColumns: buildDocItemColumns(mappingEntries, docItems),
                    selectedUnionTypes: buildSelectedUnionTypes(mappingEntries)
                };

                monitorChanges(scope, mappingEntries);
            },

            save: function(id, name, dtdFileRefInfo) {
                var data = convertToPersistFormat(_scope.model);

                var params = {
                    mappings: data,
                    name: name
                };
                if (dtdFileRefInfo.isDtdFile) {
                    params.fileRef = dtdFileRefInfo.fileRef;
                }

                return $http.put(url.api('schemamappings/' + id), params)
                    .then(function() {
                        _schema.dirty = false;

                        notificationService.success();
                        return true;
                    }, function(response) {
                        response = response.data;
                        if (response === 'DUPLICATE_NAME') {
                            notificationService.alert({
                                message: 'schemaMapping.usDuplicateMappingName'
                            });
                        } else {
                            notificationService.alert({
                                message: 'schemaMapping.' + response
                            });
                        }
                        return false;
                    });
            },

            updateName: function(id, newName) {
                return $http.put(url.api('schemamappings/' + id + '/name'), {
                    name: newName
                });
            }
        };
    }]);