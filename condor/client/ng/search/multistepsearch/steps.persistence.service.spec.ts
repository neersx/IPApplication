
import { SearchOperator } from 'search/common/search-operators';
import { Step } from './ipx-step.model';
import { StepsPersistenceService } from './steps.persistence.service';

describe('StepsPersistenceService', () => {
    let service: StepsPersistenceService;
    let steps: Array<Step>;
    beforeEach(() => {
        service = new StepsPersistenceService();
        service.defaultTopicsData = [{
            topicKey: 'Details',
            formData: {
                id: '1',
                caseOfficeOperator: SearchOperator.equalTo,
                caseTypeOperator: SearchOperator.equalTo,
                jurisdictionOperator: SearchOperator.equalTo,
                local: true,
                international: true
            }
        },
        {
            topicKey: 'Text',
            formData: {
                id: '1',
                typeOfMarkOperator: SearchOperator.equalTo,
                titleMarkOperator: SearchOperator.startsWith,
                textType: ''
            }
        }];
        steps = [
            {
                id: 1,
                operator: '',
                selected: true,
                topicsData: [
                    {
                        topicKey: 'Details',
                        formData: {
                            id: '1',
                            caseOfficeOperator: SearchOperator.equalTo,
                            caseTypeOperator: SearchOperator.equalTo,
                            jurisdictionOperator: SearchOperator.equalTo,
                            local: true,
                            international: true
                        }
                    }
                ]
            }
        ];
    });
    it('getTopicsDefaultViewModel should return default data', () => {
        const data = service.getTopicsDefaultViewModel('Text');
        expect(data).toEqual({
            id: '1',
            typeOfMarkOperator: SearchOperator.equalTo,
            titleMarkOperator: SearchOperator.startsWith,
            textType: ''
        });
    });
    describe('getTopicExistingViewModel', () => {
        it('should return default data if steps data not present', () => {
            const data = service.getTopicsDefaultViewModel('Text');
            expect(data).toEqual({
                id: '1',
                typeOfMarkOperator: SearchOperator.equalTo,
                titleMarkOperator: SearchOperator.startsWith,
                textType: ''
            });
        });
        it('should return topic data from steps', () => {
            service.steps = steps;
            const data = service.getTopicsDefaultViewModel('Details');
            expect(data).toEqual({
                id: '1',
                caseOfficeOperator: SearchOperator.equalTo,
                caseTypeOperator: SearchOperator.equalTo,
                jurisdictionOperator: SearchOperator.equalTo,
                local: true,
                international: true
            });
        });
    });
    describe('getStepTopicData', () => {
        it('should return steps topic data', () => {
            const data = service.getStepTopicData(steps, 1);
            expect(data).toEqual(steps[0].topicsData);
        });
        it('should return [] if topic data not exists', () => {
            const data = service.getStepTopicData(steps, 3);
            expect(data).toEqual([]);
        });
    });
    describe('applyStepData', () => {
        it('should set topicsData to step', () => {
            const topics = [
                {
                    key: 'references',
                    formData: '',
                    getFilterCriteria(): { } { return {CaseReference: '1234' }; }
                },
                {
                    key: 'details',
                    formData: '',
                    getFilterCriteria(): { } { return { Details: '22' }; }
                }
            ];
            service.applyStepData(topics, steps);
            expect(steps[0].topicsData).toEqual([
                {
                    topicKey: 'references',
                    formData: '',
                    filterData: { CaseReference: '1234' }
                },
                {
                    topicKey: 'details',
                    formData: '',
                    filterData: { Details: '22' }
                }
            ]);
        });
    });
});
