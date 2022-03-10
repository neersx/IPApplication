import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { SearchOperator } from 'search/common/search-operators';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { AdhocDateSearchBuilderComponent } from './adhoc-date-search-builder.component';

describe('AdhocDateSearchBuilderComponent', () => {
    let component: AdhocDateSearchBuilderComponent;
    let changeDetectorRef: ChangeDetectorRefMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let formData: any;
    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        changeDetectorRef = new ChangeDetectorRefMock();
        component = new AdhocDateSearchBuilderComponent(changeDetectorRef as any, taskPlannerService as any);
        formData = {
            adhocDates: {
                names: { operator: '0', value: [{ key: 1110, value: 'name 1' }, { key: 220, value: 'name 2' }] },
                generalRef: { operator: '0', value: 'test message' },
                message: { operator: '0', value: 'test message' },
                emailSubject: { operator: '0', value: 'test message' },
                includeCase: true,
                includeName: true,
                includeGeneral: true
            }
        };
        component.topic = {
            params: {
                viewData: {
                    formData
                }
            }
        } as any;

        component.form = new NgForm(null, null);
        component.form.form.addControl('adhocDateMessage', new FormControl(null, null));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toBeDefined();
        expect(component.formData).toBe(formData.adhocDates);
    });

    it('validate initFormData', () => {
        component.initFormData();
        expect(component.formData).toBeDefined();
        expect(component.formData.names.operator).toEqual(SearchOperator.equalTo);
        expect(component.formData.includeGeneral).toBeTruthy();
        expect(component.formData.includeCase).toBeTruthy();
        expect(component.formData.includeName).toBeTruthy();
        expect(component.formData.includeFinalizedAdHocDates).toBeFalsy();
        expect(component.formData.generalRef.operator).toEqual(SearchOperator.startsWith);
    });

    it('validate clear', () => {
        component.formData.message = { value: 'message 1', operator: SearchOperator.contains };
        component.formData.includeGeneral = true;
        component.formData.includeCase = false;
        component.formData.includeFinalizedAdHocDates = true;
        component.clear();
        expect(component.formData.message.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.includeName).toBeTruthy();
        expect(component.formData.includeGeneral).toBeTruthy();
        expect(component.formData.includeCase).toBeTruthy();
        expect(component.formData.includeFinalizedAdHocDates).toBeFalsy();
        expect(changeDetectorRef.markForCheck).toHaveBeenCalled();
    });

    it('validate isValid', () => {
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('validate getFormData for onhold', () => {
        component.formData.names = { operator: SearchOperator.notEqualTo, value: [{ key: 1110 }] };
        component.formData.message = { operator: SearchOperator.endsWith, value: 'message 1' };
        component.formData.includeGeneral = false;
        component.formData.includeName = true;
        component.formData.includeCase = true;
        component.formData.includeFinalizedAdHocDates = true;
        const result = component.getFormData();
        expect(result.searchRequest.adHocReference).toBeNull();
        expect(result.searchRequest.nameReferenceKeys).toEqual({ operator: SearchOperator.notEqualTo, value: '1110' });
        expect(result.searchRequest.adHocMessage).toEqual({ operator: SearchOperator.endsWith, value: 'message 1' });
        expect(result.searchRequest.includeAdhocDate).toEqual({ hasCase: 1, hasName: 1, isGeneral: 0, includeFinalizedAdHocDates: 1 });
        expect(result.formData.adhocDates).toBe(component.formData);
    });

    it('validate changeInclude', () => {
        component.formData.generalRef = { operator: SearchOperator.endsWith, value: 'ref' };
        component.changeInclude(false, 'generalRef');
        expect(component.formData.generalRef.value).toBeNull();
    });

    it('validate changeInclude with include', () => {
        component.formData.generalRef = { operator: SearchOperator.endsWith, value: 'ref' };
        component.changeInclude(true, 'generalRef');
        expect(component.formData.generalRef.value).toEqual('ref');
    });

    it('validate isDirty when form is dirty', () => {
        component.form.form.addControl('displayName', new FormControl(null));
        component.form.controls.displayName.setValue('data');
        component.form.controls.displayName.markAsDirty();
        expect(component.isDirty()).toEqual(true);
    });
    it('validate isDirty when form is not dirty', () => {
        component.form.form.addControl('displayName', new FormControl(null));
        expect(component.isDirty()).toEqual(false);
    });
    it('validate setPristine', () => {
        component.form.form.addControl('displayName', new FormControl(null));
        component.form.controls.displayName.setValue('data');
        component.form.controls.displayName.markAsDirty();
        component.setPristine();
        expect(component.isDirty()).toEqual(false);
    });
});
