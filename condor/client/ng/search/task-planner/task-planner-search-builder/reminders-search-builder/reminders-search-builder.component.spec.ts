import { FormControl, NgForm } from '@angular/forms';
import { ChangeDetectorRefMock } from 'mocks';
import { SearchOperator } from 'search/common/search-operators';
import { RemindersSearchBuilderComponent } from './reminders-search-builder.component';

describe('RemindersSearchBuilderComponent', () => {
    let component: RemindersSearchBuilderComponent;
    let changeDetectorRef: ChangeDetectorRefMock;
    let formData: any;
    beforeEach(() => {
        changeDetectorRef = new ChangeDetectorRefMock();
        component = new RemindersSearchBuilderComponent(changeDetectorRef as any);
        formData = {
            reminders: {
                reminderMessage: { operator: '0', value: 'test message' },
                isReminderOnHold: 1,
                isReminderRead: 0
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
        component.form.form.addControl('reminderMessage', new FormControl(null, null));
    });

    it('should create', () => {
        expect(component).toBeDefined();
    });

    it('validate ngOnInit', () => {
        component.ngOnInit();
        expect(component.viewData).toBeDefined();
        expect(component.formData).toBe(formData.reminders);
    });

    it('validate initFormData', () => {
        component.initFormData();
        expect(component.formData).toBeDefined();
        expect(component.formData.reminderMessage.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.isNotOnHold).toBeTruthy();
        expect(component.formData.isOnHold).toBeTruthy();
        expect(component.formData.isRead).toBeTruthy();
        expect(component.formData.isNotRead).toBeTruthy();
    });

    it('validate clear', () => {
        component.formData.reminderMessage = { value: 'reminder message 1', operator: SearchOperator.contains };
        component.formData.isNotRead = true;
        component.formData.isRead = false;
        component.formData.isOnHold = false;
        component.formData.isNotOnHold = false;
        component.clear();
        expect(component.formData.reminderMessage.operator).toEqual(SearchOperator.startsWith);
        expect(component.formData.reminderMessage.value).toBeUndefined();
        expect(component.formData.isNotOnHold).toBeTruthy();
        expect(component.formData.isOnHold).toBeTruthy();
        expect(component.formData.isRead).toBeTruthy();
        expect(component.formData.isNotRead).toBeTruthy();
        expect(changeDetectorRef.markForCheck).toHaveBeenCalled();
    });

    it('validate isValid', () => {
        const result = component.isValid();
        expect(result).toBeTruthy();
    });

    it('validate getFormData for onhold', () => {
        component.formData.reminderMessage = { operator: SearchOperator.endsWith, value: 'reminder message 1' };
        component.formData.isNotRead = true;
        component.formData.isRead = true;
        component.formData.isOnHold = true;
        component.formData.isNotOnHold = false;
        const result = component.getFormData();
        expect(result.searchRequest.reminderMessage).toEqual({ operator: SearchOperator.endsWith, value: 'reminder message 1' });
        expect(result.searchRequest.isReminderOnHold).toEqual(1);
        expect(result.searchRequest.isReminderRead).toBeUndefined();
        expect(result.formData.reminders).toBe(component.formData);
    });

    it('validate getFormData for read', () => {
        component.formData.reminderMessage = { operator: SearchOperator.endsWith, value: 'reminder message 2' };
        component.formData.isNotRead = true;
        component.formData.isRead = false;
        component.formData.isOnHold = false;
        component.formData.isNotOnHold = false;
        const result = component.getFormData();
        expect(result.searchRequest.reminderMessage).toEqual({ operator: SearchOperator.endsWith, value: 'reminder message 2' });
        expect(result.searchRequest.isReminderRead).toEqual(0);
        expect(result.searchRequest.isReminderOnHold).toBeUndefined();
        expect(result.formData.reminders).toBe(component.formData);
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
