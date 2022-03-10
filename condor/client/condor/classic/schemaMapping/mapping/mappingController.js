angular.module('Inprotech.SchemaMapping')
    .controller('mappingController', ['$scope', '$timeout', 'viewInitialiser',
        'schemaHelper', 'schemaNode', 'persistence', 'notificationService', 'splitterBuilder', 'dateHelper',
        function($scope, $timeout, viewInitialiser, schemaHelper, schemaNode, persistence, notificationService, splitterBuilder, dateHelper) {

            'use strict';

            var schema = null;
            var viewData = null;

            $scope.dateHelper = dateHelper;

            $scope.initData = function() {
                viewData = viewInitialiser.data;
                if (viewData.missingDependencies) {
                    $scope.editable = false;
                    notificationService.alert({
                        message: 'schemaMapping.mpLblMissingDependencies',
                        messageParams: { name: viewData.name }
                    });
                    return;
                }

                $scope.editable = true;
                schema = viewData.schema;

                schemaHelper.init(schema);
                persistence.init($scope, schema, viewData.mappingEntries, viewData.docItems);

                $scope.expandedNodes = [];
                $scope.current = null;
                $scope.structure = [schema.structure];
                $scope.mappingInfo = {
                    oldName: viewData.name,
                    name: viewData.name,
                    id: viewData.id,
                    visible: true,
                    isDtdFile: viewData.isDtdFile,
                    shouldAddDocType: !((!viewData.fileRef) || (viewData.fileRef === null)),
                    fileRef: viewData.fileRef,
                    rootNodeName: viewData.rootNodeName
                };
                if (!$scope.mappingInfo.shouldAddDocType) {
                    //default file ref set to file name
                    $scope.mappingInfo.fileRef = viewData.fileName;
                }

                $timeout($scope.expandAll);
            }

            $scope.datetime = {
                opened: false,
                open: function($event) {
                    $event.preventDefault();
                    $event.stopPropagation();

                    $scope.datetime.opened = true;
                }
            };
            $scope.filterParameters = {
                name: '!gstrEntryPoint'
            };
            $scope.expandDetails = false;

            $scope.opts = {
                equality: function(nodea, nodeb) {
                    if (nodea === undefined || nodeb === undefined) {
                        return false;
                    }

                    return nodea.id === nodeb.id;
                },
                isSpecificNode: function(node) {
                    return node.nodeType === 'Choice' || node.nodeType === 'Sequence';
                },
                injectClasses: {
                    iExpanded: 'cpa-icon cpa-icon-minus',
                    iCollapsed: 'cpa-icon cpa-icon-plus',
                    iSpecific: 'lightBorder'
                }
            };

            $scope.showDetails = function(node) {
                if (!node) {
                    $scope.current = null;
                    return;
                }

                $scope.current = schemaNode($scope, schema, node);
            };

            $scope.isInputInvalid = function(nodeForm) {
                return nodeForm.$error.numeric || nodeForm.$error.time || nodeForm.$error.date;
            };

            $scope.isInputRequired = function(nodeForm) {
                return !$scope.isInputInvalid(nodeForm) && nodeForm.$error.required;
            };

            $scope.setToNullIfBlank = function(fixedValue, id) {
                if (fixedValue[id] === '') {
                    fixedValue[id] = null;
                }
            }

            $scope.findElement = function(name) {
                return _.find(schema.nodes, function(node) {
                    return node.name === name;
                });
            };

            $scope.findPath = function(name) {
                var found = $scope.findElement(name);

                return schema.path(found);
            };

            $scope.toggleAllNodes = function() {
                if ($scope.expandedNodes.length === 0) {
                    $scope.expandAll();
                } else {
                    $scope.collapseAll();
                }
            };

            $scope.collapseAll = function() {
                $scope.expandedNodes = [];
            };

            var isExpanding = false;

            $scope.expandAll = function() {
                isExpanding = true;
                $timeout(function() {
                    var expandedNodes = [schema.nodes[0]];
                    var mappedNodeKeys = _.union(_.keys($scope.model.docItemColumns), _.keys($scope.model.fixedValues));
                    var allChoiceElements = _.pluck(_.where(schema.nodes, {
                        name: 'Choice'
                    }), 'id');

                    if (mappedNodeKeys.length > 0) {
                        var mappedNodes = _.filter(schema.nodes, function(node) {
                            return _.contains(mappedNodeKeys, node.id);
                        });
                        var rootNodeId = schema.nodes[0].id;

                        _.each(mappedNodes, function(node) {
                            var current = node;
                            while (current && current.id !== rootNodeId) {
                                expandedNodes.push(current);
                                current = _.find(schema.nodes, {
                                    id: current.parentId
                                });
                            }
                        });

                        var unMappedChoiceIds = _.reject(allChoiceElements, function(n) {
                            return _.findWhere(expandedNodes, {
                                id: n
                            });
                        });

                        var allExceptUnMappedChoices = _.reject(schema.nodes, function(n) {
                            return _.contains(unMappedChoiceIds, n.parentId);
                        });

                        if (allExceptUnMappedChoices.length <= 500) {
                            expandedNodes = allExceptUnMappedChoices;
                        } else {
                            expandedNodes = _.uniq(expandedNodes);
                        }

                    } else {
                        var allNonChoiceNodes = _.reject(schema.nodes, function(n) {
                            return _.contains(allChoiceElements, n.parentId);
                        });

                        if (allNonChoiceNodes.length <= 500) {
                            expandedNodes = allNonChoiceNodes;
                        }
                    }
                    $scope.expandedNodes = expandedNodes;
                    $timeout(function() {
                        isExpanding = false;
                    }, 100);
                });
            };

            $scope.isExpanding = function() {
                return isExpanding;
            };

            $scope.expandToNode = function(name) {
                $scope.expandedNodes = $scope.findPath(name);
                $scope.showDetails($scope.findElement(name));
            };

            $scope.showDocItemPicklist = function() {
                $scope.$broadcast('docItemPicklist.show');
            };

            $scope.save = function(form) {
                if (form.$invalid) { return; }

                var fileRef = ($scope.mappingInfo.isDtdFile && $scope.mappingInfo.shouldAddDocType) ? $scope.mappingInfo.fileRef : null;
                persistence.save(viewData.id, $scope.mappingInfo.name, { isDtdFile: $scope.mappingInfo.isDtdFile, fileRef: fileRef }).then(function(result) {
                    if (result) {
                        viewData.fileRef = $scope.mappingInfo.shouldAddDocType ? $scope.mappingInfo.fileRef : null;
                        form.$setPristine();
                    }
                });
            };

            $scope.hasChanges = function() {
                return schema && schema.dirty;
            };

            $scope.updateMappingName = function(value, old) {
                if (!value) {
                    $scope.mappingInfo.name = old;
                    return;
                }
                return persistence.updateName(viewData.id, value)
                    .then(function() {}, function(response) {
                        if (response === 'DUPLICATE_NAME') {
                            notificationService.alert({ message: 'schemaMapping.usDuplicateMappingName' });
                        } else {
                            notificationService.alert({ message: 'schemaMapping.' + response });
                        }
                    });
            };

            $scope.isRoot = function(node) {
                return node.parentId ? false : true;
            };

            $scope.isMapped = function(node) {
                return $scope.model && ($scope.model.docItemColumns[node.id] || $scope.model.fixedValues[node.id]) ? true : false;
            };

            $scope.isDocItemSelected = function(node) {
                return $scope.model && $scope.model.docItems[node.id] && !$scope.isMapped(node);
            };

            $scope.hasError = function(node) {
                return $scope.model && $scope.model.docItems[node.id] && $scope.model.docItems[node.id].error;
            };

            $scope.isSaveEnabled = function(form) {
                return $scope.editable && form.$valid && (form.$dirty || $scope.hasChanges() || false);
            }

            $scope.discard = function(form) {
                $scope.initData();
                form.$setPristine();
            }

            $scope.padZero = function(n) {
                if (n < 10) {
                    return '0' + n;
                }

                return n;
            }

            var init = function() {
                var treePane = {
                    collapsible: false,
                    collapsed: false,
                    resizable: true,
                    size: '42%',
                    min: '20%',
                    max: '55%'
                };

                var detailsPane = {
                    collapsible: false,
                    resizable: true,
                    min: '45%',
                    max: '80%'
                };

                $scope.splitterDetails = splitterBuilder.BuildOptions('mainContent', {
                    panes: [treePane, detailsPane]
                });
            }

            init();

            $scope.initData();
        }
    ]);