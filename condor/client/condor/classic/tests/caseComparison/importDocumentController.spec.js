'use strict';

describe('Inprotech.CaseDataComparison.importDocumentController', function() {
    var fixture = {};

    beforeEach(function() {
        module('Inprotech.CaseDataComparison');

        module(function($provide) {
            $provide.value('notificationService', test.mock('notificationService'));

            $provide.value('$uibModalInstance', test.mock('ModalInstance'));
        });

        inject(function($controller, $rootScope, $location, $uibModalInstance, notificationService, $injector) {
            var httpBackend = $injector.get('$httpBackend');
            var rootScope = $injector.get('$rootScope');

            fixture = {
                location: $location,
                httpBackend: httpBackend,
                rootScope: rootScope,
                uibModalInstance: $uibModalInstance,
                notificationService: notificationService,
                controller: function() {
                    fixture.scope = $rootScope.$new();
                    return $controller('importDocumentController', {
                        $location: $location,
                        $scope: fixture.scope,
                        $uibModalInstance: $uibModalInstance,
                        notificationService: notificationService,
                        documentToImport: {
                            caseId: 999,
                            document: { id: 888 }
                        }
                    });
                }
            };
        })
    });

    afterEach(function() {
        fixture.httpBackend.verifyNoOutstandingExpectation();
        fixture.httpBackend.verifyNoOutstandingRequest();
    });

    it('should request import document', function() {
        fixture.httpBackend.whenGET('api/casecomparison/importDocument/999/888')
            .respond({ caseId: 999, documentId: 888, activityDate: 'foo', attachmentName: 'bar' });

        fixture.controller();

        fixture.httpBackend.expectGET('api/casecomparison/importDocument/999/888');

        fixture.httpBackend.flush();
    });

    it('should default cycle accordingly', function() {
        var form = {
            caseEvent: {
                $setValidity: function() {}
            }
        }
        fixture.httpBackend.whenGET('api/casecomparison/importDocument/999/888')
            .respond({
                caseId: 999,
                documentId: 888,
                activityDate: 'foo',
                attachmentName: 'bar',
                occurredEvents: [
                    { eventId: 1, cycle: 1 },
                    { eventId: 2, cycle: 2 }
                ]
            });

        fixture.controller();

        fixture.httpBackend.flush();

        fixture.scope.viewData.selectedEvent = fixture.scope.viewData.occurredEvents[0];
        fixture.scope.setCycle(form);

        expect(fixture.scope.attachment.cycle).toBe(1);

        fixture.scope.viewData.selectedEvent = null;
        fixture.scope.setCycle(form);

        expect(fixture.scope.attachment.cycle).toBe(null);

        fixture.scope.viewData.selectedEvent = fixture.scope.viewData.occurredEvents[1];
        fixture.scope.setCycle(form);

        expect(fixture.scope.attachment.cycle).toBe(2);
    });

    it('should prepare data to be saved', function() {
        var form = {
            caseEvent: {
                $setValidity: function() {}
            },
            $validate: function() {},
            $dirty: function() { return true; },
            $valid: function() { return true; }
        }

        fixture.httpBackend.whenGET('api/casecomparison/importDocument/999/888')
            .respond({
                caseId: 999,
                documentId: 888,
                activityDate: 'foo',
                attachmentName: 'bar',
                occurredEvents: [{ eventId: 1, cycle: 1 }],
                activityTypes: [{ id: 'activityTypes' }],
                categories: [{ id: 'categories' }],
                attachmentTypes: [{ id: 'attachmentTypes' }]
            });

        fixture.controller();

        fixture.httpBackend.flush();

        fixture.scope.viewData.selectedEvent = fixture.scope.viewData.occurredEvents[0];
        fixture.scope.setCycle(form);

        fixture.scope.viewData.selectedActivity = fixture.scope.viewData.activityTypes[0];
        fixture.scope.viewData.selectedCategory = fixture.scope.viewData.categories[0];
        fixture.scope.viewData.selectedAttachmentType = fixture.scope.viewData.attachmentTypes[0];

        fixture.httpBackend.whenPOST('api/casecomparison/importDocument/save')
            .respond(function() {

                var data = JSON.parse(arguments[2]);

                expect(data.caseId).toBe(999);
                expect(data.documentId).toBe(888);
                expect(data.eventId).toBe(1);
                expect(data.cycle).toBe(1);
                expect(data.activityTypeId).toBe('activityTypes');
                expect(data.categoryId).toBe('categories');
                expect(data.attachmentTypeId).toBe('attachmentTypes');

                return { result: { result: 'success' } };
            });

        fixture.scope.save(form);
        fixture.httpBackend.flush();
    });

    it('should set error returned from server', function() {
        var form = {
            caseEvent: {
                $setValidity: jasmine.createSpy()
            },
            $validate: jasmine.createSpy(),
            $dirty: function() { return true; },
            $valid: function() { return true; }
        }
        fixture.httpBackend.whenGET('api/casecomparison/importDocument/999/888')
            .respond({
                caseId: 999,
                documentId: 888,
                activityDate: 'foo',
                attachmentName: 'bar',
                occurredEvents: [{ eventId: 1, cycle: 1 }],
                activityTypes: [{ id: 'activityTypes' }],
                categories: [{ id: 'categories' }],
                attachmentTypes: [{ id: 'attachmentTypes' }]
            });

        fixture.controller();

        fixture.httpBackend.flush();

        fixture.scope.viewData.selectedEvent = fixture.scope.viewData.occurredEvents[0];
        fixture.scope.setCycle(form);

        fixture.scope.viewData.selectedActivity = fixture.scope.viewData.activityTypes[0];
        fixture.scope.viewData.selectedCategory = fixture.scope.viewData.categories[0];
        fixture.scope.viewData.selectedAttachmentType = fixture.scope.viewData.attachmentTypes[0];

        fixture.httpBackend.whenPOST('api/casecomparison/importDocument/save')
            .respond({ result: { result: 'invalid-cycle' } });

        fixture.scope.save(form);
        fixture.httpBackend.flush();

        expect(fixture.notificationService.alert).toHaveBeenCalled();
        expect(form.caseEvent.$setValidity).toHaveBeenCalledWith('eventError', false);
        expect(form.$validate).toHaveBeenCalled();
    });

    it('should set flag and return when save was successful', function() {
        var form = {
            caseEvent: {
                $setValidity: function() {}
            },
            $validate: function() {},
            $dirty: function() { return true; },
            $valid: function() { return true; }
        }
        fixture.httpBackend.whenGET('api/casecomparison/importDocument/999/888')
            .respond({
                caseId: 999,
                documentId: 888,
                activityDate: 'foo',
                attachmentName: 'bar',
                occurredEvents: [{ eventId: 1, cycle: 1 }],
                activityTypes: [{ id: 'activityTypes' }],
                categories: [{ id: 'categories' }],
                attachmentTypes: [{ id: 'attachmentTypes' }]
            });

        fixture.controller();

        fixture.httpBackend.flush();

        fixture.scope.viewData.selectedEvent = fixture.scope.viewData.occurredEvents[0];
        fixture.scope.setCycle(form);

        fixture.scope.viewData.selectedActivity = fixture.scope.viewData.activityTypes[0];
        fixture.scope.viewData.selectedCategory = fixture.scope.viewData.categories[0];
        fixture.scope.viewData.selectedAttachmentType = fixture.scope.viewData.attachmentTypes[0];

        fixture.httpBackend.whenPOST('api/casecomparison/importDocument/save')
            .respond({ result: { result: 'success' } });

        fixture.scope.save(form);

        fixture.httpBackend.flush();

        expect(fixture.scope.imported).toBe(true);
        expect(fixture.uibModalInstance.close).toHaveBeenCalled();
    });
});