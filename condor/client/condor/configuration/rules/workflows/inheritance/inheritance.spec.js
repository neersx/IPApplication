describe('inprotech.configuration.rules.workflows.WorkflowsInheritanceController', function() {
    'use strict';

    var controller, scope, kendoTreeBuilder, kendoWidgetHelper, modalService, notificationService, workflowInheritanceService, workflowsMaintenanceService, promiseMock, stateParams, stateMock;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {

            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.notification', 'inprotech.mocks.components.tree', 'inprotech.mocks.configuration.rules.workflows', 'inprotech.mocks.core', 'inprotech.mocks.components.kendo']);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            workflowInheritanceService = $injector.get('workflowInheritanceServiceMock');
            $provide.value('workflowInheritanceService', workflowInheritanceService);

            kendoTreeBuilder = $injector.get('kendoTreeBuilderMock');
            $provide.value('kendoTreeBuilder', kendoTreeBuilder);

            kendoWidgetHelper = $injector.get('kendoWidgetHelperMock');
            $provide.value('kendoWidgetHelper', kendoWidgetHelper);

            promiseMock = $injector.get('promiseMock');

            stateMock = $injector.get('stateMock');
            $provide.value('$state', stateMock);

            workflowsMaintenanceService = $injector.get('workflowsMaintenanceServiceMock');
            $provide.value('workflowsMaintenanceService', workflowsMaintenanceService);

        });

        inject(function($rootScope, $controller) {
            controller = function() {
                scope = $rootScope.$new();
                var c = $controller('WorkflowsInheritanceController', {
                    $scope: scope,
                    viewData: {},
                    kendoTreeBuilder: kendoTreeBuilder,
                    modalService: modalService,
                    notificationService: notificationService,
                    workflowInheritanceService: workflowInheritanceService,
                    $stateParams: stateParams || {}
                });
                c.$onInit();
                return c;
            }
        });
    });

    describe('initialise', function() {
        it('should initialise controller', function() {
            var c = controller();
            expect(kendoTreeBuilder.buildOptions).toHaveBeenCalled();
            expect(c.treeOptions).toBeDefined();
            expect(c.moveBeforeTopItem).toBeDefined();
            expect(c.breakInheritance).toBeDefined();
            expect(c.closeDetailView).toBeDefined();
            expect(c.expandAll).toBeDefined();
            expect(c.collapseAll).toBeDefined();
            expect(c.showsDetailView).toBeDefined();
            expect(c.selectedCriteria).not.toBeDefined();
        });
    });

    describe('select item', function() {
        var ctrl, setSelectedFn;

        beforeEach(function() {
            ctrl = controller();
            setSelectedFn = kendoTreeBuilder.buildOptions.calls.first().args[1].select;
        });

        it('should populate details pane and update selected url', function() {
            expect(setSelectedFn).toBeDefined();
            var e = {
                sender: 'a',
                node: 'b'
            }
            kendoWidgetHelper.getDataItem.returnValue = {id: 123};
            var criteriaDetail = { criteriaId: 'aaaaaa'};
            workflowInheritanceService.getCriteriaDetail.returnValue = criteriaDetail;
            
            setSelectedFn(e);

            expect(kendoWidgetHelper.getDataItem).toHaveBeenCalledWith(e.sender, e.node);
            expect(workflowInheritanceService.getCriteriaDetail).toHaveBeenCalledWith(123);
            expect(ctrl.selectedCriteria.detail).toBe(criteriaDetail);

            expect(stateMock.go).toHaveBeenCalledWith('workflows.inheritance',
                jasmine.objectContaining({
                    selectedNode: 123
                }),
                jasmine.objectContaining({
                    location: 'replace'
                }));
        });
    });

    describe('click unlink button', function() {
        var ctrl;

        beforeEach(function() {
            ctrl = controller();
            ctrl.selectedCriteria = {
                id: 123,
                parent: function() {
                    return {
                        parent: function() {
                            return {
                                id: 456
                            };
                        }
                    };
                }
            };
        });

        it('should pop up inheritance unlink confirmation', function() {
            ctrl.breakInheritance = promiseMock.createSpy();

            spyOn(ctrl, 'moveBeforeTopItem');

            ctrl.onUnlinkClick();
            expect(ctrl.breakInheritance).toHaveBeenCalled();
            expect(ctrl.moveBeforeTopItem).toHaveBeenCalled();
            expect(ctrl.selectedCriteria).toBeNull();
            expect(notificationService.success).toHaveBeenCalled();
        });

        it('should show confirmation and call breakInheritance on service', function() {

            workflowsMaintenanceService.getParent = promiseMock.createSpy();
            modalService.openModal = promiseMock.createSpy();
            kendoWidgetHelper.getParentDataItemFromData.returnValue = {
                id: 111
            };

            ctrl.breakInheritance(ctrl.selectedCriteria);

            expect(workflowsMaintenanceService.getParent).toHaveBeenCalled();
            expect(modalService.openModal).toHaveBeenCalled();
            expect(workflowInheritanceService.breakInheritance).toHaveBeenCalled();
        });
    });

    it('should move selected critera to top item', function() {
        var c = controller();
        var dataSource = new kendo.data.HierarchicalDataSource({});
        var selectedCriteria = {};
        spyOn(dataSource, 'remove');
        spyOn(dataSource, 'insert');
        spyOn(c, 'findTopCriteria');

        c.moveBeforeTopItem(selectedCriteria, dataSource);

        expect(dataSource.remove).toHaveBeenCalled();
        expect(dataSource.insert).toHaveBeenCalled();
        expect(c.findTopCriteria).toHaveBeenCalled();
    });

    it('should find top criteria', function() {
        var c, dataSource, selectedCriteria, topCriteria;
        c = controller();
        dataSource = new kendo.data.HierarchicalDataSource({
            data: [{
                text: 'aaa',
                children: [{
                    text: '111'
                }, {
                    text: '222'
                }]
            }, {
                text: 'bbb',
                children: [{
                    text: '333'
                }, {
                    text: '444'
                }]
            }]
        });
        dataSource.fetch();
        // set selectedCriteria as {text: '333'}
        selectedCriteria = dataSource.data()[1].children[0];

        topCriteria = c.findTopCriteria(selectedCriteria);

        expect(topCriteria).toBe(dataSource.data()[1]);
    });

    describe('deleting criteria', function() {
        describe('onDeleteClick', function() {
            it('proceeds to delete if usedByCase false', function() {
                var c = controller();

                c.deleteCriteria = promiseMock.createSpy();
                c.deleteAndMoveChildrenBeforeTopItem = jasmine.createSpy();
                c.getDataSource = _.constant('data');
                var criteria = c.selectedCriteria = {
                    id: 123
                };
                workflowInheritanceService.isCriteriaUsedByCase.returnValue = false;

                c.onDeleteClick();

                expect(c.deleteAndMoveChildrenBeforeTopItem).toHaveBeenCalledWith(criteria, 'data');
                expect(c.selectedCriteria).toBeNull();
                expect(notificationService.success).toHaveBeenCalled();
            });

            it('shows warning if usedByCase true', function() {
                var c = controller();

                c.deleteCriteria = jasmine.createSpy();
                c.deleteAndMoveChildrenBeforeTopItem = jasmine.createSpy();
                c.selectedCriteria = {
                    id: 123
                };
                workflowInheritanceService.isCriteriaUsedByCase.returnValue = true;

                c.onDeleteClick();

                expect(modalService.open).toHaveBeenCalledWith({
                    id: 'CriteriaUnableToDelete',
                    scope: scope,
                    options: {
                        criteriaId: c.selectedCriteria.id
                    }
                });

                expect(c.deleteCriteria).not.toHaveBeenCalled();
                expect(c.deleteAndMoveChildrenBeforeTopItem).not.toHaveBeenCalled();
                expect(notificationService.success).not.toHaveBeenCalled();
            });
        });

        it('deleteCriteria should invoke service call', function() {
            var c = controller();

            c.deleteCriteria({
                id: 1
            });

            expect(workflowInheritanceService.deleteCriteria).toHaveBeenCalledWith(1);
        });

        it('deleteCriteria should show correct message based on hasChildren', function() {
            var c = controller();

            c.deleteCriteria({
                id: 1,
                hasChildren: false
            });

            expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                message: 'workflows.inheritance.deleteCriteria.confirmMessage',
                messageParams: {
                    id: 1
                }
            });

            c.deleteCriteria({
                id: 1,
                hasChildren: true
            });

            expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                message: 'workflows.inheritance.deleteCriteria.confirmHasChildrenMessage',
                messageParams: {
                    id: 1
                }
            });
        });

        it('should move all children to top level and remove selected criteria', function() {
            var c = controller();
            c.findTopCriteria = jasmine.createSpy().and.returnValue(-22);
            var criteria = {
                items: [33, 44]
            };
            var dataSource = {
                indexOf: jasmine.createSpy().and.returnValue(1),
                insert: jasmine.createSpy(),
                remove: jasmine.createSpy()
            };
            c.getDataSource = _.constant(dataSource);
            c.deleteAndMoveChildrenBeforeTopItem(criteria, dataSource);

            expect(dataSource.indexOf).toHaveBeenCalledWith(-22);
            expect(dataSource.insert).toHaveBeenCalledWith(1, 33);
            expect(dataSource.insert).toHaveBeenCalledWith(1, 44);
            expect(dataSource.remove).toHaveBeenCalledWith(criteria);
        });
    });

    describe('display state of unlink button', function() {
        var ctrl, isTopLevelItem, canEditProtected, isProtected;

        beforeEach(function() {
            ctrl = controller();
        });

        it('unlink button should be disabled', function() {
            isTopLevelItem = true, canEditProtected = true, isProtected = true;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(false);

            isTopLevelItem = true, canEditProtected = true, isProtected = false;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(false);

            isTopLevelItem = true, canEditProtected = false, isProtected = true;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(false);

            isTopLevelItem = true, canEditProtected = false, isProtected = false;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(false);

            isTopLevelItem = false, canEditProtected = false, isProtected = true;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(false);
        });

        it('unlink button should be clickable', function() {
            isTopLevelItem = false, canEditProtected = true, isProtected = true;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(true);

            isTopLevelItem = false, canEditProtected = true, isProtected = false;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(true);

            isTopLevelItem = false, canEditProtected = false, isProtected = false;
            expect(ctrl.isUnlinkable(isTopLevelItem, canEditProtected, isProtected)).toEqual(true);
        });
    });

    describe('enabling and disabling delete button', function() {
        it('enables delete button if criteria is selected and user has rights', function() {
            var ctrl = controller();
            ctrl.selectedCriteria = {
                id: 123
            }

            expect(ctrl.isDeleteEnabled()).toBe(true);
        });

        it('disables delete button if criteria is not selected', function() {
            var ctrl = controller();

            expect(ctrl.isDeleteEnabled()).toBe(false);
        })

        describe('user does not have maintain protected criteria rights', function() {
            it('enables delete button if criteria is unprotected (even with protected children - edge case)', function() {
                var ctrl = controller();
                ctrl.selectedCriteria = {
                    id: 123,
                    isProtected: false,
                    hasProtectedChildren: true
                }
                ctrl.canEditProtected = false;

                expect(ctrl.isDeleteEnabled()).toBe(true);
            });

            it('disables delete button if criteria is protected', function() {
                var ctrl = controller();
                ctrl.selectedCriteria = {
                    id: 123,
                    isProtected: true
                }
                ctrl.canEditProtected = false;

                expect(ctrl.isDeleteEnabled()).toBe(false);
            });
        });
    });

    describe('drag drop', function() {
        var ctrl, evt;
        beforeEach(function() {
            ctrl = controller();
            ctrl.setSelectedDebounced = jasmine.createSpy();
            evt = {
                sender: {
                    select: jasmine.createSpy()
                },
                sourceNode: 2,
                preventDefault: jasmine.createSpy(),
                complete: jasmine.createSpy(),
                destinationNode: {}
            }
        });

        it('completes drop', function() {
            ctrl.move = promiseMock.createSpy();
            ctrl.prepareForMove = jasmine.createSpy().and.returnValue({
                selectedCriteria: 11,
                newParent: 22
            });

            ctrl.treeOptions.drop(evt);

            expect(evt.preventDefault).toHaveBeenCalled();
            expect(ctrl.prepareForMove).toHaveBeenCalledWith(evt);
            expect(ctrl.move).toHaveBeenCalledWith(11, 22);
            expect(notificationService.success).toHaveBeenCalled();
            expect(evt.complete).toHaveBeenCalled();
            expect(ctrl.setSelectedDebounced).toHaveBeenCalled();
        });
        
        it('reloads if dropped to nowhere', function() {
            ctrl.move = promiseMock.createSpy();
            ctrl.prepareForMove = jasmine.createSpy().and.returnValue({
                selectedCriteria: 11,
                newParent: 22
            });

            evt.destinationNode = null;

            ctrl.treeOptions.drop(evt);

            expect(evt.preventDefault).toHaveBeenCalled();
            expect(ctrl.prepareForMove).toHaveBeenCalledWith(evt);
            expect(ctrl.move).toHaveBeenCalledWith(11, 22);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateMock.reload).toHaveBeenCalled();
            expect(ctrl.setSelectedDebounced).toHaveBeenCalled();
        });
    });

    describe('prepareForMove', function() {
        var ctrl, evt;

        beforeEach(function() {
            ctrl = controller();
        });

        it('should be null when destinationNode is the same as sourceNode', function() {
            evt = {
                sourceNode: 'abc',
                destinationNode: 'abc'
            };

            var result = ctrl.prepareForMove(evt);

            expect(result).toBeNull();
        });

        describe('unableToMove', function() {
            var evt, translationPrefix;
            beforeEach(function() {
                evt = {
                    sourceNode: 'abc',
                    destinationNode: 'def'
                };
                translationPrefix = 'workflows.inheritance.unableToMove.';
            });

            it('when user does not have permission for protected criteria', function() {
                kendoWidgetHelper.getDataItem.returnValue = {
                    id: 123,
                    isProtected: true
                };
                ctrl.canEditProtected = false;

                var result = ctrl.prepareForMove(evt);

                expect(result).toBeNull();
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: translationPrefix + 'protectedCriteria',
                    messageParams: {
                        criteriaId: 123
                    }
                });
            });

            it('when user does not have permission for protected children', function() {
                kendoWidgetHelper.getDataItem.returnValue = {
                    id: 123,
                    isProtected: false,
                    hasProtectedChildren: true
                };
                ctrl.canEditProtected = false;

                var result = ctrl.prepareForMove(evt);

                expect(result).toBeNull();
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: translationPrefix + 'protectedChildren',
                    messageParams: {
                        criteriaId: 123
                    }
                });
            });
        });

        it('should be null when new parent is the same of old one', function() {
            evt = {
                sourceNode: 'abc',
                destinationNode: 'def'
            };

            kendoWidgetHelper.getDataItem.returnValue = {};
            kendoWidgetHelper.getParentDataItem.returnValue = 'parent';
            ctrl.getNewParent.returnValue = 'parent';

            var result = ctrl.prepareForMove(evt);
            expect(result).toBeNull();
        });

        it('should return object', function() {
            var selectedCriteria = {};
            evt = {
                sourceNode: 'abc',
                destinationNode: 'def'
            };

            kendoWidgetHelper.getDataItem.returnValue = selectedCriteria;
            kendoWidgetHelper.getParentDataItem.returnValue = 'oldParent';
            spyOn(ctrl, 'getNewParent').and.returnValue('newParent');

            var result = ctrl.prepareForMove(evt);

            expect(result).toEqual({
                selectedCriteria: selectedCriteria,
                newParent: 'newParent'
            });
        });

        it('should not allow moving protected criteria under unprotected', function() {
            var selectedCriteria = {
                'isProtected': true
            };
            evt = {
                sourceNode: 'abc',
                destinationNode: 'def'
            };
            kendoWidgetHelper.getDataItem.returnValue = selectedCriteria;
            kendoWidgetHelper.getParentDataItem.returnValue = {
                'isProtected': false
            };
            ctrl.canEditProtected = true;

            var result = ctrl.prepareForMove(evt);

            expect(notificationService.alert).toHaveBeenCalled();
            expect(result).toBe(null);
        });
    });

    describe('should get correct new parent', function() {
        var ctrl, evt;

        beforeEach(function() {
            ctrl = controller();
            evt = {};
            kendoWidgetHelper.getDataItem.returnValue = 'a';
            kendoWidgetHelper.getParentDataItem.returnValue = 'b';
        });

        it('should get data item', function() {
            evt.dropPosition = 'over';
            var result = ctrl.getNewParent(evt);
            expect(result).toEqual('a');
        });

        it('should get parent data item', function() {
            evt.dropPosition = 'not over';
            var result = ctrl.getNewParent(evt);
            expect(result).toEqual('b');
        });
    });

    describe('should pop up correct modal after move', function() {
        var ctrl, selectedCriteria, newParent;

        beforeEach(function() {
            ctrl = controller();
        });

        it('should pop up break inheritance modal', function() {
            newParent = false;
            selectedCriteria = 'criteria';
            spyOn(ctrl, 'breakInheritance');
            ctrl.breakInheritance = promiseMock.createSpy();

            ctrl.move(selectedCriteria, newParent);

            expect(ctrl.breakInheritance).toHaveBeenCalledWith('criteria');

        });

        describe('should pop up change inheritance modal', function() {
            beforeEach(function() {
                newParent = {
                    id: 123,
                    name: 'abc'
                };
                selectedCriteria = {
                    id: 456,
                    name: 'def'
                };
                modalService.openModal = promiseMock.createSpy({
                    childCriteriaId: 123,
                    parentCriteriaId: 456,
                    isReplaceChild: true
                });
            });

            it('should be followed by warning if being involved in open case', function() {
                workflowInheritanceService.changeParentInheritance.returnValue = {
                    usedByCase: true
                };
                notificationService.info = promiseMock.createSpy();

                ctrl.move(selectedCriteria, newParent);
                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'InheritanceChangeConfirmation',
                    childCriteriaId: 456,
                    childName: 'def',
                    parentCriteriaId: 123,
                    parentName: 'abc'
                });
                expect(workflowInheritanceService.changeParentInheritance).toHaveBeenCalledWith(123, 456, true);
                
                expect(notificationService.info).toHaveBeenCalledWith({
                    title: "workflows.inheritance.policingNotification.title",
                    message: "workflows.inheritance.policingNotification.message",
                    messageParams: {
                        criteriaId: 456
                    }
                });
            });

            it('should not display warning or error if no warnings or errors from server', function() {
                workflowInheritanceService.changeParentInheritance.returnValue = {
                    usedByCase: false,
                    hasDuplicateEntries: false
                };
                ctrl.move(selectedCriteria, newParent);
                expect(workflowInheritanceService.changeParentInheritance).toHaveBeenCalled();
                expect(notificationService.info).not.toHaveBeenCalled();
                expect(notificationService.alert).not.toHaveBeenCalled();
            });

            it('should show duplicate entry description error', function() {
                workflowInheritanceService.changeParentInheritance.returnValue = {
                    hasDuplicateEntries: true,
                    duplicateEntries: "abc"
                };
                notificationService.alert = promiseMock.createSpy();

                ctrl.move(selectedCriteria, newParent);
                expect(workflowInheritanceService.changeParentInheritance).toHaveBeenCalledWith(123, 456, true);
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: "modal.unableToComplete",
                    message: "workflows.inheritance.duplicateEntries.message",
                    messageParams: {
                        duplicates: "abc"
                    },
                    actionMessage: "workflows.inheritance.duplicateEntries.action"
                });
            });
        });
    });

    describe('expand all and collapse all buttons', function() {
        var ctrl;

        function setTreeData(ctrl, data) {
            ctrl.treeOptions.$widget.dataSource.data = _.constant(data);
        }

        beforeEach(function() {
            ctrl = controller();
        });

        it('should be both disabled if there is only a single item in the tree', function() {
            setTreeData(ctrl, [{
                hasChildren: false,
                expanded: false
            }]);

            expect(ctrl.isExpendAllEnabled()).toEqual(false);
            expect(ctrl.isCollapseAllEnabled()).toEqual(false);
        });

        it('expandAll should be enabled if there is any node collapsed ', function() {
            setTreeData(ctrl, [{
                hasChildren: true,
                expanded: false,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }]);

            expect(ctrl.isExpendAllEnabled()).toEqual(true);
        });

        it('expandAll should be disabled if all nodes are expanded', function() {
            setTreeData(ctrl, [{
                hasChildren: true,
                expanded: true,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }, {
                hasChildren: true,
                expanded: true,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }]);

            expect(ctrl.isExpendAllEnabled()).toEqual(false);
        });

        it('collapseAll should be enabled if there is any node expanded', function() {
            setTreeData(ctrl, [{
                hasChildren: true,
                expanded: true,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }]);

            expect(ctrl.isCollapseAllEnabled()).toEqual(true);
        });

        it('collapseAll should be disabled if all nodes are collapsed', function() {
            setTreeData(ctrl, [{
                hasChildren: true,
                expanded: false,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }, {
                hasChildren: true,
                expanded: false,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }]);

            expect(ctrl.isCollapseAllEnabled()).toEqual(false);
        });

        it('collapseAll should be enabled if first tree is collapsed but second is expanded', function() {
            setTreeData(ctrl, [{
                hasChildren: true,
                expanded: false,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }, {
                hasChildren: true,
                expanded: true,
                items: [{
                    hasChildren: false,
                    expanded: false
                }]
            }]);

            expect(ctrl.isCollapseAllEnabled()).toEqual(true);
        });

        it('collapseAll should be disabled if node does not have children but expanded', function() {
            setTreeData(ctrl, [{
                hasChildren: false,
                expanded: true
            }]);

            expect(ctrl.isCollapseAllEnabled()).toEqual(false);
        });
    });
});