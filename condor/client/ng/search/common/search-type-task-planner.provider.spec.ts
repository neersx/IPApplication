import { NotificationServiceMock } from 'mocks';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { ReminderActionProviderMock } from 'search/task-planner/reminder-action.provider.mock';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { SearchTypeTaskPlannerProvider } from './search-type-task-planner.provider';

describe('SearchTypeTaskPlannerProvider', () => {

    let service: SearchTypeTaskPlannerProvider;
    let taskPlannerService: TaskPlannerServiceMock;
    let notificationService: NotificationServiceMock;
    let reminderActionProviderMock: ReminderActionProviderMock;
    const searchHelperService = {};

    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        notificationService = new NotificationServiceMock();
        reminderActionProviderMock = new ReminderActionProviderMock();
        service = new SearchTypeTaskPlannerProvider(notificationService as any, taskPlannerService as any, reminderActionProviderMock as any, searchHelperService as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('add dismiss reminder bulk item, when reminderDeleteButton is 0', () => {
        const result = service.getConfigurationActionMenuItems(queryContextKeyEnum.taskPlannerSearch, { reminderDeleteButton: 0 });
        expect(result.length).toEqual(4);
        expect(result[0].id).toEqual('dismiss-reminders');
    });

    it('does not add dismiss reminder bulk item, when reminderDeleteButton is 1', () => {
        const result = service.getConfigurationActionMenuItems(queryContextKeyEnum.taskPlannerSearch, { reminderDeleteButton: 1 });
        expect(result.length).toEqual(3);
        expect(result[0].id === 'dismiss-reminders').toBeFalsy();
    });

    it('add mark as bulk item', () => {
        const result = service.getConfigurationActionMenuItems(queryContextKeyEnum.taskPlannerSearch, { reminderDeleteButton: 0 });
        expect(result.length).toEqual(4);
        expect(result[2].id).toEqual('mark-as-read-unread');
    });

    it('add change-due-date-responsibility bulk item', () => {
        const result = service.getConfigurationActionMenuItems(queryContextKeyEnum.taskPlannerSearch, { reminderDeleteButton: 0, canChangeDueDateResponsibility: true });
        expect(result.length).toEqual(5);
        expect(result[3].id).toEqual('change-due-date-responsibility');
    });

    it('add forwardReminders bulk item', () => {
        const result = service.getConfigurationActionMenuItems(queryContextKeyEnum.taskPlannerSearch, { reminderDeleteButton: 0 });
        expect(result.length).toEqual(4);
        expect(result[3].id).toEqual('forward-reminders');
    });

});
