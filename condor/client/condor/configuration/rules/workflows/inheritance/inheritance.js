angular.module('inprotech.configuration.rules.workflows').controller('WorkflowsInheritanceController',
    function ($scope, viewData, kendoTreeBuilder, kendoWidgetHelper, modalService, notificationService,
        workflowInheritanceService, workflowsMaintenanceService, $timeout, $stateParams, $state, bus) {
        'use strict';

        var vm = this;
        var allExpandedThreshold = 200;
        var service;
        var lastSelectedNodeId;
        vm.$onInit = onInit;

        function onInit() {
            service = workflowInheritanceService;
            lastSelectedNodeId = $stateParams.selectedNode;

            vm.canEditProtected = viewData.canEditProtected;
            vm.moveBeforeTopItem = moveBeforeTopItem;
            vm.deleteAndMoveChildrenBeforeTopItem = deleteAndMoveChildrenBeforeTopItem;
            vm.isUnlinkEnabled = isUnlinkEnabled;
            vm.isDeleteEnabled = isDeleteEnabled;
            vm.findTopCriteria = findTopCriteria;
            vm.isUnlinkable = isUnlinkable;
            vm.hasOffices = viewData.hasOffices;
            vm.prepareForMove = prepareForMove;
            vm.breakInheritance = breakInheritance;
            vm.deleteCriteria = deleteCriteria;
            vm.move = move;
            vm.getNewParent = getNewParent;
            vm.getDataSource = getDataSource;
            vm.treeOptions = buildGridOptions();
        }

        vm.closeDetailView = function () {
            vm.selectedCriteria = null;
            vm.treeOptions.deselect();
        };

        vm.expandAll = function () {
            vm.treeOptions.expandAll();
        };

        vm.collapseAll = function () {
            vm.treeOptions.collapseAll();
        };

        vm.showsDetailView = function () {
            return vm.selectedCriteria != null;
        };

        vm.onUnlinkClick = function () {
            vm.breakInheritance(vm.selectedCriteria).then(function () {
                vm.moveBeforeTopItem(vm.selectedCriteria, vm.getDataSource());
                vm.selectedCriteria = null;
                notificationService.success();
            });
        };

        vm.onDeleteClick = function () {
            service.isCriteriaUsedByCase(vm.selectedCriteria.id).then(function (isUsedByCase) {
                if (isUsedByCase == true) {
                    modalService.open({
                        id: 'CriteriaUnableToDelete',
                        scope: $scope,
                        options: {
                            criteriaId: vm.selectedCriteria.id
                        }
                    });
                } else {
                    vm.deleteCriteria(vm.selectedCriteria).then(function () {
                        vm.deleteAndMoveChildrenBeforeTopItem(vm.selectedCriteria, vm.getDataSource());
                        vm.selectedCriteria = null;
                        notificationService.success();
                    });
                }
            })
        };

        vm.isExpendAllEnabled = function () {
            if (vm.treeOptions.$widget) {
                return !_.all(vm.treeOptions.$widget.dataSource.data(), isAllExpanded);
            }
            return false;
        };

        vm.isCollapseAllEnabled = function () {
            if (vm.treeOptions.$widget) {
                return _.any(vm.treeOptions.$widget.dataSource.data(), isAnyCollapsible);
            }
            return false;
        };

        function traverseTree(items, expression) {
            for (var i = 0; i < items.length; i++) {
                if (expression(items[i])) return items[i];

                if (items[i].items) {
                    var foundItem = traverseTree(items[i].items, expression);
                    if (foundItem) return foundItem;
                }
            }
            return null;
        }

        function buildGridOptions() {
            return kendoTreeBuilder.buildOptions($scope, {
                id: 'criteriaInheritanceTree',
                dataSource: viewData.trees,
                dragAndDrop: true,
                loadOnDemand: false, // items need to be pre-loaded for expandTo to work
                expandedByDefault: viewData.totalCount <= allExpandedThreshold,
                select: setSelected,
                drop: function (evt) {
                    evt.preventDefault();

                    var result = vm.prepareForMove(evt);

                    if (result) {
                        vm.move(result.selectedCriteria, result.newParent).then(function () {
                            notificationService.success();
                            selectNode(evt.sender, evt.sourceNode);
                            if (evt.destinationNode) {
                                evt.complete();
                            } else {
                                $state.reload();
                            }
                        });
                    }
                },
                dataBound: function (e) {
                    if (e.node) {
                        return;
                    }

                    if (lastSelectedNodeId) {
                        findAndSelectNode(e.sender, function (i) {
                            return i.id == lastSelectedNodeId;
                        });
                    } else {
                        findAndSelectNode(e.sender, function (i) {
                            return i.isFirstFromSearch;
                        });
                    }

                    vm.onNavigateClick = initOnNavigateClick(e.sender);
                }
            });
        }

        function initOnNavigateClick(sender) {
            return function (dataItem, $event) {
                $event.preventDefault();

                var iNode = sender.findByUid(dataItem.uid);
                selectNode(sender, iNode).then(function () {
                    $state.go('workflows.details', {
                        id: dataItem.id
                    });
                });
            }
        }

        function findAndSelectNode(sender, findFunc) {
            var foundNode = traverseTree(sender.dataItems(), findFunc);
            if (foundNode) {
                var iNode = sender.findByUid(foundNode.uid);
                expandAndSelect(sender, iNode);
            }
        }

        function expandAndSelect(sender, node) {
            if (!sender.options.expandedByDefault) {
                sender.expandTo(node.id);
            }

            selectNode(sender, node);
        }

        function selectNode(sender, node) {
            sender.select(node);
            var evtParam = {
                sender: sender,
                node: node
            };
            return vm.setSelectedDebounced(evtParam);
        }

        vm.setSelectedDebounced = _.debounce(setSelected, 100, true);

        function setSelected(e) {
            vm.selectedCriteria = kendoWidgetHelper.getDataItem(e.sender, e.node);

            if (!vm.selectedCriteria.detail) {
                var populateDetails = function (id) {
                    service.getCriteriaDetail(id).then(function (data) {
                        if (id === vm.selectedCriteria.id) {
                            vm.selectedCriteria.detail = data;
                        }

                        bus.channel('resize').broadcast();
                    });
                };
                populateDetails(vm.selectedCriteria.id);
            } else {
                bus.channel('resize').broadcast();
            }

            $timeout(function () {
                vm.treeOptions.scrollToSelected();
            });

            // update the selectedNode param in the URL without reloading 
            // (requires selectedNode param to be set as dynamic in workflows.inheritance state registration)
            return $state.go('workflows.inheritance', {
                selectedNode: vm.selectedCriteria.id
            }, {
                location: 'replace'
            });
        }

        function prepareForMove(evt) {
            var result = {};
            if (evt.destinationNode === evt.sourceNode) {
                return null;
            }

            result.selectedCriteria = kendoWidgetHelper.getDataItem(evt.sender, evt.sourceNode);
            if (result.selectedCriteria.isProtected && !vm.canEditProtected) {
                unableToMoveNotification('protectedCriteria', result.selectedCriteria.id);

                return null;
            }

            if (result.selectedCriteria.hasProtectedChildren && !vm.canEditProtected) {
                unableToMoveNotification('protectedChildren', result.selectedCriteria.id);
                return null;
            }

            result.newParent = vm.getNewParent(evt);
            if (result.newParent && !result.newParent.isProtected && result.selectedCriteria.isProtected) {
                unableToMoveNotification('protectedFromUnprotectedError', result.selectedCriteria.id);
                return null;
            }

            var oldParent = kendoWidgetHelper.getParentDataItem(evt.sender, evt.sourceNode);
            if (oldParent === result.newParent) {
                return null;
            }

            return result;
        }

        function getNewParent(evt) {
            if (evt.dropPosition === 'over') {
                return kendoWidgetHelper.getDataItem(evt.sender, evt.destinationNode);
            } else {
                return kendoWidgetHelper.getParentDataItem(evt.sender, evt.destinationNode);
            }
        }

        function move(selectedCriteria, newParent) {
            if (newParent) {
                // changing parent
                return modalService
                    .openModal({
                        id: 'InheritanceChangeConfirmation',
                        childCriteriaId: selectedCriteria.id,
                        childName: selectedCriteria.name,
                        parentCriteriaId: newParent.id,
                        parentName: newParent.name
                    }).then(function (data) {
                        return service.changeParentInheritance(data.childCriteriaId, data.parentCriteriaId, data.isReplaceChild);
                    }).then(function (data) {
                        if (data.usedByCase) {
                            return notificationService.info({
                                title: "workflows.inheritance.policingNotification.title",
                                message: "workflows.inheritance.policingNotification.message",
                                messageParams: {
                                    criteriaId: selectedCriteria.id
                                }
                            });
                        }

                        if (data.hasDuplicateEntries) {
                            return notificationService.alert({
                                title: "modal.unableToComplete",
                                message: "workflows.inheritance.duplicateEntries.message",
                                messageParams: {
                                    duplicates: data.duplicateEntries
                                },
                                actionMessage: "workflows.inheritance.duplicateEntries.action"
                            });
                        }
                    });
            } else {
                // breaking inheritance
                return vm.breakInheritance(selectedCriteria);
            }
        }

        function unableToMoveNotification(message, id) {
            notificationService.alert({
                title: 'modal.unableToComplete',
                message: 'workflows.inheritance.unableToMove.' + message,
                messageParams: {
                    criteriaId: id
                }
            });
        }

        function breakInheritance(selectedCriteria) {
            return workflowsMaintenanceService.getParent(selectedCriteria.id)
                .then(function (data) {
                    return modalService.openModal({
                        id: 'InheritanceBreakConfirmation',
                        parent: data,
                        criteriaId: selectedCriteria.id,
                        context: 'inheritance'
                    });
                }).then(function () {
                    return service.breakInheritance(selectedCriteria.id);
                });
        }

        function deleteCriteria(selectedCritria) {
            var prefix = 'workflows.inheritance.deleteCriteria.';
            var message = selectedCritria.hasChildren ? 'confirmHasChildrenMessage' : 'confirmMessage';

            return notificationService.confirmDelete({
                message: prefix + message,
                messageParams: {
                    id: selectedCritria.id
                }
            }).then(function () {
                return service.deleteCriteria(selectedCritria.id);
            });
        }

        function moveBeforeTopItem(selectedCriteria, dataSource) {
            var topCriteria = vm.findTopCriteria(selectedCriteria);
            dataSource.remove(selectedCriteria);
            dataSource.insert(
                dataSource.indexOf(topCriteria),
                selectedCriteria
            );
            return topCriteria;
        }

        function deleteAndMoveChildrenBeforeTopItem(selectedCriteria, dataSource) {
            var topCriteria = vm.findTopCriteria(selectedCriteria);

            _.each(selectedCriteria.items, function (item) {
                dataSource.insert(dataSource.indexOf(topCriteria), item);
            });

            dataSource.remove(selectedCriteria);

            return topCriteria;
        }

        function isUnlinkable(isTopLevelItem, canEditProtected, isProtected) {
            if (isTopLevelItem) {
                return false;
            }

            return canEditProtected || !isProtected;
        }

        function isTopLevelItem(dataItem) {
            return !dataItem || dataItem.level() === 0;
        }

        function findTopCriteria(selectedCriteria) {
            var parent = selectedCriteria.parent().parent();
            if (!isTopLevelItem(parent)) {
                return findTopCriteria(parent);
            } else {
                return parent;
            }
        }

        function isUnlinkEnabled() {
            var criteria = vm.selectedCriteria;

            if (!criteria) {
                return false;
            }

            return vm.isUnlinkable(isTopLevelItem(criteria), vm.canEditProtected, criteria.isProtected);
        }

        function isDeleteEnabled() {
            var criteria = vm.selectedCriteria;

            if (!criteria) {
                return false;
            }

            if (!criteria.isProtected) {
                return true;
            }

            return vm.canEditProtected;
        }

        function isAnyCollapsible(node) {
            if (!node.hasChildren) {
                return false;
            }

            if (node.expanded) {
                return true;
            }

            return _.any(node.items, isAnyCollapsible);
        }

        function isAllExpanded(node) {
            if (!node.hasChildren) {
                return true;
            }

            if (!node.expanded) {
                return false;
            }

            return _.all(node.items, isAllExpanded);
        }

        function getDataSource() {
            return vm.treeOptions.$widget.dataSource;
        }
    });