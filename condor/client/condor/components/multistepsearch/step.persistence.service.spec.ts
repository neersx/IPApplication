module inprotech.components.multistepsearch {
    describe('inprotech.components.multistepsearch', function () {
        'use strict';

        let service: StepsPersistenceService, topics: any, options: any, firstStep: Array<any>, expectedFormData: any;

        beforeEach(() => {
            angular.mock.module('inprotech.components.multistepsearch');
        });

        beforeEach(inject((StepsPersistenceService) => {
            service = StepsPersistenceService;
            topics = {
                references: {
                    key: 'References',
                    title: 'caseSearch.topics.references.title',
                    template: '<ip-case-search-references data-topic="$topic" />',
                    getFormData: jasmine.createSpy('topic1Spy').and.returnValue({
                        abc: '123'
                    })
                },
                details: {
                    key: 'Details',
                    title: 'caseSearch.topics.details.title',
                    template: '<ip-case-search-details data-topic="$topic" />',
                    getFormData: jasmine.createSpy('topic1Spy').and.returnValue({
                        abc: '123'
                    })
                }
            };

            options = {
                topics: [topics.references, topics.details]
            };

            firstStep = new Array();
            firstStep.push({
                id: 1,
                isDefault: true,
                operator: '',
                selected: true
            });

            expectedFormData = {
                caseListOperator: '0',
                caseNameReferenceOperator: '2',
                caseNameReferenceType: 'I',
                caseReferenceOperator: '2',
                familyOperator: '0',
                isPrimeCasesOnly: 0,
                officialNumberOperator: '0',
                searchNumbersOnly: false,
                searchRelatedCases: false,
                yourReferenceOperator: '2'
            };

        }));

        describe('serviceInitData', function () {
            it('should default step and topic form data', function () {
                expect(service.steps.length).toEqual(0);
                expect(service.topicOptions.length).toEqual(0);
                expect(service.topicsFormData.length).toEqual(0);
            });
        });

        describe('applyStepData', function () {
            it('should add record to persistence step data', function () {
                service.applyStepData(firstStep[0], topics, firstStep);

                expect(service.steps.length).toEqual(1);
            });
            it('should add new step', function () {

                service.applyStepData(firstStep[0], topics, firstStep);

                firstStep[0].selected = false;
                firstStep.push({
                    id: 2,
                    isDefault: true,
                    operator: '',
                    selected: true
                });

                service.applyStepData(firstStep[1], topics, firstStep);

                expect(service.steps[0].topicsData).toEqual(service.steps[1].topicsData);
            });
        });

        describe('persistDefaultOptions', function () {
            it('should persist default topic options in to the service', function () {
                service.persistDefaultOptions(options);

                expect(service.topicOptions).toEqual(options);
            });
        });

        describe('getTopicFormData', function () {
            it('should return the topic form data matched to the topic key', function () {
                service.initTopicsFormData();
                let formData = service.getTopicFormData('References');
                expect(expectedFormData).toEqual(formData);
            });
        });

        describe('getStepTopicData', function () {
            it('should return the step data matched to the topic key', function () {
                firstStep[0].selected = false;

                service.applyStepData(firstStep[0], topics, firstStep);

                let newStep = [];
                newStep.push({
                    id: 2,
                    isDefault: true,
                    operator: 'OR',
                    selected: true
                });

                service.applyStepData(newStep[0], topics, newStep);

                let stepTopicsData = service.getStepTopicData(2);
                expect(stepTopicsData[0].filterData.abc).toEqual('123');
                expect(stepTopicsData[0].topicKey).toEqual('References');
            });
        });

        describe('defaultTopicsFormData', function () {
            it('should return the default form data for the topic key', function () {
                let formData = service.defaultTopicsFormData('References');
                expect(expectedFormData).toEqual(formData);
            });
        });

        describe('updateOperator', function () {
            it('operator value should get updated', function () {
                firstStep[0].selected = false;
                service.applyStepData(firstStep[0], topics, firstStep);

                let newStep = [];
                newStep.push(firstStep[0]);
                newStep.push({
                    id: 2,
                    isDefault: true,
                    operator: 'OR',
                    selected: true
                });

                service.applyStepData(newStep[1], topics, newStep);
                expect(service.steps[1].operator).toEqual('OR');

                service.updateOperator(1, 'AND');
                expect(service.steps[1].operator).toEqual('AND');

            });
        });
    });
}