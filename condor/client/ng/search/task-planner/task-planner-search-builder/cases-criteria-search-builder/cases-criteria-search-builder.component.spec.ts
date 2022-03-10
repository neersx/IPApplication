import { FormControl, NgForm } from '@angular/forms';
import { CaseValidCombinationServiceMock, ChangeDetectorRefMock, TranslateServiceMock } from 'mocks';
import { SearchOperator } from 'search/common/search-operators';
import { CasesCriteriaSearchBuilderComponent } from './cases-criteria-search-builder.component';

describe('CasesCriteriaSearchBuilderComponent', () => {
    let component: CasesCriteriaSearchBuilderComponent;
    let changeDetectorRef: ChangeDetectorRefMock;
    let vcService: CaseValidCombinationServiceMock;
    let translate: TranslateServiceMock;
    let formData: any;
    beforeEach(() => {
        changeDetectorRef = new ChangeDetectorRefMock();
        vcService = new CaseValidCombinationServiceMock();
        translate = new TranslateServiceMock();
        component = new CasesCriteriaSearchBuilderComponent(changeDetectorRef as any, vcService as any, {} as any, translate as any);
        formData = {
            cases: {
                caseFamily: { operator: '0', value: [{ key: 12, code: 'AA', value: 'Test family' }] },
                caseCategory: { operator: '0', value: [{ key: 45, code: 'BB', value: 'Test category' }] },
                caseType: { operator: '1', value: [{ key: -765, code: 'CC', value: 'Type 1' }] },
                jurisdiction: { operator: '0', value: { key: 667, code: 'ju' } },
                propertyType: { operator: '0', value: { key: 981, code: 'PT' } }
            }
        };
        component.topic = {
            params: {
                viewData: {
                    numberTypes: [{ value: 'Application No', key: '1' }, { value: 'Patent No', key: '2' }],
                    nameTypes: [{ value: 'Owner', key: '22' }],
                    formData
                }
            }
        } as any;

        component.casesCriteriaForm = new NgForm(null, null);
        component.casesCriteriaForm.form.addControl('caseReference', new FormControl(null, null));
        component.casesCriteriaForm.form.addControl('basis', new FormControl(null, null));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toBeDefined();
        expect(component.numberTypes.length).toEqual(2);
        expect(component.nameTypes.length).toEqual(1);
        expect(component.formData).toBe(formData.cases);
        expect(component.instructorPickListExternalScope).toBeDefined();
        expect(component.ownerPickListExternalScope).toBeDefined();
        expect(component.namePickListExternalScope).toBeDefined();
    });

    it('validate initFormData', () => {
        component.initFormData();
        expect(component.formData).toBeDefined();
        expect(component.formDataForVC).toBeDefined();
        expect(component.formData.caseReference.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.caseCategory.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.officialNumber.type).toEqual('');
    });

    it('validate clear', () => {
        component.formData.caseReference = { value: [{ key: '-487', value: '1234/a' }], operator: SearchOperator.equalTo };
        component.formData.basis = { value: { key: '3', code: 'A' }, operator: SearchOperator.notEqualTo };
        component.formData.instructor = { value: { key: '984', code: 'IS' }, operator: SearchOperator.notEqualTo };
        component.clear();
        expect(component.formData.caseReference.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.caseReference.value).toBeUndefined();
        expect(component.formData.basis.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.basis.value).toBeUndefined();
        expect(component.formData.instructor.value).toBeUndefined();
        expect(component.formData.instructor.operator).toEqual(SearchOperator.equalTo);
        expect(component.disabledCaseCategory).toBeTruthy();
        expect(vcService.initFormData).toHaveBeenCalled();
        expect(changeDetectorRef.markForCheck).toHaveBeenCalled();
    });

    it('validate isValid', () => {
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('validate changeCaseType with case type', () => {
        const caseTypes = [{ key: 4, code: 'A' }];
        component.formData.caseType.value = caseTypes;
        component.changeCaseType();
        expect(component.disabledCaseCategory).toBeFalsy();
        expect(component.formDataForVC.caseType).toBe(caseTypes);
    });

    it('validate changeCaseType without case type', () => {
        component.formData.caseType.value = null;
        component.changeCaseType();
        expect(component.disabledCaseCategory).toBeTruthy();
        expect(component.formDataForVC.caseType).toBeNull();
    });

    it('validate getFormData', () => {
        const caseFamilies = [{ key: 11, code: 'F', value: 'Family 1' }, { key: 12, code: 'G', value: 'Family 2' }];
        const caseOffices = [{ key: 21, code: 'O', value: 'Office 1' }, { key: 22, code: 'P', value: 'Office 2' }];
        const subType = { key: 31, code: 'S', value: 'sub type 1' };
        component.formData.caseReference = { operator: SearchOperator.contains, value: 'caseref' };
        component.formData.caseFamily = { operator: SearchOperator.equalTo, value: caseFamilies };
        component.formData.caseOffice = { operator: SearchOperator.equalTo, value: caseOffices };
        component.formData.subType = { operator: SearchOperator.notEqualTo, value: subType };
        const result = component.getFormData();
        expect(result.searchRequest.caseReference.value).toEqual('caseref');
        expect(result.searchRequest.caseReference.operator).toEqual(SearchOperator.contains);
        expect(result.searchRequest.familyKeyList.operator).toEqual(SearchOperator.equalTo);
        expect(result.searchRequest.familyKeyList.familyKey[0].value).toEqual(11);
        expect(result.searchRequest.familyKeyList.familyKey[1].value).toEqual(12);
        expect(result.searchRequest.familyKeyList.operator).toEqual(SearchOperator.equalTo);
        expect(result.searchRequest.subTypeKey.operator).toEqual(SearchOperator.notEqualTo);
        expect(result.searchRequest.subTypeKey.value).toEqual('S');
        expect(result.searchRequest.officeKeys.value).toEqual('21,22');
        expect(result.searchRequest.officeKeys.operator).toEqual(SearchOperator.equalTo);
        expect(result.searchRequest.caseList).toBeNull();
        expect(result.formData.cases).toBe(component.formData);
    });

    it('validate changeOperator with equalTo', () => {
        const caseFamilies = [{ key: 11, code: 'F', value: 'Family 1' }, { key: 12, code: 'G', value: 'Family 2' }];
        component.formData.caseFamily = { operator: SearchOperator.equalTo, value: caseFamilies };
        component.changeOperator('caseFamily');
        expect(component.formData.caseFamily.value).toBe(caseFamilies);
    });

    it('validate changeOperator notEqualTo', () => {
        const caseFamilies = [{ key: 11, code: 'F', value: 'Family 1' }, { key: 12, code: 'G', value: 'Family 2' }];
        component.formData.caseFamily = { operator: SearchOperator.notEqualTo, value: caseFamilies };
        component.changeOperator('caseFamily');
        expect(component.formData.caseFamily.value).toBe(caseFamilies);
    });

    it('validate changeOperator exists', () => {
        const caseFamilies = [{ key: 11, code: 'F', value: 'Family 1' }, { key: 12, code: 'G', value: 'Family 2' }];
        component.formData.caseFamily = { operator: SearchOperator.exists, value: caseFamilies };
        component.changeOperator('caseFamily');
        expect(component.formData.caseFamily.value).toBeNull();
    });

    it('validate updateVCFormData', () => {
        const caseTypes = [{ key: 4, code: 'A' }];
        const caseCategories = [{ key: 12, code: 'CC' }];
        component.formData.caseType = { value: caseTypes, operator: SearchOperator.equalTo };
        component.formData.caseCategory = { value: caseCategories, operator: SearchOperator.notEqualTo };
        component.updateVCFormData();
        expect(component.formDataForVC.caseType).toBe(caseTypes);
        expect(component.formDataForVC.caseCategory).toBe(caseCategories);
    });

    it('validate isDirty when form is dirty', () => {
        component.casesCriteriaForm.form.addControl('displayName', new FormControl(null));
        component.casesCriteriaForm.controls.displayName.setValue('data');
        component.casesCriteriaForm.controls.displayName.markAsDirty();
        expect(component.isDirty()).toEqual(true);
    });
    it('validate isDirty when form is not dirty', () => {
        component.casesCriteriaForm.form.addControl('displayName', new FormControl(null));
        expect(component.isDirty()).toEqual(false);
    });
    it('validate setPristine', () => {
        component.casesCriteriaForm.form.addControl('displayName', new FormControl(null));
        component.casesCriteriaForm.controls.displayName.setValue('data');
        component.casesCriteriaForm.controls.displayName.markAsDirty();
        component.setPristine();
        expect(component.isDirty()).toEqual(false);
    });

});
