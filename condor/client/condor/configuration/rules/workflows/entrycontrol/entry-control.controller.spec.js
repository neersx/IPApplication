describe('inprotech.configuration.rules.workflows.entrycontrol.WorkflowsEntryControlController', function() {
    'use strict';

    var controller, service, topics, notificationService, modalService, promiseMock, maintenanceService,
        maintenanceEntriesService, stateService, busService, rootScope;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows']);

            maintenanceEntriesService = $injector.get('workflowsMaintenanceEntriesServiceMock');
            $provide.value('workflowsMaintenanceEntriesService', maintenanceEntriesService);

            maintenanceService = test.mock('workflowsMaintenanceService');
            service = test.mock('workflowsEntryControlService');
            notificationService = test.mock('notificationService');
            modalService = test.mock('modalService', 'modalServiceMock');
            stateService = test.mock('$state', 'stateMock');
            busService = test.mock('bus', 'BusMock');
            promiseMock = test.mock('promise');
            rootScope = {
                setPageTitlePrefix: jasmine.createSpy('setPageTitlePrefix').and.stub()
            }
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(extendData) {
            var data = {
                criteriaId: -1,
                entryId: 1,
                canEdit: true,
                candDelete: true
            };
            _.extend(data, extendData);

            var returnController = $controller('WorkflowsEntryControlController', {
                $scope: {},
                viewData: data,
                $rootScope: rootScope
            });
            returnController.$onInit();
            topics = returnController.$topics;
            return returnController;
        }
    }));

    describe('initialise', function() {
        it('should initialise controller', function() {
            maintenanceEntriesService.entryIds.returnValue = [123];
            var c = controller();

            expect(c.entryControl.canEdit).toEqual(true);
            expect(c.workflowEntryIds).toEqual([123]);

            expect(c.canEdit).toEqual(true);
            expect(c.isSaveEnabled).toBeDefined();
            expect(c.isDiscardEnabled).toBeDefined();
            expect(c.isDeleteEnabled).toBeDefined();

            expect(c.discard).toBeDefined();
            expect(c.save).toBeDefined();
            expect(c.delete).toBeDefined();
            expect(rootScope.setPageTitlePrefix).toHaveBeenCalled();
        });

        it('should call to set page title prefix', function(){
            var details = {
                description: 'entry description',
                criteriaId: 1111
           };
           controller(details);

           var prefix = details.criteriaId + ' (' + details.description + ')';
           expect(rootScope.setPageTitlePrefix).toHaveBeenCalledWith(prefix, 'workflows.details.entrycontrol');
        });

        it('should initialise user access if showUserAccess true', function() {
            var c = controller({
                showUserAccess: true
            });
            expect(c.$topics.userAccess).toBeDefined();
            expect(c.topicOptions.topics).toContain(c.$topics.userAccess);
        });

        it('should not initialise user access if showUserAccess false', function() {
            var c = controller({
                showUserAccess: false
            });
            expect(c.$topics.userAccess).not.toBeDefined();
            expect(c.topicOptions.topics).not.toContain(c.$topics.userAccess);
        });

        it('should not initialise topics for separators', function() {
            var c = controller({
                isSeparator: true
            });
            expect(c.topicOptions.topics).toEqual([c.$topics.definition]);
        });
    });

    describe('enable buttons', function() {
        describe('for details section', function() {
            var c;
            beforeEach(function() {
                c = controller();
                c.topicOptions.topics = [c.$topics.details];
            })
            it('should enable save if no error and dirty', function() {
                topics.details.initialised = _.constant(true);
                topics.details.hasError = _.constant(false);
                topics.details.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(true);

                topics.details.hasError = _.constant(true);
                topics.details.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(false);

                topics.details.hasError = _.constant(false);
                topics.details.isDirty = _.constant(false);
                expect(c.isSaveEnabled()).toBe(false);
            });

            it('should enable discard when dirty', function() {
                topics.details.initialised = _.constant(true);
                topics.details.isDirty = _.constant(true);
                expect(c.isDiscardEnabled()).toBe(true);
            });

            it('should always enable delete when initialised', function() {
                expect(c.isDeleteEnabled()).toBe(false);

                topics.details.initialised = _.constant(true);
                expect(c.isDeleteEnabled()).toBe(true);
            });
        });

        describe('for definitions section', function() {
            var c;
            beforeEach(function() {
                c = controller();
                c.topicOptions.topics = [c.$topics.definition];
            })
            it('should enable save if no error and dirty', function() {
                topics.definition.initialised = _.constant(true);
                topics.definition.hasError = _.constant(false);
                topics.definition.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(true);

                topics.definition.hasError = _.constant(true);
                topics.definition.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(false);

                topics.definition.hasError = _.constant(false);
                topics.definition.isDirty = _.constant(false);
                expect(c.isSaveEnabled()).toBe(false);
            });

            it('should enable discard when dirty', function() {
                topics.definition.initialised = _.constant(true);
                topics.definition.isDirty = _.constant(true);
                expect(c.isDiscardEnabled()).toBe(true);

                topics.definition.isDirty = _.constant(false);
                expect(c.isDiscardEnabled()).toBe(false);
            });
        });

        describe('multiple section', function() {
            var c;
            beforeEach(function() {
                c = controller();
                c.topicOptions.topics = [c.$topics.definition, c.$topics.details, c.$topics.displayConditions];
                _.each(_.keys(topics), function(key) {
                    topics[key].initialised = _.constant(true);
                    topics[key].hasError = _.constant(false);
                    topics[key].isDirty = _.constant(false);
                });
            })
            it('should enable save if no error and dirty', function() {
                topics.details.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(true);

                topics.definition.hasError = _.constant(true);
                topics.details.hasError = _.constant(false);

                topics.definition.isDirty = _.constant(true);
                topics.details.isDirty = _.constant(true);
                expect(c.isSaveEnabled()).toBe(false);

                topics.definition.hasError = _.constant(false);
                topics.details.hasError = _.constant(false);

                topics.definition.isDirty = _.constant(false);
                topics.details.isDirty = _.constant(false);
                expect(c.isSaveEnabled()).toBe(false);
            });

            it('should enable discard when dirty', function() {

                topics.definition.isDirty = _.constant(true);
                expect(c.isDiscardEnabled()).toBe(true);

                topics.definition.isDirty = _.constant(false);
                topics.details.isDirty = _.constant(true);
                expect(c.isDiscardEnabled()).toBe(true);

                topics.definition.isDirty = _.constant(false);
                topics.details.isDirty = _.constant(false);
                expect(c.isDiscardEnabled()).toBe(false);
            });
        });
    });

    describe('save', function() {
        var c;

        it('should save changes and perform post save tasks', function() {
            setupController();
            service.updateDetail = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });
            c.save();

            expect(topics.details.getFormData).toHaveBeenCalled();
            expect(service.updateDetail).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(busService.channel).toHaveBeenCalledWith('gridRefresh.entriesResults');
        });

        it('should show message if has parent', function() {
            setupController(true);
            service.updateDetail = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });
            c.save();

            expect(notificationService.confirm).toHaveBeenCalledWith(jasmine.objectContaining({
                messages: ['workflows.entrycontrol.breakInheritanceConfirmation', 'workflows.entrycontrol.doYouWantToProceed']
            }));
            expect(modalService.open).not.toHaveBeenCalled();
            expect(topics.details.getFormData).toHaveBeenCalled();
            expect(service.updateDetail).toHaveBeenCalledWith(-1, 1, jasmine.objectContaining({
                applyToDescendants: false
            }));
        });

        it('should show message if has children and pass apply to descendants', function() {
            setupController(false, true);
            var descendent1 = {
                id: 1,
                description: "test"
            };
            var breaking1 = {
                id: 2,
                description: "test2"
            };

            modalService.open = promiseMock.createSpy(true);
            service.getDescendants = promiseMock.createSpy({
                data: {
                    descendants: [descendent1],
                    breaking: [breaking1]
                }
            });
            service.updateDetail = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });

            c.save();

            expect(notificationService.confirm).not.toHaveBeenCalledWith(jasmine.objectContaining({
                messages: ['workflows.entrycontrol.breakInheritanceConfirmation', 'workflows.entrycontrol.doYouWantToProceed']
            }));
            expect(modalService.open).toHaveBeenCalledWith('EntryInheritanceConfirmation', null, {
                viewData: {
                    items: [descendent1],
                    breakingItems: [breaking1]
                }
            });
            expect(topics.details.getFormData).toHaveBeenCalled();
            expect(service.updateDetail).toHaveBeenCalledWith(-1, 1, jasmine.objectContaining({
                applyToDescendants: true
            }));
        });

        it('should apply save and display success, if save is successful', function() {
            setupController(true);
            service.updateDetail = promiseMock.createSpy({
                data: {
                    status: 'success'
                }
            });

            c.save();

            expect(service.updateDetail).toHaveBeenCalled();
            expect(notificationService.success).toHaveBeenCalled();
            expect(stateService.reload).toHaveBeenCalled();
        });

        it('should apply error and display alert, if save is unsuccessful', function() {
            setupController(true);
            var errorForDefinition = {
                topic: 'definition'
            };
            var errorForDetail = {
                topic: 'details'
            };
            service.updateDetail = promiseMock.createSpy({
                data: {
                    status: 'error',
                    errors: [
                        errorForDefinition,
                        errorForDetail
                    ]
                }

            });

            c.save();

            expect(service.updateDetail).toHaveBeenCalled();
            expect(stateService.reload).not.toHaveBeenCalled();

            expect(topics.details.setError).toHaveBeenCalledWith([errorForDetail]);
            expect(topics.definition.setError).toHaveBeenCalledWith([errorForDefinition]);

            expect(notificationService.alert).toHaveBeenCalledWith({
                title: 'modal.unableToComplete',
                message: 'workflows.entrycontrol.saveError'
            });
        });

        function setupController(hasParent, hasChildren) {
            c = controller({
                hasParent: hasParent,
                hasChildren: hasChildren
            });

            _.each(_.keys(topics), function(key) {
                topics[key].getFormData = jasmine.createSpy().and.returnValue({});
                topics[key].setError = jasmine.createSpy();
            });
        }
    });

    describe('delete', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.workflowEntryIds = [123];
            var confirmationMock = { applyToDescendants: false };
            maintenanceEntriesService.confirmDeleteWorkflow = promiseMock.createSpy(confirmationMock);
        });

        it('should delete the entry', function() {
            c.delete();

            expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalled();
            expect(stateService.go).toHaveBeenCalled();
        });

        it('should broadcast a message to the entries grid to refresh', function() {
            c.delete();

            expect(busService.channel).toHaveBeenCalledWith('gridRefresh.entriesResults');
            expect(busService.channel().broadcast).toHaveBeenCalled();
        });

        it('should show message if has parent', function() {
            c.delete();

            expect(modalService.open).not.toHaveBeenCalled();

            expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalledWith(-1, [1], false);
        });

        it('should show message if has children and pass apply to descendants', function() {
            var confirmationMock = { applyToDescendants: true };
            maintenanceEntriesService.confirmDeleteWorkflow = promiseMock.createSpy(confirmationMock);
            c.delete();
            expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalledWith(-1, [1], true);
        });

        describe('navigation after delete', function() {
            beforeEach(function() {
                c.workflowEntryIds = [-5, 0, 1, 2, 3];
            });

            it('should move to next item after deletion', function() {
                c.delete();

                expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalled();
                expect(stateService.go).toHaveBeenCalledWith('workflows.details.entrycontrol', {
                    entryId: 2
                }, { location: 'replace' });
                expect(c.workflowEntryIds.length).toEqual(4);
            });

            it('should move to previous item if last one is deleted', function() {
                c.delete();

                expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalled();
                expect(stateService.go).toHaveBeenCalledWith('workflows.details.entrycontrol', {
                    entryId: 2
                }, { location: 'replace' });
                expect(c.workflowEntryIds.length).toEqual(4);
            });

            it('should move to Criteria detail page if only entry is deleted', function() {
                c.workflowEntryIds = [1];

                c.delete();

                expect(maintenanceEntriesService.deleteEntries).toHaveBeenCalled();
                expect(stateService.go).toHaveBeenCalledWith('^', null, { location: 'replace' });
            });
        });
    });

    describe('Reset and Break Inheritance', function() {
        var c;
        describe('Reset', function() {
            var key = 'resetInheritance';
            it('should only show Reset Action if User has edit permission', function() {
                setupController({
                    canEdit: false
                });

                expect(getAction(key)).not.toBeDefined();

                setupController();
                expect(getAction(key)).toBeDefined();
            });

            it('should only enable Reset Action if has parent entry', function() {
                setupController({
                    hasParentEntry: false
                });

                expect(getAction(key).disabled).toEqual(true);

                setupController({
                    hasParentEntry: true
                });
                expect(getAction(key).disabled).toEqual(false);
            });

            it('should reset the entry', function() {
                setupController({
                    hasChildren: false
                });
                modalService.open = promiseMock.createSpy({
                    applyToDescendants: false
                });
                getAction(key).action();
                expect(modalService.open).toHaveBeenCalled();
                expect(service.resetEntry).toHaveBeenCalledWith(-1, 1, {
                    applyToDescendants: false
                });
                expect(notificationService.success).toHaveBeenCalled();
                expect(stateService.reload).toHaveBeenCalled();
            });

            it('should show message if has children and pass apply to descendants', function() {
                setupController();

                modalService.open = promiseMock.createSpy({
                    applyToDescendants: true
                });

                getAction(key).action();


                expect(modalService.open).toHaveBeenCalled();

                expect(service.resetEntry).toHaveBeenCalledWith(-1, 1, {
                    applyToDescendants: true
                });
            });
        });


        describe('Break', function() {
            var key = 'breakInheritance';
            it('should only show Break Inheritance Action if User has edit permission', function() {
                setupController({
                    canEdit: false
                });

                expect(getAction(key)).not.toBeDefined();

                setupController();
                expect(getAction(key)).toBeDefined();
            });

            it('should only enable Break Inheritance Action if has parent entry', function() {
                setupController({
                    hasParentEntry: true,
                    isInherited: true
                });

                expect(getAction(key).disabled).toEqual(false);

                setupController({
                    hasParentEntry: true,
                    isInherited: false
                });
                expect(getAction(key).disabled).toEqual(true);

                setupController({
                    hasParentEntry: false,
                    isInherited: true
                });
                expect(getAction(key).disabled).toEqual(true);
            });

            it('should only enable Break Action if inherited', function() {
                setupController({
                    hasParentEntry: true,
                    isInherited: false
                });

                expect(getAction(key).disabled).toEqual(true);

                setupController({
                    hasParentEntry: false,
                    isInherited: true
                });
                expect(getAction(key).disabled).toEqual(true);

                setupController({
                    hasParentEntry: true,
                    isInherited: true
                });
                expect(getAction(key).disabled).toEqual(false);
            });


            it('should Break Inheritance for the entry', function() {
                setupController({
                    hasChildren: false,
                    isInherited: true,
                    hasParentEntry: true
                });
                modalService.openModal = promiseMock.createSpy();
                var parent = { id: 99 };
                maintenanceService.getParent = promiseMock.createSpy(parent);

                getAction(key).action();

                expect(maintenanceService.getParent).toHaveBeenCalledWith(-1);

                expect(modalService.openModal).toHaveBeenCalledWith({
                    id: 'InheritanceBreakConfirmation',
                    parent: parent,
                    context: 'entrycontrol'
                });

                expect(service.breakEntryInheritance).toHaveBeenCalledWith(-1, 1);
                expect(notificationService.success).toHaveBeenCalled();
                expect(stateService.reload).toHaveBeenCalled();
            });

        });

        function getAction(key) {
            return _.find(c.topicOptions.actions, function(a) {
                return a.key === key;
            });
        }

        function setupController(extend) {
            var data = {
                hasParent: true,
                hasChildren: true,
                canEdit: true,
                hasParentEntry: true,
                inheritanceLevel: 'Full'
            };

            maintenanceEntriesService.entryIds.returnValue = [123];
            _.extend(data, extend)
            c = controller(data);

            _.each(_.keys(topics), function(key) {
                topics[key].getFormData = jasmine.createSpy().and.returnValue({});
                topics[key].setError = jasmine.createSpy();
            });

            var descendents = [];
            if (data.hasChildren) {
                descendents = [{
                    id: 1,
                    description: "test"
                }];
            }
            service.getDescendantsAndParentWithInheritedEntry = promiseMock.createSpy({
                descendents: descendents,
                parent: {
                    id: 0,
                    description: "parent"
                }
            });
            service.resetEntry = promiseMock.createSpy();
            service.breakEntryInheritance = promiseMock.createSpy();
        }
    });

});