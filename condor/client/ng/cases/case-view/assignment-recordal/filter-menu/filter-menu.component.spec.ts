import { FormBuilder } from '@angular/forms';
import { KnownNameTypesMock, TranslateServiceMock } from 'mocks';
import { NameFilteredPicklistScope } from 'search/case/case-search-topics/name-filtered-picklist-scope';
import { AffectedCasesFilterMenuComponent } from './filter-menu.component';

describe('AffectedCasesFilterMenuComponent', () => {
    let component: AffectedCasesFilterMenuComponent;
    let builder: FormBuilder;
    let knownTypes: KnownNameTypesMock;
    let translate: TranslateServiceMock;

    beforeEach(() => {
        builder = new FormBuilder();
        translate = new TranslateServiceMock();
        knownTypes = new KnownNameTypesMock();
        component = new AffectedCasesFilterMenuComponent(knownTypes as any, translate as any);
        component.formGroup = {
            value: {
                renew: true
            },
            dirty: true,
            markAsDirty: jest.fn(),
            controls: {
                stepNumber: { value: null, setValue: jest.fn().mockReturnValue('1') },
                recordalType: { value: { key: 2 }, setValue: jest.fn().mockReturnValue('2') },
                caseRef: { value: 1234, setValue: jest.fn().mockReturnValue('1234') },
                propertyType: { setValue: jest.fn().mockReturnValue('') },
                officialNo: { setValue: jest.fn().mockReturnValue('') },
                currentOwner: { setValue: jest.fn().mockReturnValue('') },
                foreignAgent: { setValue: jest.fn().mockReturnValue('') },
                pending: { value: true, setValue: jest.fn().mockReturnValue(false) },
                jurisdiction: { setValue: jest.fn().mockReturnValue('AU') },
                registered: { setValue: jest.fn().mockReturnValue(true) },
                dead: { value: false, setValue: jest.fn().mockReturnValue(false) },
                notYetFiled: { setValue: jest.fn().mockReturnValue(true) },
                recorded: { value: false, setValue: jest.fn().mockReturnValue(false) },
                filed: { value: true, setValue: jest.fn().mockReturnValue(false) },
                rejected: { setValue: jest.fn().mockReturnValue(false) }
            }
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should create new formGroup', () => {
        jest.spyOn(component, 'createFormGroup');
        component.formGroup = null;
        component.ngOnInit();
        expect(component.createFormGroup).toBeCalled();
    });

    describe('ngOnInit', () => {

        it('should initialise correctly', () => {
            const ownerPickList = new NameFilteredPicklistScope(
                knownTypes.owner,
                translate.instant('picklist.owner'),
                false
            );
            component.formGroup = null;
            jest.spyOn(component, 'loadExistingFilter');
            component.ngOnInit();
            expect(component.ownerPickListExternalScope).not.toBeNull();
            expect(component.loadExistingFilter).not.toBeCalled();
        });

        it('should initialise correctly with existing filters', () => {
            component.formGroup = null;
            component.filterParams = { value: { caseRef: '123' } };
            jest.spyOn(component, 'loadExistingFilter');
            component.ngOnInit();
            expect(component.ownerPickListExternalScope).not.toBeNull();
            expect(component.loadExistingFilter).toBeCalledWith({ caseRef: '123' });
        });
    });

    describe('form submit and clear', () => {
        it('should submit and prepare corrrect filter data', () => {
            jest.spyOn(component, 'prepareFilter');
            component.submit();
            expect(component.prepareFilter).toBeCalled();
        });
        it('should prepare corrrect filter data', () => {
            const result = component.prepareFilter();
            expect(result.stepNo).toBe(null);
            expect(result.recordalStatus).toEqual(['Filed']);
            expect(result.caseStatus).toEqual(['Pending']);
            expect(result.recordalTypeNo).toBe(2);
            expect(result.jurisdictions).toBe(null);
        });
        it('clear filter data', () => {
            jest.spyOn(component, 'createFormGroup');
            jest.spyOn(component.onFilterSelect, 'emit');
            component.clear();
            expect(component.createFormGroup).toBeCalled();
            expect(component.onFilterSelect.emit).toBeCalled();
        });
    });
});