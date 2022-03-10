import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { ChecklistSearchServiceMock } from '../checklist-search.service.mock';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';
import { SearchByCharacteristicComponent } from './search-by-characteristic.component';

describe('Checklist search by characteristics', () => {
    let component: SearchByCharacteristicComponent;
    let commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;
    let cvs: any;
    let cdRef: any;
    let searchService: any;
    let cvccs: any;

    beforeEach(() => {
        cvs = new CaseValidCombinationServiceMock();
        searchService = new ChecklistSearchServiceMock();
        cdRef = new ChangeDetectorRefMock();
        cvccs = { validateCaseCharacteristics$: jest.fn() } as any;
        component = new SearchByCharacteristicComponent(cvs, searchService);
        commonChecklistCharacteristics = new CommonChecklistCharacteristicsComponent(searchService, cdRef, cvs, cvccs);
        commonChecklistCharacteristics.resetFormData = jest.fn();
        component.commonChecklistCharacteristics = commonChecklistCharacteristics;
        (component.clear as any) = new EventEmitterMock();
        (component.viewData as any) = { canMaintainProtectedRules: true };
    });

    it('should create the component', () => {
        expect(component).toBeTruthy();
    });

    describe('initialise', () => {
        it('should disable search if user does not have any task security', () => {
            component.viewData = { canMaintainProtectedRules: false, canMaintainRules: false, canMaintainQuestion: false, hasOffices: true, canAddProtectedRules: true, canAddRules: true };
            component.ngAfterViewInit();
            expect(component.disableSearch).toBeTruthy();
        });
        it('should disable search if user does not have rules task security', () => {
            component.viewData = { canMaintainProtectedRules: false, canMaintainRules: false, canMaintainQuestion: true, hasOffices: true, canAddProtectedRules: true, canAddRules: true };
            component.ngAfterViewInit();
            expect(component.disableSearch).toBeTruthy();
        });
        it('should enable search if user has protected rules task security', () => {
            component.viewData = { canMaintainProtectedRules: true, canMaintainRules: false, canMaintainQuestion: false, hasOffices: true, canAddProtectedRules: true, canAddRules: true };
            component.ngAfterViewInit();
            expect(component.disableSearch).toBeFalsy();
        });
        it('should enable search if user has rules task security', () => {
            component.viewData = { canMaintainProtectedRules: false, canMaintainRules: true, canMaintainQuestion: false, hasOffices: true, canAddProtectedRules: true, canAddRules: true };
            component.ngAfterViewInit();
            expect(component.disableSearch).toBeFalsy();
        });
    });

    describe('resetFormData', () => {
        it('should default the form data back to the expected values', () => {
            component.resetFormData();

            expect(component.clear.emit).toHaveBeenCalled();
            expect(commonChecklistCharacteristics.resetFormData).toHaveBeenCalled();
        });
    });

    describe('submitForm', () => {
        it('calls the search service and emits search', () => {
            component.ngAfterViewInit();
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