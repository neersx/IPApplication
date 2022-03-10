describe('DateLogicMaintenanceController', function() {
    'use strict';

    var scope, controller, modalInstance, workflowsEventControlService, maintModalService, notificationService;//, dateHelperService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.core');

        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            notificationService = test.mock('notificationService');
            workflowsEventControlService = test.mock('workflowsEventControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($rootScope, $controller/*, dateHelper*/) {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            //dateHelperService = dateHelper;
            controller = function(options) {
                var ctrl = $controller('DateLogicMaintenanceController', {
                    $scope: scope,
                    options: _.extend({}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
        it('initialises title for add mode', function() {
            var ctrl = controller({
                mode: 'add'
            });
            expect(ctrl.title).toBe('.addTitle');
        });

        it('initialises title for edit mode', function() {
            var ctrl = controller({
                mode: 'edit'
            });
            expect(ctrl.title).toBe('.editTitle');
        });

        it('initialises defaults', function() {
            var ctrl = controller({
                mode: 'add'
            });

            expect(ctrl.formData.appliesTo).toBe('Event');
            expect(ctrl.formData.compareType).toBe('Event');
            expect(ctrl.formData.ifRuleFails).toBe('Warn');
        });
    });

    describe('dismiss', function() {
        it('calls uibModalInstance dismiss', function() {
            var ctrl = controller();
            ctrl.dismiss();
            expect(modalInstance.dismiss).toHaveBeenCalled();
        });
    });

    describe('hasUnsavedChanges', function() {
        it('returns true when form is dirty', function() {
            var ctrl = controller();
            ctrl.form = {
                $dirty: true
            };
            expect(ctrl.hasUnsavedChanges()).toBe(true);

            ctrl.form.$dirty = false;
            expect(ctrl.hasUnsavedChanges()).toBe(false);
        });
    });

    describe('apply', function(){
        it('checks if form is valid', function() {
            var ctrl = controller();
            ctrl.form = {
                $validate: _.constant(false),
                $pristine: false,
                $dirty: true
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).not.toHaveBeenCalled();
            expect(maintModalService().applyChanges).not.toHaveBeenCalled();
        });
        
        it('calls service functions', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: 'dataItem'
            });
            ctrl.form = {
                $pristine: false,   // has edits
                $dirty: true,
                $validate: jasmine.createSpy().and.returnValue(true) // is valid
            };

            workflowsEventControlService.isDuplicated = jasmine.createSpy().and.returnValue(false);
            maintModalService.applyChanges = jasmine.createSpy();
            
            ctrl.apply();

            expect(workflowsEventControlService.isDuplicated).toHaveBeenCalled();
            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalled();
            //expect(maintModalService.applyChanges).toHaveBeenCalled();
        });
        
        it('fails with duplicates', function() {
            var dataItem1 = {
                appliesTo: 'appliesTo',
                operator: 'operator', 
                compareEvent: 'compareEvent', 
                compareType: 'compareType',
                relativeCycle: 'relativeCycle',
                caseRelationship: 'caseRelationship', 
                blockUserIfRuleFails: 'blockUserIfRuleFails'
            };

            var newItem = {
                appliesTo: 'appliesTo',
                operator: 'operator', 
                compareEvent: 'compareEvent', 
                compareType: 'compareType',
                relativeCycle: 'relativeCycle',
                caseRelationship: 'caseRelationship', 
                blockUserIfRuleFails: 'blockUserIfRuleFails'
            };

            var ctrl = controller({
                allItems: [dataItem1],
                dataItem: newItem
            });

            ctrl.form = {
                $validate: jasmine.createSpy().and.returnValue(true),
                $dirty: true
            };

            workflowsEventControlService.isDuplicated = jasmine.createSpy().and.returnValue(true);
            maintModalService.applyChanges = jasmine.createSpy();

            expect(ctrl.apply()).toBe(false);
            expect(notificationService.alert).toHaveBeenCalled();
        });        
    });

    describe('on navigate', function() {
        it('navigates if the form is pristine', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: 'dataItem'
            });
            ctrl.form = {
                $pristine: true,
                $validate: jasmine.createSpy().and.returnValue(false)
            };
            ctrl.apply = jasmine.createSpy();

            var result = ctrl.onNavigate();
            expect(result).toBe(true);
            expect(ctrl.form.$validate).not.toHaveBeenCalled();
            expect(ctrl.apply).not.toHaveBeenCalled();
        });

        it('applies changes automatically', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: 'dataItem'
            });
            ctrl.form = {
                $pristine: false,
                $validate: jasmine.createSpy().and.returnValue(false)
            };
            ctrl.apply = jasmine.createSpy();

            var result = ctrl.onNavigate(); 
            expect(result).toBe(false);
            expect(ctrl.form.$validate).toHaveBeenCalled(); // since not pristine, revalidate
            expect(ctrl.apply).not.toHaveBeenCalled();      // since still invalid, don't apply
        });
    });

    describe('eventPicklistScope', function() {
        it('should extend query for event picklist', function() {
            var ctrl = controller({
                criteriaId: 'criteriaId'
            });
            ctrl.eventPicklistScope.filterByCriteria = true;
            expect(workflowsEventControlService.initEventPicklistScope).toHaveBeenCalledWith({
                criteriaId: 'criteriaId',
                filterByCriteria: true
            });
        });
    });        
});