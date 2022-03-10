describe('MaintenanceModalHeaderComponent', function() {

    var rootScope, $componentController, notificationService;

    beforeEach(function() {
        module('inprotech.components.modal')
        module(function() {
            notificationService = test.mock('notificationService');
        });
    });

    beforeEach(inject(function(_$componentController_, _$rootScope_) {
        $componentController = _$componentController_;
        rootScope = _$rootScope_;
    }));

    describe('closing modal', function() {
        it('shows discard confirmation when dirty', function() {

            var bindings = {
                hasUnsavedChanges: jasmine.createSpy().and.returnValue(true),
                dismiss: jasmine.createSpy()
            };

            var ctrl = $componentController('ipMaintenanceModalHeader', {$attrs: {}}, bindings);

            notificationService.discard.confirmed = true;

            ctrl.doClose();

            expect(ctrl.hasUnsavedChanges).toHaveBeenCalled();
            expect(notificationService.discard).toHaveBeenCalled();
            expect(ctrl.dismiss).toHaveBeenCalled();
        });

        it('dismisses immediately when no unsaved changes', function() {

            var bindings = {
                hasUnsavedChanges: jasmine.createSpy().and.returnValue(false),
                dismiss: jasmine.createSpy()
            };

            var ctrl = $componentController('ipMaintenanceModalHeader', {$attrs: {}}, bindings);

            notificationService.discard.confirmed = true;

            ctrl.doClose();

            expect(ctrl.hasUnsavedChanges).toHaveBeenCalled();
            expect(notificationService.discard).not.toHaveBeenCalled();
            expect(ctrl.dismiss).toHaveBeenCalled();
        });

        it('asks to discard changes when hitting escape key', function() {
            var ctrl = $componentController('ipMaintenanceModalHeader', {$attrs: {}}, null);
            ctrl.doClose = jasmine.createSpy();

            rootScope.$broadcast('modal.closing', 'escape key press');

            expect(ctrl.doClose).toHaveBeenCalled();
        });
    });
});
