import { CaseValidCombinationServiceMock, ChangeDetectorRefMock } from 'mocks';
import { skip } from 'rxjs/operators';
import { SearchByCaseComponent } from './search-by-case.component';
jest.useFakeTimers();
describe('Checklist search by characteristics', () => {
    let component: SearchByCaseComponent;
    let cdRef: any;
    let cvs: any;
    let validatorService: any;

    beforeEach(() => {
        cvs = new CaseValidCombinationServiceMock();
        validatorService = { validateCaseCharacteristics$: jest.fn() } as any;
        cdRef = new ChangeDetectorRefMock();
        component = new SearchByCaseComponent(cvs, cdRef, validatorService);
    });

    it('should create and initialise the component', () => {
        component.ngOnInit();
        expect(component).toBeTruthy();
        expect(component.appliesToOptions.length).toBe(2);
    });

    it('verifyCaseCategoryStatus should correctly call isCaseCategoryDisabled with right flag', done => {
        component.ngOnInit();
        let isDisabled = true;

        component.isCaseCategoryDisabled.subscribe(val => {
            expect(val).toEqual(isDisabled);

            if (!isDisabled) {
                done();
            }
        });

        component.formData = { ...component.formData, caseType: { code: 'A' }, caseTypeExclude: true };
        component.verifyCaseCategoryStatus();

        component.formData = { ...component.formData, caseType: { code: 'A' }, caseTypeExclude: false };
        isDisabled = false;
        component.verifyCaseCategoryStatus();
    });

    it('resetFormData, should default the form data back to the expected values', () => {
        cvs.validCombinationDescriptionsMap = 'validCombinationDescriptionsMap';
        cvs.extendValidCombinationPickList = 'extendValidCombinationPickList';

        component = new SearchByCaseComponent(cvs, cdRef, validatorService);
        component.ngOnInit();
        expect(component.picklistValidCombination).toEqual('validCombinationDescriptionsMap');
        expect(cvs.initFormData).toHaveBeenCalled();
    });

    it('characteristicsFor, should extend query to include selected instruction type', () => {
        component.ngOnInit();
        component.formData = { ...component.formData, instructionType: { code: 'ABCD' } };
        const result = component.characteristicsExtendQuery({});
        expect(result.instructionTypeCode).toEqual('ABCD');
    });

    it('isInstructionTypeSelected fires value, depending on call to instructionTypeSelected', done => {
        let isSelected = false;
        component.isInstructionTypeSelected.subscribe((val) => {
            expect(val).toEqual(isSelected);

            if (isSelected) {
                done();
            }
        });

        component.instructionTypeSelected(isSelected);

        isSelected = true;
        component.instructionTypeSelected(isSelected);
    });

    it('on criteria changes, calls validator service', () => {
        component.form = { control: {} } as any;
        component.formData = { caseType: 'A', caseTypeExcluded: true };
        validatorService.validateCaseCharacteristics$.mockReturnValue({
            then: jest.fn().mockImplementation((x) => {
                x();
            })
        });
        component.isCaseCategoryDisabled.pipe(skip(1)).subscribe((val) => {
            expect(val).toBeFalsy();
        });

        component.onCriteriaChange();
        jest.runAllTimers();

        expect(validatorService.validateCaseCharacteristics$).toHaveBeenCalled();
        expect(component.formData.jurisdictionExclude).toBeNull();
        expect(component.formData.propertyTypeExclude).toBeNull();
        expect(component.formData.caseCategoryExclude).toBeNull();
        expect(component.formData.subTypeExclude).toBeNull();
        expect(component.formData.basisExclude).toBeNull();
    });
});