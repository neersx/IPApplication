import { FormControl, NgForm, Validators } from '@angular/forms';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock } from 'mocks';
import { ReminderRequestType } from '../task-planner.data';
import { DueDateResponsibilityModalComponent } from './due-date-responsibility-modal.component';

describe('DueDateResponsibilityModalComponent', () => {
    let component: DueDateResponsibilityModalComponent;
    let modalRef: BsModalRefMock;
    let cdRef: ChangeDetectorRefMock;
    let appContext: AppContextServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;
    beforeEach(() => {
        modalRef = new BsModalRefMock();
        cdRef = new ChangeDetectorRefMock();
        appContext = new AppContextServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        component = new DueDateResponsibilityModalComponent(modalRef as any, cdRef as any, appContext as any, ipxNotificationService as any);
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('verify ngOnInit method with inline task menu', () => {
        component.requestType = ReminderRequestType.InlineTask;
        component.ngOnInit();
        expect(component.picklistPlaceholder).toEqual('taskPlanner.dueDateResponsibility.unassigned');
    });

    it('verify ngOnInit method with bulk action menu', () => {
        component.requestType = ReminderRequestType.BulkAction;
        component.ngOnInit();
        expect(component.picklistPlaceholder).toBeNull();
    });

    it('verify save method', () => {
        component.requestType = ReminderRequestType.InlineTask;
        component.save();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify onClose method', () => {
        component.onClose();
        expect(modalRef.hide).toHaveBeenCalled();
    });

    it('verify isDirty method with valid name', () => {
        component.form = new NgForm(null, null);
        component.form.form.addControl('name', new FormControl(null, Validators.required));
        component.form.controls.name.setValue({ key: '123', value: 'Test name' });
        component.form.controls.name.markAsDirty();
        component.name = { key: '123', value: 'Test name' };
        const result = component.isDirty();
        expect(result).toBeTruthy();
    });

    it('verify isDirty method with bulk action', () => {
        component.requestType = ReminderRequestType.BulkAction;
        component.form = new NgForm(null, null);
        component.form.form.addControl('name', new FormControl(null, Validators.required));
        const result = component.isDirty();
        expect(result).toBeTruthy();
    });

});