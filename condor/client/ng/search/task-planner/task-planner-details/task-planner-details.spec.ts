import { LocalSettingsMock } from 'core/local-settings.mock';
import { BsModalRefMock, IpxNotificationServiceMock } from 'mocks';
import { TaskPlannerServiceMock } from '../task-planner.service.mock';
import { TaskPlannerDetailComponent } from './task-planner-detail';

describe('TaskPlannerDetailComponent', () => {
  let component: TaskPlannerDetailComponent;
  let localSettings: LocalSettingsMock;
  let taskPlannerService: TaskPlannerServiceMock;
  const bsModalRefMock = new BsModalRefMock();
  const ipxNotificationService = new IpxNotificationServiceMock();
  beforeEach(() => {
    localSettings = new LocalSettingsMock();
    taskPlannerService = new TaskPlannerServiceMock();
    component = new TaskPlannerDetailComponent(localSettings as any, taskPlannerService as any, ipxNotificationService as any, bsModalRefMock as any);
  });

  it('should call Oninit if showReminderComments is true and showEventNotes false', () => {
    const testQueryParams = {
      skip: 0,
      take: 10
    };
    component.taskPlannerRowKey = '1';
    component.showReminderComments = true;
    component.ngOnInit();
    component.gridOptions.read$(testQueryParams);
    expect(component.gridOptions.columns.length).toEqual(1);
    expect(component.taskPlannerDetails.length).toEqual(1);
  });

  it('should call getEventNoteType and getEventNotesDetails', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = true;
    component.ngOnInit();
    expect(taskPlannerService.getEventNoteTypes$).toHaveBeenCalled();
    expect(taskPlannerService.getEventNotesDetails$).toHaveBeenCalledWith(component.taskPlannerRowKey);
  });

  it('should set showEventNotes local storage session to true on expand', () => {
    spyOn(component.onEventNoteUpdate, 'emit');
    component.handelOnEventNoteUpdate(1);
    expect(component.onEventNoteUpdate.emit).toHaveBeenCalledWith(1);
  });

  it('verify handelOnNoteOrCommentDirty method', () => {
    spyOn(component.onTaskDetailChange, 'emit');
    const event = { isDirty: true, taskPlannerRowKey: 'C^23^55' };
    component.handleOnNoteOrCommentChange(event);
    expect(component.onTaskDetailChange.emit).toHaveBeenCalledWith(event);
  });

  it('should set updated ReminderComments timestamp', () => {
    spyOn(component.onReminderCommentUpdate, 'emit');
    component.handelOnReminderCommentUpdate(1);
    expect(component.onReminderCommentUpdate.emit).toHaveBeenCalledWith(1);
  });
  it('should set showReminderComments local storage session to true on expand', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = false;
    component.onExpand({ dataItem: { detail: 'Reminder Comments' } });

    expect(localSettings.keys.taskPlanner.showReminderComments.setSession).toBeCalledWith(true);
  });
  it('should set showReminderComments local storage session to false on collapse', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = false;
    component.onCollapse({ dataItem: { detail: 'Reminder Comments' } });

    expect(localSettings.keys.taskPlanner.showReminderComments.setSession).toBeCalledWith(false);
  });

  it('should set showReminderComments local storage session to false on collapse when row edited is true', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = false;
    component.notifyCommentChange = true;
    const event = { dataItem: { detail: 'Reminder Comments' }, prevented: false };
    component.onCollapse(event);

    expect(event.prevented).toEqual(true);
  });

  it('expand/collapse on basis of localsettings key session value', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = false;
    component.showReminderComments = true;
    component.grid = {
      checkChanges: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      wrapper: {
        data: []
      }
    } as any;
    const collapseRowSpy = component.grid.wrapper.collapseRow = jest.fn();
    const expandRowSpy = component.grid.wrapper.expandRow = jest.fn();
    localSettings.keys.taskPlanner.showReminderComments.setSession(true);
    localSettings.keys.taskPlanner.showEventNotes.setSession(false);
    component.ngAfterViewInit();
    expect(expandRowSpy).toBeCalledWith(0);
  });
  it('expand/collapse on basis of expand action', () => {
    component.taskPlannerRowKey = '1';
    component.showEventNotes = false;
    component.showReminderComments = true;
    component.grid = {
      checkChanges: jest.fn(),
      isValid: jest.fn(),
      isDirty: jest.fn(),
      wrapper: {
        data: []
      }
    } as any;
    const collapseRowSpy = component.grid.wrapper.collapseRow = jest.fn();
    const expandRowSpy = component.grid.wrapper.expandRow = jest.fn();
    localSettings.keys.taskPlanner.showReminderComments.setSession(true);
    localSettings.keys.taskPlanner.showEventNotes.setSession(false);
    component.expandAction = 'C';
    component.ngAfterViewInit();
    expect(expandRowSpy).toBeCalledWith(0);
    expect(collapseRowSpy).toHaveBeenCalled();
    component.expandAction = 'N';
    component.ngAfterViewInit();
    expect(expandRowSpy).toBeCalledWith(0);
    expect(collapseRowSpy).toHaveBeenCalled();
  });
});