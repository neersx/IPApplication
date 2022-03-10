import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { ChecklistSearchServiceMock } from '../checklist-search.service.mock';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';
import { SearchByQuestionComponent } from './search-by-question.component';

describe('SearchByQuestionComponent', () => {
    let component: SearchByQuestionComponent;
    let commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;
    let cdRef: any;
    let cvs: any;
    let searchService: any;
    let cvccs: any;

    beforeEach(() => {
        cvs = new CaseValidCombinationServiceMock();
        searchService = new ChecklistSearchServiceMock();
        cdRef = new ChangeDetectorRefMock();
        component = new SearchByQuestionComponent(searchService, cdRef);
        cvccs = { validateCaseCharacteristics$: jest.fn() } as any;
        commonChecklistCharacteristics = new CommonChecklistCharacteristicsComponent(searchService, cdRef, cvs, cvccs);
        component.commonChecklistCharacteristics = commonChecklistCharacteristics;
        (component.clear as any) = new EventEmitterMock();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('submitForm', () => {
        it('calls the search service and emits search', () => {
            spyOn(component.search, 'emit');
            component.formData = {
                includeProtectedCriteria: false,
                matchType: 'exact-match',
                test: 'vvvv'
            };
            commonChecklistCharacteristics.formData = {
                twoLegs: 'hope rises'
            };
            component.submitForm();
            expect(searchService.setSearchData.mock.calls[0][0]).toBe('questionSearchForm');
            expect(searchService.setSearchData.mock.calls[0][1]).toBe(component.formData);
            expect(component.search.emit).toHaveBeenCalledWith({
                includeProtectedCriteria: false,
                matchType: 'exact-match',
                test: 'vvvv',
                twoLegs: 'hope rises'
            });
        });

        describe('resetFormData', () => {
            it('should default the form data back to the expected values', () => {
                commonChecklistCharacteristics.resetFormData = jest.fn();
                component.resetFormData();

                expect(component.clear.emit).toHaveBeenCalled();
                expect(commonChecklistCharacteristics.resetFormData).toHaveBeenCalled();
            });
        });
    });
});