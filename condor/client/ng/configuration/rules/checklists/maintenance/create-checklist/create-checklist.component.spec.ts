import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { BsModalRefMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { CreateChecklistComponent } from './create-checklist.component';

describe('CreateChecklistComponent', () => {
    let component: CreateChecklistComponent;
    let bsModalRef: any;
    let translateService: any;
    let formBuilder: any;
    let validComboService: any;
    let searchService: any;
    let maintainService: any;
    let notifications: any;

    beforeEach(() => {
        bsModalRef = new BsModalRefMock();
        translateService = new TranslateServiceMock();
        formBuilder = new FormBuilder();
        validComboService = { initFormData: jest.fn() };
        searchService = { search: jest.fn() };
        maintainService = { createChecklist: jest.fn() };
        notifications = new NotificationServiceMock();
        component = new CreateChecklistComponent(bsModalRef, translateService, formBuilder, validComboService, searchService, maintainService, notifications);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('initialise', () => {
        it('should intialise the form', () => {
            component.criteria = {};
            component.ngOnInit();
            expect(component.formGroup).toBeDefined();
            expect(validComboService.initFormData).toHaveBeenCalled();
        });
        it('should initialise the form fields to the selected criteria', () => {
            component.criteria = {
                office: '001'

            };
            component.ngOnInit();
            expect(component.formGroup.controls.office.value).toBe('001');
        });
    });

    describe('saving', () => {
        beforeEach(() => {
            component.criteria = {
                office: '123',
                caseType: 'X',
                jurisdiction: 'GB',
                criteriaName: '',
                checklist: ''
            };
            component.ngOnInit();
        });

        it('should not post if invalid', () => {
            component.onSave();
            expect(maintainService.createChecklist).not.toHaveBeenCalled();
            component.formGroup.controls.criteriaName.setValue('ABC-xyz 000-123');
            component.onSave();
            expect(maintainService.createChecklist).not.toHaveBeenCalled();
            component.formGroup.controls.checklist.setValue({ key: '-1' });
        });

        it('should post the data and close the modal if successful', fakeAsync(() => {
            maintainService.createChecklist = jest.fn().mockReturnValue(of({status: true}));
            component.formGroup.controls.criteriaName.setValue('ABC-xyz 000-123');
            component.formGroup.controls.checklist.setValue({ key: '-1' });
            component.formGroup.markAsDirty();
            expect(component.formGroup.value).toBeTruthy();
            expect(component.formGroup.valid).toBeTruthy();
            component.onSave();
            expect(maintainService.createChecklist).toHaveBeenCalled();
            tick(10);
            expect(notifications.success).toHaveBeenCalled();
            expect(bsModalRef.hide).toHaveBeenCalled();
        }));
        it('should post the data and display errors if any', fakeAsync(() => {
            maintainService.createChecklist = jest.fn().mockReturnValue(of({ error: {field: 'abc-XYZ-123', message: 'there was an error'} }));
            translateService.instant = jest.fn().mockReturnValue('translated error message');
            component.formGroup.controls.criteriaName.setValue('ABC-xyz 000-123');
            component.formGroup.controls.checklist.setValue({ key: '-1' });
            component.formGroup.markAsDirty();
            expect(component.formGroup.value).toBeTruthy();
            expect(component.formGroup.valid).toBeTruthy();
            component.onSave();
            expect(maintainService.createChecklist).toHaveBeenCalled();
            tick(10);
            expect(notifications.success).not.toHaveBeenCalled();
            expect(bsModalRef.hide).not.toHaveBeenCalled();
            expect(translateService.instant).toHaveBeenCalledWith('checklistConfiguration.errors.abc-XYZ-123', { criteriaId: 'there was an error' });
            expect(notifications.alert).toHaveBeenCalledWith({ message: 'translated error message'});
        }));
    });
});
