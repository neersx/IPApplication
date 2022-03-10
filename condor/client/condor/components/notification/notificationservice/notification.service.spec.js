describe('notification service inprotech.components.notification.notificationService', function() {
    'use strict';

    beforeEach(module('inprotech.components'));

    var service, modalsvc;
    beforeEach(inject(function(notificationService, modalService) {
        service = notificationService;
        modalsvc = modalService;
    }));

    describe('modal dialog', function() {
        it('should open for discard changes', function() {
            spyOn(modalsvc, 'open');
            service.discard();

            var args = modalsvc.open.calls.mostRecent().args;
            expect(args[0]).toEqual('DiscardChanges');
        });

        it('should open for alert', function() {
            spyOn(modalsvc, 'open');
            service.alert({
                messageParams: 1,
                actionMessage: 'a'
            });
            var args = modalsvc.open.calls.mostRecent().args;
            var options = args[2].options();

            expect(args[0]).toEqual('Alert');
            expect(options.title).toEqual('modal.unableToComplete');          
            expect(options.message).toEqual('modal.alert.message');
            expect(options.okButton).toEqual('button.ok');
            expect(options.messageParams).toEqual(1);
            expect(options.actionMessage).toEqual('a');

            service.alert({
                title: 'Error',
                message: 'Error',
                okButton: 'Cancel',
                messageParams: 1,
                actionMessage: 'a'
            });

            args = modalsvc.open.calls.mostRecent().args;
            options = args[2].options();
            expect(args[0]).toEqual('Alert');
            expect(options.title).toEqual('Error');            
            expect(options.message).toEqual('Error');
            expect(options.okButton).toEqual('Cancel');
            expect(options.messageParams).toEqual(1);
            expect(options.actionMessage).toEqual('a');
        });

        it('should open for confirm', function() {
            var options = {
                message: 'confirm'
            };

            spyOn(modalsvc, 'open');
            service.confirm(options);

            var args = modalsvc.open.calls.mostRecent().args;
            expect(args[0]).toEqual('Confirm');
            expect(args[2].options().message).toEqual(options.message);
        });

        it('should open for unsaved changes', function() {
            var options = {
                message: 'unsaved'
            };

            spyOn(modalsvc, 'open');
            service.unsavedchanges(options);

            var args = modalsvc.open.calls.mostRecent().args;
            expect(args[0]).toEqual('UnsavedChanges');
            expect(args[2].options().message).toEqual(options.message);
        });
    });
});
