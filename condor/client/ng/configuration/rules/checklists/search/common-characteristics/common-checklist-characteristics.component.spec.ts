import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, EventEmitterMock } from 'mocks';
import { ChecklistSearchServiceMock } from '../checklist-search.service.mock';
import { CommonChecklistCharacteristicsComponent } from './common-checklist-characteristics.component';

describe('Checklist search by characteristics', () => {
    let component: CommonChecklistCharacteristicsComponent;
    let cdRef: any;
    let cvs: any;
    let searchService: any;

    beforeEach(() => {
        cvs = new CaseValidCombinationServiceMock();
        searchService = new ChecklistSearchServiceMock();
        cdRef = new ChangeDetectorRefMock();
        component = new CommonChecklistCharacteristicsComponent(searchService, cdRef, cvs);
        (component.clear as any) = new EventEmitterMock();
        (component.viewData as any) = {
            canMaintainProtectedRules: true,
            canMaintainRules: true
        };
    });

    it('should create and initialise the component', () => {
        component.ngOnInit();
        expect(component).toBeTruthy();
        expect(component.appliesToOptions.length).toBe(2);
    });

    describe('verifyCaseCategoryStatus', () => {
        it('should correctly call CaseValidCombinationService', () => {
            component.ngOnInit();
            component.verifyCaseCategoryStatus();

            expect(cvs.isCaseCategoryDisabled).toHaveBeenCalled();
        });
    });

    describe('onCaseChange', () => {
        it('should not try to default if no case selected', () => {
            component.ngOnInit();
            component.defaultFieldsFromCase(null);

            expect(searchService.getCaseCharacteristics$).not.toHaveBeenCalled();
        });

        it('should try to default when a case is selected', () => {
            const pickedCase = {
                key: 68965
            };
            component.ngOnInit();
            component.defaultFieldsFromCase(pickedCase);

            expect(searchService.getCaseCharacteristics$).toHaveBeenCalledWith(pickedCase.key, 'C');
        });
    });

    describe('resetFormData', () => {
        it('should default the form data back to the expected values', () => {
            component.formData = {
                includeProtectedCriteria: false,
                matchType: 'not-exact-match'
            };
            cvs.validCombinationDescriptionsMap = 'validCombinationDescriptionsMap';
            cvs.extendValidCombinationPickList = 'extendValidCombinationPickList';

            component.resetFormData();

            expect(component.formData.includeProtectedCriteria).toBeTruthy();
            expect(component.picklistValidCombination).toEqual('validCombinationDescriptionsMap');
            expect(component.extendPicklistQuery).toEqual('extendValidCombinationPickList');
            expect(component.formData.matchType).toEqual('exact-match');
            expect(component.clear.emit).toHaveBeenCalled();
            expect(cvs.initFormData).toHaveBeenCalled();
        });
    });
});