import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { ChecklistSearchServiceMock } from '../checklist-search.service.mock';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';
import { SearchByCaseComponent } from './search-by-case.component';

describe('Checklist search by characteristics', () => {
    let component: SearchByCaseComponent;
    let commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;
    let cdRef: any;
    let cvs: any;
    let searchService: any;
    let cvccs: any;

    beforeEach(() => {
        cvs = new CaseValidCombinationServiceMock();
        searchService = new ChecklistSearchServiceMock();
        cdRef = new ChangeDetectorRefMock();
        component = new SearchByCaseComponent(cvs, cdRef, searchService);
        cvccs = { validateCaseCharacteristics$: jest.fn() } as any;
        commonChecklistCharacteristics = new CommonChecklistCharacteristicsComponent(searchService, cdRef, cvs, cvccs);
        component.commonChecklistCharacteristics = commonChecklistCharacteristics;
        (component.clear as any) = new EventEmitterMock();
        (component.viewData as any) = {
            canMaintainProtectedRules: true,
            canMaintainRules: true
        };
    });

    it('should create and initialise the component', () => {
        component.ngOnInit();
        expect(component).toBeTruthy();
        expect(component.disableSearch).toBeFalsy();
    });

    it('should disable search when user has no permission', () => {
        component.viewData = { canMaintainProtectedRules: false, canMaintainRules: false, hasOffices: true, canMaintainQuestion: false, canAddProtectedRules: true, canAddRules: true };
        component.ngOnInit();
        expect(component.disableSearch).toBeTruthy();
    });

    describe('onCaseChange', () => {
        it('should not try to default if no case selected', () => {
            component.ngOnInit();
            component.onCaseChange(null);

            expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
        });

        it('should try to default when a case is selected', () => {
            const pickedCase = {
                key: 68965
            };
            component.ngOnInit();
            component.onCaseChange(pickedCase);

            expect(searchService.getCaseCharacteristics$).toHaveBeenCalledWith(pickedCase.key, 'C');
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

    describe('submitForm', () => {
        it('calls the search service and emits search', () => {
            component.ngOnInit();
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
            expect(searchService.setSearchData.mock.calls[0][0]).toBe('characteristicsSearchForm');
            expect(searchService.setSearchData.mock.calls[0][1]).toBe(component.formData);
            expect(component.search.emit).toHaveBeenCalledWith({
                includeProtectedCriteria: false,
                matchType: 'exact-match',
                test: 'vvvv',
                twoLegs: 'hope rises'
            });
        });
    });
});