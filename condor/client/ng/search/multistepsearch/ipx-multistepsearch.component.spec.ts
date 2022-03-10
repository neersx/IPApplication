import { async } from '@angular/core/testing';
import { IpxMultiStepSearchComponent } from './ipx-multistepsearch.component';

describe('MultiStepSearchComponent', () => {
    let c: IpxMultiStepSearchComponent;
    let stepsPersistenceService: any;
    beforeEach(() => {
        stepsPersistenceService = {
            defaultTopicsData: jest.spyOn,
            steps: [{ selected: true, isDefault: true, operator: '', id: 1 }], getSelectedStep: jest.fn(), applyStepData: jest.fn()
        };
        c = new IpxMultiStepSearchComponent(stepsPersistenceService);
        c.operators = ['AND', 'OR', 'NOT'];
        c.steps = stepsPersistenceService.steps;
    });
    describe('initialize component', () => {
        it('should create the component', async(() => {
            expect(c).toBeTruthy();
        }));
        it('should initialise operators', () => {
            expect(c.operators).toEqual(['AND', 'OR', 'NOT']);
        });
        it('should initialise default initial steps', () => {
            expect(c.steps.length).toBe(1);
            expect(c.steps[0].selected).toBe(true);
            expect(c.steps[0].isDefault).toBe(true);
            expect(c.steps[0].operator).toBe('');
            expect(c.steps[0].id).toBe(1);
        });
    });

    describe('remove steps in wizard', () => {
        it('should remove step', () => {

            c.checkNavigation = jest.fn();
            c.goTo = jest.fn();

            // unselect first step
            c.steps[0].selected = false;

            const newStep = {
                id: c.steps.length + 1,
                operator: 'OR',
                selected: true
            };

            // add new  step
            c.steps.push(newStep);

            c.removeStep(newStep);

            expect(c.steps.length).toBe(1);
            // tslint:disable-next-line: no-unbound-method
            expect(c.checkNavigation).toHaveBeenCalled();
            expect(c.goTo).toHaveBeenCalled();
        });
    });
    describe('add steps in wizard', () => {
        it('should add step', () => {
            c.checkNavigation = jest.fn();
            c.goTo = jest.fn();
            c.topicsRef = {
                options: {
                    topics: []
                }
            };

            c.addStep();
            expect(c.steps.length).toBe(2);
            expect(c.steps[1].selected).toBe(true);
            expect(c.steps[1].operator).toBe('OR');
            expect(c.steps[1].id).toBe(2);

            expect(c.goTo).toHaveBeenCalled();
        });
    });
    describe('goto step in wizard', () => {
        it('should goto step', () => {
            c.checkNavigation = jest.fn();
            c.scroll = jest.fn();
            c.setTopicFormData = jest.fn();

            const newStep = {
                id: c.steps.length + 1,
                operator: 'OR',
                selected: true
            };

            // add new  step
            c.steps.push(newStep);

            c.goTo(newStep, true);

            expect(c.steps[0].selected).toBe(false);
            expect(c.steps[1].selected).toBe(true);
            expect(c.scroll).toHaveBeenCalled();
            expect(c.setTopicFormData).toHaveBeenCalled();
        });
    });
    describe('getfilterCriteriaForSearch', () => {
        it('should get filterCriteria for single step', () => {
            c.isMultiStepMode = false;
            c.topicsRef = {
                options: {
                    topics: [
                        {
                            key: 'references',
                            getFilterCriteria: jest.fn().mockReturnValue({ CaseReference: '1234' })
                        },
                        {
                            key: 'details',
                            getFilterCriteria: jest.fn().mockReturnValue({ Details: '22' })
                        }
                    ]
                }
            };

            const data = c.getFilterCriteriaForSearch();
            expect(data.length).toBe(1);
            expect(data).toEqual([{
                CaseReference: '1234',
                Details: '22'
            }]);
        });
        it('should get filterCriteria for multi steps', () => {
            c.isMultiStepMode = true;
            c.topicsRef = {
                options: {
                    topics: [
                    ]
                }
            };

            const newStep = {
                id: c.steps.length + 1,
                operator: 'OR',
                selected: true,
                topicsData: [{
                    topicKey: '1',
                    formData: null,
                    filterData: { CaseReference: '1234' }
                },
                {
                    topicKey: '2',
                    formData: null,
                    filterData: { Details: '22' }
                }]
            };

            c.steps[0].topicsData = [{
                topicKey: '1',
                formData: null,
                filterData: { CaseReference: '11' }
            },
            {
                topicKey: '2',
                formData: null,
                filterData: { Details: '34' }
            }];

            // add new  step
            c.steps.push(newStep);

            const data = c.getFilterCriteriaForSearch();
            expect(data.length).toBe(2);
            expect(data[0]).toEqual({
                CaseReference: '11',
                Details: '34',
                id: 1,
                operator: ''
            });
        });
    });
});