describe('inprotech.configuration.rules.workflows.workflowsMaintenanceEntriesService', function() {
    'use strict';

    var service, httpMock, modalService, promiseMock, notificationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);

            promiseMock = test.mock('promise');
            notificationService = test.mock('notificationService');
        });

        inject(function(workflowsMaintenanceEntriesService) {
            service = workflowsMaintenanceEntriesService;
        });
    });

    it('should get and set entry ids from entryNo', function() {
        service.entryIds([{
            entryNo: -10,
            description: 'abc'
        }, {
            entryNo: -20,
            description: 'def'
        }]);

        expect(service.entryIds()).toEqual([-10, -20]);
    });

    it('should open Create Entry Modal', function() {
        modalService.open = promiseMock.createSpy();
        var params = {
            scope: {},
            criteriaId: 1,
            insertAfterEntryId: 1
        }
        service.showCreateEntryModal(params.scope, params.criteriaId, params.insertAfterEntryId);
        expect(modalService.open).toHaveBeenCalled();
    });

    describe('Add Entry Workflow', function() {
        var entryDescription;

        beforeEach(function() {
            entryDescription = 'test';
        });

        it('should pop up confirmation warning for affecting inherited entries', function() {
            service.getDescendantsWithoutEntry = promiseMock.createSpy([{}, {}]);
            service.showInheritanceConfirmationModal = promiseMock.createSpy(true);

            var inheritFlag = service.addEntryWorkflow(1, entryDescription, false, null);

            expect(service.getDescendantsWithoutEntry).toHaveBeenCalledWith(1, entryDescription, false);
            expect(service.getDescendantsWithoutEntry.then).toHaveBeenCalled();
            expect(service.showInheritanceConfirmationModal).toHaveBeenCalled();

            expect(inheritFlag.data).toBe(true);
        });

        it('should not invoke modal if there are no descendants', function() {
            spyOn(service, 'showInheritanceConfirmationModal');
            service.addEntry = promiseMock.createSpy();
            service.getDescendantsWithoutEntry = promiseMock.createSpy([]);

            var result = service.addEntryWorkflow(1, entryDescription, null);

            expect(service.getDescendantsWithoutEntry).toHaveBeenCalledWith(1, entryDescription, null);
            expect(service.getDescendantsWithoutEntry.then).toHaveBeenCalled();
            expect(service.showInheritanceConfirmationModal).not.toHaveBeenCalled();
            expect(result.data).toBe(false);
        });
    });

    describe('apis', function() {
        it('getEntries should pass correct parameters', function() {
            service.getEntries(-1, 1);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/entries', {
                params: {
                    params: '1'
                }
            });
        });

        it('reorderEvent pass correct parameters', function() {
            service.reorderEntry(123, 1, 2, 3);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/123/entries/reorder', {
                sourceId: 1,
                targetId: 2,
                insertBefore: 3
            });
        });

        it('reorderDescendants pass correct parameters', function() {
            service.reorderDescendantsEntry(123, 1, 2, 3, 4, 5);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/123/entries/descendants/reorder', {
                sourceId: 1,
                targetId: 2,
                prevTargetId: 3,
                nextTargetId: 4,
                insertBefore: 5
            });
        });

        it('searchEntries should pass correct parameters', function() {
            service.searchEntryEvents(-1, 1);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/entryEventSearch?eventId=1');
        });

        it('addEntry should pass correct parameters', function() {
            service.addEntry(-1, 'Test Entry',false, 12, true);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/entries',{
                entryDescription: 'Test Entry',
                isSeparator: false,
                insertAfterEntryId: 12,
                applyToChildren: true
            });
        });

        it('confirmDeleteWorkflow should pass correct parameters to getDescendantsWithInheritedEntry', function() {
            httpMock.get.returnValue = promiseMock.createSpy([]);
            var entryIds = [10, 9];
            service.confirmDeleteWorkflow({}, 100, entryIds);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/100/entries/descendants?withInheritedEntryIds=' + JSON.stringify(entryIds));
        });

        it('deleteEntries should pass correct parameters', function() {
            var entryIds = [10, 9];
            service.deleteEntries(100, entryIds, true);
            expect(httpMock.delete).toHaveBeenCalledWith('api/configuration/rules/workflows/100/entries?entryIds=' + JSON.stringify(entryIds) + '&appliesToDescendants=true');
        });

        it('addEntryEvents should pass correct parameters', function() {
            service.addEntryEvents(-1, 'Test Entry', [12, 13, 14], true);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventsentry?entryDescription=Test%20Entry&applyToChildren=true', [12, 13, 14]);

        });
    });

    describe('delete entries ', function() {
        describe('confirmDeleteWorkflow', function() {
            it('confirms delete inherited entries from descendants', function() {
                service.getDescendantsWithInheritedEntry = promiseMock.createSpy([10, 20]);

                service.confirmDeleteWorkflow({}, 123, [1, 2]);

                expect(service.getDescendantsWithInheritedEntry).toHaveBeenCalledWith(123, [1, 2]);
                var args = modalService.open.calls.first().args;
                expect(args[0]).toBe('InheritanceDeleteConfirmation');
                expect(args[1]).toEqual({});
                expect(args[2].items().descendants).toEqual([10, 20]);
                expect(args[2].items().selectedCount).toEqual(2);
            });

            it('confirms delete when no inherited events', function() {
                service.getDescendantsWithInheritedEntry = promiseMock.createSpy();

                service.confirmDeleteWorkflow({}, 123, [1, 2]);

                expect(service.getDescendantsWithInheritedEntry).toHaveBeenCalledWith(123, [1, 2]);

                expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                    message: 'workflows.maintenance.deleteConfirmationEntry.messageMultiple',
                    messageParams: {
                        count: 2
                    }
                });
            });

            it('displays the confirmation, even if single entry is selected for delete', function(){
                httpMock.get.returnValue = promiseMock.createSpy([]);
                service.confirmDeleteWorkflow({}, 123, [1]);
                expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                    message: 'workflows.maintenance.deleteConfirmationEntry.messageIndividual',
                    messageParams: {
                        count: 1
                    }
                });
            });
        });
    });
});
