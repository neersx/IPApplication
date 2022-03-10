describe('inprotech.configuration.rules.workflows.CreateEntries', function() {
    'use strict';

    var c, controller, service, modalInstance, notifications, promiseMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            service = test.mock('workflowsMaintenanceEntriesService');
            test.mock('modalService');
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            notifications = test.mock('notificationService');
            promiseMock = test.mock('promise');
        });


        inject(function($controller) {
            var defaultViewData = {
                canEditProtected: true,
                canEdit: true,
                hasOffices: true
            };

            controller = function(viewData) {
                return $controller('CreateEntriesController', {
                    viewData: _.extend(defaultViewData, viewData)
                });
            };
        });
    });

    it('should show notification if response has error', function() {
        c = controller({
            criteriaId: 1,
            insertAfterEntryId: 2
        });
        c.entryDescription = 'test';
        c.isSeparator = true;

        notifications.alert = promiseMock.createSpy();
        service.addEntryWorkflow = promiseMock.createSpy(true);
        service.addEntry = promiseMock.createSpy({
            data: {
                error: {
                    field: 'a',
                    message: 'test'
                }
            }
        });

        c.save();
        expect(service.addEntryWorkflow).toHaveBeenCalled();
        expect(service.addEntry).toHaveBeenCalledWith(1, 'test', true, 2, true);
        expect(notifications.alert).toHaveBeenCalled();
    });

    it('should show success and close modal', function() {
        c = controller({
            criteriaId: 1,
            insertAfterEntryId: 2
        });
        c.entryDescription = 'test';

        var response = {
            entryNo: 3,
            description: c.entryDescription,
            displaySequence: 2
        }

        notifications.success = promiseMock.createSpy();
        service.addEntryWorkflow = promiseMock.createSpy(true);
        service.addEntry = promiseMock.createSpy({
            data: response
        });

        c.save();
        expect(service.addEntryWorkflow).toHaveBeenCalled();
        expect(service.addEntry).toHaveBeenCalledWith(1, 'test', false, 2, true);
        expect(notifications.success).toHaveBeenCalled();
        expect(modalInstance.close).toHaveBeenCalledWith(response);
    });

    it('should show save Entry events if selected events are provided', function() {
        c = controller({
            criteriaId: 1,
            insertAfterEntryId: 2,
            selectedEvents: [{
                eventNo: 1,
                description: 'event 1'
            }, {
                eventNo: 2,
                description: 'event 2'
            }]
        });
        c.entryDescription = 'test';

        var response = {
            entryNo: 3,
            description: c.entryDescription,
            displaySequence: 2
        }

        notifications.success = promiseMock.createSpy();
        service.addEntryWorkflow = promiseMock.createSpy(true);
        service.addEntry = promiseMock.createSpy();

        service.addEntryEvents = promiseMock.createSpy({
            data: response
        });

        c.save();
        expect(service.addEntryWorkflow).toHaveBeenCalled();
        expect(service.addEntry).not.toHaveBeenCalled();
        expect(service.addEntryEvents).toHaveBeenCalledWith(1, 'test', [1, 2], true);
        expect(notifications.success).toHaveBeenCalled();
        expect(modalInstance.close).toHaveBeenCalledWith(response);
    });

    it('should validate the description provided', function() {
        c = controller({
            criteriaId: 1,
            insertAfterEntryId: 2
        });
        service.addEntryWorkflow = promiseMock.createSpy(true);

        c.entryDescription = '            ';
        c.isSeparator = false;
        c.form = {
            entryDescription: {
                $setValidity: jasmine.createSpy()
            }
        };

        c.save();

        expect(c.form.entryDescription.$setValidity).toHaveBeenCalledWith('required', false);
        expect(service.addEntryWorkflow).not.toHaveBeenCalled();
    });
});
