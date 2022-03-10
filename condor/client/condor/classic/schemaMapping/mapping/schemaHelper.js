angular.module('Inprotech.SchemaMapping')
    .factory('schemaHelper', ['dataTypeToInputMap', function(dataTypeToInputMap) {
        'use strict';

        function traverseTree(node, fn) {
            if (!node) {
                return;
            }

            fn(node);

            if (!node.children) {
                return;
            }

            for (var i = 0; i < node.children.length; i++) {
                traverseTree(node.children[i], fn);
            }
        }

        function getPath(node, idToNodeMap) {
            var n = node;
            var path = [];

            while (n) {
                path.unshift(n);
                n = n.parentId ? idToNodeMap[n.parentId] : null;
            }

            return path;
        }

        function isRequired(node) {
            if (node.nodeType === 'element') {
                return node.minOccurs && node.minOccurs !== '0';
            } else if (node.nodeType === 'attribute') {
                return node.use === 'Required';
            }

            return null;
        }

        return {
            init: function(schema) {
                var map = {};
                var nodes = [];
                var idToNodeMap = {};

                schema.dirty = false;
                _.each(schema.types, function(type) {
                    type.inputType = (type.restrictions && type.restrictions.enumerations) ? 'list' : dataTypeToInputMap[type.dataType];
                    map[type.name] = type;
                    type.canHaveValue = (type.dataType || type.unionTypes);
                });

                schema.types = map;

                traverseTree(schema.structure, function(n) {
                    nodes.push(n);
                    idToNodeMap[n.id] = n;
                    n.isRequired = isRequired(n);
                });

                schema.nodes = nodes;

                schema.node = function(id) {
                    return idToNodeMap[id];
                };

                schema.path = function(node) {
                    if (!_.isObject(node)) {
                        node = schema.node(node); //by id
                    }

                    return getPath(node, idToNodeMap);
                };

                schema.type = function(typeName) {
                    return schema.types[typeName];
                };
            }
        };
    }]);