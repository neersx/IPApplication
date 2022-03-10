import { CaseValidCombinationServiceMock, ChangeDetectorRefMock } from 'mocks';
import { skip } from 'rxjs/operators';
import { SearchByNameComponent } from './search-by-name.component';
jest.useFakeTimers();
describe('Checklist search by characteristics', () => {
    let component: SearchByNameComponent;
    let cdRef: any;

    beforeEach(() => {
        cdRef = new ChangeDetectorRefMock();
        component = new SearchByNameComponent(cdRef);
    });

    it('should create and initialise the component', () => {
        component.ngOnInit();
        expect(component).toBeTruthy();
        expect(component.appliesToOptions.length).toBe(2);
    });

    it('resetFormData, should default the form data back to the expected values', () => {
        component.ngOnInit();
        expect(component.formData).toEqual({});
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
});