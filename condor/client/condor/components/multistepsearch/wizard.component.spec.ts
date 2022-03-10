module inprotech.components.multistepsearch {
    declare var test: any;

    describe('inprotech.components.multistepsearch.MultiStepSearchController', () => {
        'use strict';

        let stepsPersistenceSvc: StepsPersistenceServiceMock, options: any;
        let controller: (dependencies?: any) => MultiStepSearchController;

        beforeEach(() => {
            angular.mock.module('inprotech.components.multistepsearch');
            angular.mock.module(function () {
                stepsPersistenceSvc = test.mock('StepsPersistenceService', 'StepsPersistenceServiceMock');
            });
        });

        let c: MultiStepSearchController;
        beforeEach(inject(($rootScope: ng.IRootScopeService, $timeout, $interval) => {
            controller = function (dependencies?) {
                dependencies = angular.extend({
                    scope: $rootScope.$new()
                }, dependencies);
                return new MultiStepSearchController(dependencies.scope, stepsPersistenceSvc, $timeout, $interval);
            };
            let topics = {
                references: {
                    key: 'References',
                    title: 'caseSearch.topics.references.title',
                    template: '<ip-case-search-references data-topic="$topic" />',
                    getFormData: jasmine.createSpy('topic1Spy').and.returnValue({
                        abc: '123'
                    }),
                    discard: jasmine.createSpy(),
                    updateFormData: jasmine.createSpy()
                },
                details: {
                    key: 'Details',
                    title: 'caseSearch.topics.details.title',
                    template: '<ip-case-search-details data-topic="$topic" />',
                    getFormData: jasmine.createSpy('topic1Spy').and.returnValue({
                        abc: '123'
                    }),
                    discard: jasmine.createSpy(),
                    updateFormData: jasmine.createSpy()
                }
            };

            options = {
                topics: [topics.references, topics.details]
            };
        }));

        describe('initialize wizard', () => {
            it('should initialise operators', () => {
                c = controller();
                c.init();

                expect(c.operators).toEqual(['AND', 'OR', 'NOT']);
            });
            it('should initialise default initial steps', () => {
                c = controller();
                c.init();

                expect(c.steps.length).toBe(1);
                expect(c.steps[0].selected).toBe(true);
                expect(c.steps[0].isDefault).toBe(true);
                expect(c.steps[0].operator).toBe('');
                expect(c.steps[0].id).toBe(1);
            });
            it('should initialise topic options', () => {
                stepsPersistenceSvc.topicOptions = options;

                c = controller();
                c.init();

                expect(c.options).toBe(options);
            });
        });
        describe('remove steps in wizard', () => {
            it('should remove step', () => {
                c = controller();

                c.checkNavigation = jasmine.createSpy();
                c.goTo = jasmine.createSpy();

                c.init();

                // unselect first step
                c.steps[0].selected = false;

                let newStep = {
                    id: c.steps.length + 1,
                    operator: 'OR',
                    selected: true
                };

                // add new  step
                c.steps.push(newStep);

                c.removeStep(newStep);

                expect(c.steps.length).toBe(1);
                expect(c.checkNavigation).toHaveBeenCalled();
                expect(c.goTo).toHaveBeenCalled();
            });
        });
        describe('add steps in wizard', () => {
            it('should add step', () => {
                stepsPersistenceSvc.topicOptions = options;

                c = controller();

                c.checkNavigation = jasmine.createSpy();
                c.goTo = jasmine.createSpy();

                c.init();

                c.addStep();

                expect(stepsPersistenceSvc.applyStepData).toHaveBeenCalled();

                _.each(options.topics, (t: any) => {
                    expect(t.discard).toHaveBeenCalled();
                });

                expect(c.steps.length).toBe(2);
                expect(c.steps[1].selected).toBe(true);
                expect(c.steps[1].operator).toBe('OR');
                expect(c.steps[1].id).toBe(2);

                expect(c.checkNavigation).toHaveBeenCalled();
                expect(c.goTo).toHaveBeenCalled();
            });
        });
        describe('goto step in wizard', () => {
            it('should goto step', () => {
                stepsPersistenceSvc.topicOptions = options;

                c = controller();

                c.checkNavigation = jasmine.createSpy();
                c.scroll = jasmine.createSpy();

                c.init();

                let newStep = {
                    id: c.steps.length + 1,
                    operator: 'OR',
                    selected: true
                };

                // add new  step
                c.steps.push(newStep);

                c.goTo(newStep, false);

                _.each(options.topics, (t: any) => {
                    expect(t.updateFormData).toHaveBeenCalled();
                });

                expect(c.steps[0].selected).toBe(false);
                expect(c.steps[1].selected).toBe(true);
                expect(stepsPersistenceSvc.applyStepData).toHaveBeenCalled();
                expect(c.scroll).toHaveBeenCalled();
            });
        });
    });
}