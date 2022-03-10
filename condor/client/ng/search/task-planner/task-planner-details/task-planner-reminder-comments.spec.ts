import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { DateServiceMock } from 'ajs-upgraded-providers/mocks/date-service.mock';
import { ChangeDetectorRefMock, IpxGridOptionsMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { TaskPlannerServiceMock } from '../task-planner.service.mock';
import { TaskPlannerReminderCommentsComponent } from './task-planner-reminder-comments';

describe('TaskPlannerReminderCommentsComponent', () => {
    let component: TaskPlannerReminderCommentsComponent;
    let taskPlannerService: TaskPlannerServiceMock;
    let dateService: DateServiceMock;
    let cdRef: ChangeDetectorRefMock;
    const ipxNotificationService = new IpxNotificationServiceMock();
    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        dateService = new DateServiceMock();
        cdRef = new ChangeDetectorRefMock();
        component = new TaskPlannerReminderCommentsComponent(taskPlannerService as any, dateService as any, new FormBuilder(),
            NotificationServiceMock as any, ipxNotificationService as any, cdRef as any);
        component.gridOptions = new IpxGridOptionsMock() as any;
        component._resultsGrid = new IpxKendoGridComponentMock() as any;
    });
    it('should call Oninit', () => {
        const testQueryParams = {
            skip: 0,
            take: 10
        };
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toEqual(3);
        component.gridOptions.read$(testQueryParams);
        expect(taskPlannerService.reminderComments).toHaveBeenCalledWith(component.taskPlannerRowKey);
    });

    it('should create formgroup', () => {
        component.formGroup = new FormGroup({
            staffNameKey: new FormControl(),
            comments: new FormControl()
        });
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        component.reminderFor = 'John';
        const dataitem = { staffNameKey: 0, status: 'A' };
        component.createFormGroup(dataitem);
        expect(component.gridOptions.enableGridAdd).toEqual(false);
    }
    );

    it('should  onReset', () => {
        component.formGroup = new FormGroup({
            staffNameKey: new FormControl(0),
            comments: new FormControl()
        });
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        component.reminderFor = 'John';
        const dataitem = { staffNameKey: 0, status: 'A' };
        component.createFormGroup(dataitem);
        taskPlannerService.isCommentDirty$.next({ rowKey: 0, dirty: true });
        component.onReset();
        expect(component.gridOptions.enableGridAdd).toEqual(false);
        expect(component.formGroup.controls.comments.value).toEqual(null);
    });

    it('should save form', () => {
        component.formGroup = new FormGroup({
            staffNameKey: new FormControl(0),
            comments: new FormControl(['Home'])
        });
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        component.reminderFor = 'John';
        const dataitem = { staffNameKey: 0, status: 'A' };
        component.createFormGroup(dataitem);
        component.onSave();
        expect(component.gridOptions.enableGridAdd).toEqual(false);
        expect(taskPlannerService.saveReminderComment).toHaveBeenCalled();
    });

    it('should resetForm', () => {
        component.formGroup = new FormGroup({
            staffNameKey: new FormControl(0),
            comments: new FormControl(['Home'])
        });
        component.currentRowIndex = 1;
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        component.reminderFor = 'John';
        const dataitem = { staffNameKey: 0, status: 'A' };
        component.createFormGroup(dataitem);
        component.grid = new IpxKendoGridComponentMock() as any;
        component.resetForm();
        expect(component.gridOptions.enableGridAdd).toEqual(false);
        expect(component.grid.rowEditFormGroups).toEqual(null);
        expect(component.grid.currentEditRowIdx).toEqual(1);
    });

    it('should close the modal after asking for confirmation if pending changes', () => {
        component.formGroup = new FormGroup({
            staffNameKey: new FormControl(0),
            comments: new FormControl(['Home']),
            dirty: new FormControl('dirty', [Validators.required])
        });
        component.taskPlannerRowKey = '1';
        component.ngOnInit();
        component.reminderFor = 'John';
        const dataitem = { staffNameKey: 0, status: 'A' };
        component.createFormGroup(dataitem);
        component.grid = new IpxKendoGridComponentMock() as any;
        component.rowDiscard();
        expect(component.formGroup.dirty).toBe(false);
    });
});