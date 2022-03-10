describe('inprotech.configuration.rules.workflows.WorkflowsMaintenanceController', function() {
    'use strict';

    var controller, sharedService, stateService, notificationService, 
        workflowsMaintenanceService,modalService, promiseMock,
        workflowInheritanceService, store, rootScope;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            notificationService = test.mock('notificationService');
            workflowsMaintenanceService = test.mock('workflowsMaintenanceService');
            modalService = test.mock('modalService');
            promiseMock = test.mock('promise');
            stateService = test.mock('$state', 'stateMock');
            store = test.mock('store', 'storeMock');
            workflowInheritanceService = test.mock('workflowInheritanceService');
            
            store.local.get.returnValue = null;
            rootScope = {
                setPageTitlePrefix: jasmine.createSpy('setPageTitlePrefix').and.stub()
            };
        });
        
        inject(function($controller) {
            controller = function(viewData) {
                viewData = angular.extend({criteriaId: -1}, viewData);
    
                var c = $controller('WorkflowsMaintenanceController', {
                    viewData: viewData,
                    sharedService: sharedService || {},
                    notificationService: notificationService,
                    $rootScope: rootScope
                });
                c.$onInit();
                return c;
            };
        })
    });

    describe('initialise', function() {
        it('should initialise controller', function() {
            sharedService = {
                lastSearch: 'apples'
            };

            var viewData = {
                canEdit: true,
                criteriaId: 12345
            };
            var c = controller(viewData);
            expect(c.criteria.criteriaId).toBe(12345);
            expect(c.canEdit).toBe(true);
            expect(c.lastSearch).toBe('apples');
            expect(c.criteria).toEqual(viewData);
            expect(c.permissionAlertOptions).toEqual(viewData);
            expect(rootScope.setPageTitlePrefix).toHaveBeenCalled();
        });

        it('should call to set page title prefix', function(){
            var details = {
                criteriaId: 1111
           };
           controller(details);

           var prefix = details.criteriaId ;
           expect(rootScope.setPageTitlePrefix).toHaveBeenCalledWith(prefix, 'workflows.details');
        });
        
        it('should initialise actions if can edit', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });
            
            expect(c.options.actions.length).toEqual(2);
            expect(c.options.actions[0].disabled).toEqual(false);
            expect(c.options.actions[0].tooltip).toEqual(null);

            expect(c.options.actions[1].disabled).toEqual(false);
            expect(c.options.actions[1].tooltip).toEqual(null);
        });

        it('should not initialise actions if cannot edit', function() {
            var c = controller({
                canEdit: false,
                isInherited: true
            });
            
            expect(c.options.actions.length).toEqual(0);
        });

        it('should disable reset inheritance if cannot reset', function() {
            var c = controller({
                canEdit: true,
                isInherited: false
            });

            expect(c.options.actions[0].disabled).toEqual(true);
            expect(c.options.actions[0].tooltip).not.toEqual(null);
        });
        it('should set the lastSearch from the local store and set the methodname to search', function () {
            var args = ['1', '2'];
            store.local.get.returnValue = args;
            sharedService = {
                lastSearch: undefined
            };
            var viewData = {
                id: 'PCT',
                type: '1'
            };
            var c = controller({
                viewData: viewData
            });            
            expect(c.lastSearch.methodName).toBe('search'); 
            expect(c.lastSearch.args[0]).toBe('1'); 
            expect(c.lastSearch.args[1]).toBe('2');         
        });
        it('should set the lastSearch from the local store and set the methodname to searchByIds', function () {
            var args = [['1', '2', '3'], '2'];
            store.local.get.returnValue = args;
            sharedService = {
                lastSearch: undefined
            };
            var viewData = {
                id: 'PCT',
                type: '1'
            };
            var c = controller({
                viewData: viewData
            });
            store.local.get.returnValue = args;
            expect(c.lastSearch.methodName).toBe('searchByIds'); 
            expect(c.lastSearch.args[0][0]).toBe('1'); 
            expect(c.lastSearch.args[0][1]).toBe('2'); 
            expect(c.lastSearch.args[0][2]).toBe('3'); 
            expect(c.lastSearch.args[1]).toBe('2');         
        });
    });
    
    describe('reset inheritance action', function() {
        it('should check for descendants and reset criteria', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });
            var parent = {id:1};
            var descendants = [{id:2},{id:3}];
            workflowsMaintenanceService.getDescendants = promiseMock.createSpy({parent: parent, descendants: descendants});
            workflowsMaintenanceService.resetWorkflow = promiseMock.createSpy({status:'success'});
            modalService.open = promiseMock.createSpy(true);

            c.options.actions[0].action();

            expect(workflowsMaintenanceService.getDescendants).toHaveBeenCalled();
            expect(modalService.open).toHaveBeenCalledWith('InheritanceResetConfirmation', null, {
                    viewData: {
                        criteriaId: -1,
                        items: descendants,
                        parent: parent,
                        context: 'criteria'
                    }
                });
            expect(workflowsMaintenanceService.resetWorkflow).toHaveBeenCalledWith(-1, true);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
        });

        it('should ask to update due date responsible name if required', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });
            var parent = {id:1};
            var descendants = [];
            workflowsMaintenanceService.getDescendants = promiseMock.createSpy({parent: parent, descendants: descendants});
            workflowsMaintenanceService.resetWorkflow = promiseMock.createSpy({status:'updateNameRespOnCases'});
            modalService.openModal = promiseMock.createSpy(true);
            modalService.open = promiseMock.createSpy(true);

            c.options.actions[0].action();

            expect(modalService.openModal).toHaveBeenCalledWith({ id: 'ChangeDueDateRespConfirm', preSave: true });
            expect(workflowsMaintenanceService.resetWorkflow).toHaveBeenCalledWith(-1, true, true);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
        });
    });

    describe('break inheritance action', function() {
        it('should get parent and break inheritance', function() {
            var c = controller({
                canEdit: true,
                isInherited: true
            });
            var parent = {id:1};
            workflowsMaintenanceService.getParent = promiseMock.createSpy(parent);
            modalService.openModal = promiseMock.createSpy();
            workflowInheritanceService.breakInheritance = promiseMock.createSpy();

            c.options.actions[1].action();

            expect(workflowsMaintenanceService.getParent).toHaveBeenCalledWith(-1);
            expect(modalService.openModal).toHaveBeenCalledWith({
                id: 'InheritanceBreakConfirmation',
                parent: parent,
                criteriaId: -1,
                context: 'criteria'
            });
            expect(workflowInheritanceService.breakInheritance).toHaveBeenCalledWith(-1);
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
        });
    });
});