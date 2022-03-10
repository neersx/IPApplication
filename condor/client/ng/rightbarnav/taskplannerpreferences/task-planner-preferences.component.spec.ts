import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { TaskPlannerPreferencesComponent } from './task-planner-preferences.component';

describe('TaskPlannerPreferencesComponent', () => {
    let c: TaskPlannerPreferencesComponent;
    let cdref: ChangeDetectorRefMock;
    let notifications: NotificationServiceMock;
    let taskPlannerService: TaskPlannerServiceMock;
    let rightBarNav: RightBarNavServiceMock;
    let ipxNotificationService: IpxNotificationServiceMock;

    beforeEach(() => {
        cdref = new ChangeDetectorRefMock();
        notifications = new NotificationServiceMock();
        taskPlannerService = new TaskPlannerServiceMock();
        rightBarNav = new RightBarNavServiceMock();
        ipxNotificationService = new IpxNotificationServiceMock();
        c = new TaskPlannerPreferencesComponent(cdref as any, taskPlannerService as any, rightBarNav as any, notifications as any, ipxNotificationService as any);
        c.viewData = { maintainTaskPlannerSearch: true, defaultTabsData: [], preferenceData: { autoRefreshGrid: true, tabs: [] } };
    });

    it('should create', () => {
        expect(c).toBeTruthy();
    });

    it('validate ngOnInit', () => {
        c.ngOnInit();
        expect(cdref.markForCheck).toHaveBeenCalled();
    });

    it('validate toggle', () => {
        c.toggle(true);
        expect(c.formData.autoRefreshGrid).toBeTruthy();
    });

    it('validate close', () => {
        c.close();
        expect(rightBarNav.onCloseRightBarNav$.next).toHaveBeenCalledWith(true);
    });

    it('validate submit', () => {
        c.formData.autoRefreshGrid = true;
        c.formData.tabs = [];
        c.submit();
        expect(taskPlannerService.setUserPreference).toHaveBeenCalledWith(c.formData);
    });

});
