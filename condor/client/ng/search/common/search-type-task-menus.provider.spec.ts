import { TimeRecordingHelper } from 'accounting/time-recording-widget/time-recording-helper';
import { TimeRecordingTimerGlobalService } from 'accounting/time-recording-widget/time-recording-timer-global.service';
import { TimeRecordingTimerGlobalServiceMock } from 'accounting/time-recording-widget/time-recording-timer-global.service.mock';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { InjectorMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { Observable } from 'rxjs';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { ReminderActionProviderMock } from 'search/task-planner/reminder-action.provider.mock';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import * as _ from 'underscore';
import { CaseWebLinksTaskProviderMock } from './case-web-links-task-provider.mock';
import { SearchTypeTaskMenusProvider } from './search-type-task-menus.provider';

describe('SearchTypeTaskMenusProvider', () => {

    let service: SearchTypeTaskMenusProvider;
    const windowParentMessagingService = new WindowParentMessagingServiceMock();
    const stateService = new StateServiceMock();
    const appContextService = new AppContextServiceMock();
    const injector = new InjectorMock();
    let taskPlannerService: TaskPlannerServiceMock;
    let notificationService: NotificationServiceMock;
    let reminderActionProvider: ReminderActionProviderMock;
    const adhocDateService = { caseEventDetails: jest.fn().mockReturnValue(new Observable()), viewData: jest.fn().mockReturnValue(new Observable()) };
    const attachmentModalService = new AttachmentModalServiceMock();
    const caseWebLinksProvider = new CaseWebLinksTaskProviderMock();
    const billSearchProvider = {
        reverseBill: jest.fn().mockReturnValue(new Observable()),
        deleteDraftBill: jest.fn().mockReturnValue(new Observable()),
        canDeleteBill: jest.fn(),
        canReverseBill: jest.fn()
    };

    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        notificationService = new NotificationServiceMock();
        reminderActionProvider = new ReminderActionProviderMock();
        service = new SearchTypeTaskMenusProvider(
            windowParentMessagingService as any,
            stateService as any,
            {} as any,
            injector,
            appContextService as any,
            taskPlannerService as any,
            notificationService as any,
            reminderActionProvider as any,
            adhocDateService as any,
            attachmentModalService as any,
            caseWebLinksProvider as any,
            billSearchProvider as any
        );
    });

    it('should load task menu configuration service', () => {
        expect(service).toBeTruthy();
    });

    it('validate initializeContext', () => {
        const permissions = {
            canUpdateEventsInBulk: true,
            canMaintainCase: true
        };
        const viewData = {
            programs: []
        };
        service.initializeContext(permissions, queryContextKeyEnum.nameSearch, true, viewData);
        expect(service.queryContextKey).toEqual(queryContextKeyEnum.nameSearch);
        expect(service.permissions).toEqual(permissions);
        expect(service.isHosted).toBeTruthy();
    });

    describe('Case Search TaskMenu', () => {
        it('validate getConfigurationTaskMenuItems with editcase and firstToFile menus', () => {
            const dataItem = {
                caseKey: 233,
                CaseReference: '1234/a',
                isEditable: true
            };

            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canMaintainCase: true,
                canOpenWorkflowWizard: true,
                canOpenDocketingWizard: true,
                canMaintainFileTracking: true,
                canOpenFirstToFile: true,
                canOpenWipRecord: false,
                canOpenCopyCase: false
            };

            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results.length).toEqual(3);
            expect(results[0].id).toEqual('editCase');
            expect(results[0].items.length).toEqual(4);
            expect(results[1].id).toEqual('OpenFirstToFile');
        });

        it('validate getConfigurationTaskMenuItems with RecordWip and CopyCase menus', () => {
            const dataItem = {
                caseKey: '233',
                CaseReference: '1234/a',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canMaintainCase: false,
                canOpenWorkflowWizard: false,
                canOpenDocketingWizard: false,
                canMaintainFileTracking: false,
                canOpenFirstToFile: false,
                canOpenWipRecord: true,
                canOpenCopyCase: true,
                canAccessDocumentsFromDms: true

            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results.length).toEqual(4);
            expect(results[0].id).toEqual('RecordWip');
            expect(results[1].id).toEqual('OpenDms');
            expect(results[2].id).toEqual('CopyCase');
        });

        it('validate getConfigurationTaskMenuItems with RecordTime, OpenReminders and CreateAdHocDate menus', () => {
            const dataItem = {
                caseKey: '233',
                CaseReference: '1234/a',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canMaintainCase: false,
                canOpenWorkflowWizard: false,
                canOpenDocketingWizard: false,
                canMaintainFileTracking: false,
                canOpenFirstToFile: false,
                canOpenWipRecord: false,
                canOpenCopyCase: false,
                canRecordTime: true,
                canOpenReminders: true,
                canCreateAdHocDate: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem);
            expect(results.length).toEqual(3);
            expect(results[0].id).toEqual('OpenReminders');
            expect(results[1].id).toEqual('CreateAdHocDate');
        });

        it('validate getConfigurationTaskMenuItems with RequestCaseFile menu', () => {
            const dataItem = {
                caseKey: '233',
                CaseReference: '1234/a',
                isEditable: true
            };

            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canMaintainCase: false,
                canOpenWorkflowWizard: false,
                canOpenDocketingWizard: false,
                canMaintainFileTracking: false,
                canOpenFirstToFile: false,
                canOpenWipRecord: false,
                canOpenCopyCase: false,
                canRecordTime: false,
                canOpenReminders: false,
                canCreateAdHocDate: false,
                canRequestCaseFile: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem);
            expect(results.length).toEqual(2);
            expect(results[0].id).toEqual('RequestCaseFile');
        });

        it('validate getConfigurationTaskMenuItems with openWithProgram', () => {
            const dataItem = {
                caseKey: '233',
                CaseReference: '1234/a',
                isEditable: true
            };

            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.viewData = {
                programs: [{
                    id: 'openWithProgram1',
                    name: 'Program One'
                },
                {
                    id: 'openWithProgram2',
                    name: 'Program Two'
                }]
            };
            service.permissions = {

            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results.length).toEqual(2);
            expect(results[0].id).toEqual('openWithProgram');
            expect(results[0].items.length).toEqual(2);
            expect(results[0].items[0].id).toEqual('openWithProgram1');
            expect(results[0].items[1].id).toEqual('openWithProgram2');
        });

        it('validate getConfigurationTaskMenuItems with MaintainTimeViaTimeRecording', () => {
            const dataItem = {
                caseKey: -999,
                CaseReference: '1234/a',
                isEditable: true
            };
            service.isHosted = false;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canUseTimeRecording: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem);
            expect(results.length).toEqual(3);
            expect(results[0].id).toEqual('RecordTime');
            expect(results[1].id).toEqual('RecordTimeWithTimer');
        });

        it('recordTime initiates call to perform timeentry', () => {
            const dataItem = {
                caseKey: -999,
                CaseReference: '1234/a',
                isEditable: true
            };
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canUseTimeRecording: true
            };

            const initiateTimeEntrySpy = jest.spyOn(TimeRecordingHelper, 'initiateTimeEntry');
            const results = service.getConfigurationTaskMenuItems(dataItem);
            results[0].action();
            expect(initiateTimeEntrySpy).toHaveBeenCalledWith(dataItem.caseKey);
        });

        it('recordTimer initiates call to start timer via global timer service', () => {
            const dataItem = {
                caseKey: -999,
                CaseReference: '1234/a',
                isEditable: true
            };
            service.isHosted = false;
            service.queryContextKey = queryContextKeyEnum.caseSearch;
            service.permissions = {
                canUseTimeRecording: true
            };
            const timerServiceMock = new TimeRecordingTimerGlobalServiceMock();
            injector.get.mockReturnValueOnce(timerServiceMock);
            const results = service.getConfigurationTaskMenuItems(dataItem);
            results[1].action();
            expect(injector.get).toHaveBeenCalledWith(TimeRecordingTimerGlobalService);
            expect(timerServiceMock.startTimerForCase).toHaveBeenCalledWith(dataItem.caseKey);
        });
    });

    describe('Name Search TaskMenu', () => {
        it('validate getConfigurationTaskMenuItems with editName', () => {
            const dataItem = {
                nameKey: '233',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.nameSearch;
            service.permissions = {
                canMaintainName: true,
                canMaintainNameNotes: true,
                canMaintainNameAttributes: true,
                canMaintainOpportunity: true,
                canMaintainAdHocDate: true,
                canMaintainContactActivity: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results[0].id).toEqual('editName');
            expect(results[0].items.length).toEqual(3);
        });

        it('It should return task menu items for adHocDateForName, newActivityWizardForName and newOpportunityForName', () => {
            const dataItem = {
                nameKey: '233',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.nameSearch;
            service.permissions = {
                canMaintainAdHocDate: true,
                canMaintainContactActivity: true,
                canMaintainOpportunity: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results[0].id).toEqual('AdHocDateForName');
            expect(results[1].id).toEqual('NewActivityWizardForName');
            expect(results[2].id).toEqual('NewOpportunityForName');
        });

        it('It should return only permitted task menu items for editName', () => {
            const dataItem = {
                nameKey: '233',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.nameSearch;
            service.permissions = {
                canMaintainName: true,
                canMaintainNameNotes: false,
                canMaintainNameAttributes: true,
                canMaintainOpportunity: true,
                canMaintainAdHocDate: false,
                canMaintainContactActivity: true
            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results.length).toEqual(3);
            expect(results[0].id).toEqual('editName');
            expect(results[0].items.length).toEqual(2);
        });

        it('It should return none when no permission is granted', () => {
            const dataItem = {
                nameKey: '233',
                isEditable: true
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.nameSearch;
            service.permissions = {
                canMaintainName: false,
                canMaintainNameNotes: false,
                canMaintainNameAttributes: false
            };
            const results = service.getConfigurationTaskMenuItems(dataItem) as any;
            expect(results.length).toEqual(0);
        });
    });

    describe('Prior Art Search TaskMenu', () => {
        it('validate getConfigurationTaskMenuItems with MaintainPriorArt', () => {
            const dataItem = {
                priorArtKey: '233'
            };
            service.isHosted = true;
            service.queryContextKey = queryContextKeyEnum.priorArtSearch;
            service.permissions = {
                canMaintainPriorArt: true
            };

            const result = service.getConfigurationTaskMenuItems(dataItem);
            const isExist = _.any(result, item => { return item.id === 'MaintainPriorArt'; });
            expect(isExist).toBeTruthy();
        });
    });

    describe('Time Recording task menus - when task security is not given', () => {
        beforeAll(() => {
            service.viewData = { canFinaliseAdhocDate: true };
            appContextService.appContext = {
                user: {
                    permissions: {
                        canAccessTimeRecording: false
                    }
                }
            };
        });

        it('does not add record time menu, when user does not have task security', () => {
            const result = service.configureTaskPlannerMenuItems({ caseKey: 10 });
            const isExist = _.any(result, item => { return item.id === 'Recordtime'; });
            expect(isExist).toBeFalsy();
        });
    });

    describe('Time Recording task menus - when task security is given', () => {
        let initiateTimeEntrySpy: any;
        let timerServiceMock: TimeRecordingTimerGlobalServiceMock;
        beforeAll(() => {
            appContextService.appContext = {
                user: {
                    permissions: {
                        canAccessTimeRecording: true
                    }
                }
            };
            initiateTimeEntrySpy = jest.spyOn(TimeRecordingHelper, 'initiateTimeEntry');
            timerServiceMock = new TimeRecordingTimerGlobalServiceMock();
            injector.get.mockReturnValue(timerServiceMock);
        });

        it('record time with timer triggers call to timer global service for starting timer', () => {
            expect(injector.get).toHaveBeenCalled();
            const record = { caseKey: 10 };
            service.configureTaskPlannerMenuItems(record);
            expect(timerServiceMock.startTimerForCase).toBeDefined();
        });
    });

    describe('Add Attachment task menu - when task security is given', () => {
        const getAttachmentMenu = (): any => {
            return _.find(service._baseTasks, (t) => {
                return t.menu.id === 'addAttachment';
            });
        };

        it('init TaskPlannerBase Tasks', () => {
            service.configureTaskPlannerMenuItems({ caseKey: 10 });
            expect(service._baseTasks.length).toEqual(18);
        });

        it('add attachment is initiated', () => {
            expect(injector.get).toHaveBeenCalled();
            const record = { caseKey: 10, eventKey: 19, eventCycle: 11, actionKey: 'OK' };
            service.configureTaskPlannerMenuItems(record);
            const attachmentMenu = getAttachmentMenu();
            attachmentMenu.menu.action(record);
            expect(attachmentModalService.triggerAddAttachment).toBeCalled();
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][0]).toEqual('case');
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][1]).toEqual(10);
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][2].eventKey).toEqual(record.eventKey);
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][2].eventCycle).toEqual(record.eventCycle);
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][2].actionKey).toEqual(record.actionKey);
        });

        it('addAttachment is not displayed, if task security is not provided', () => {
            const record = { caseKey: 10, eventKey: 19, eventCycle: 11, actionKey: 'OK' };
            service.configureTaskPlannerMenuItems(record);
            const attachmentMenu = getAttachmentMenu();
            expect(attachmentMenu.evalAvailable(record)).toBeFalsy();
        });

        it('addAttachment is displayed, if task security is provided', () => {
            const record = { caseKey: 10, eventKey: 19, eventCycle: 11, actionKey: 'OK' };
            service.viewData = { canAddCaseAttachments: true };
            service.configureTaskPlannerMenuItems(record);
            const attachmentMenu = getAttachmentMenu();
            expect(attachmentMenu.evalAvailable(record)).toBeTruthy();
        });
    });

    describe('task planner task menus', () => {

        it('add remove reminder menu, when reminderDeleteButton is 0 or 2', () => {
            service.viewData = { reminderDeleteButton: 2 };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234' });
            const isExist = _.any(result, item => { return item.id === 'dismissReminder'; });
            expect(isExist).toBeTruthy();
        });

        it('does not add remove reminder menu, when reminderDeleteButton is 1', () => {
            service.viewData = { reminderDeleteButton: 1 };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234' });
            const isExist = _.any(result, item => { return item.id === 'dismissReminder'; });
            expect(isExist).toBeFalsy();
        });

        it('does not add remove reminder menu, when it is due date reminder', () => {
            taskPlannerService.hasEmployeeReminder = jest.fn().mockReturnValue(false);
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(false);
            taskPlannerService.isReminderOrAdHoc = jest.fn().mockReturnValue(false);
            service.viewData = { reminderDeleteButton: 2 };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^123' });
            const isExist = _.any(result, item => { return item.id === 'dismissReminder'; });
            expect(isExist).toBeFalsy();
        });

        it('add defer reminder menu, when it is adhoc date or reminder', () => {
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234' });
            const isExist = _.any(result, item => { return item.id === 'deferReminder'; });
            expect(isExist).toBeTruthy();
        });

        it('does not add defer reminder menu, when it is due date reminder', () => {
            taskPlannerService.hasEmployeeReminder = jest.fn().mockReturnValue(false);
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(false);
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^123' });
            const isExist = _.any(result, item => { return item.id === 'deferReminder'; });
            expect(isExist).toBeFalsy();
        });

        it('add unread reminder menu, when it is in read state', () => {
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234', isRead: true });
            const isExist = _.any(result, item => { return item.id === 'unreadReminder'; });
            expect(isExist).toBeTruthy();
        });

        it('add read reminder menu, when it is in unread state', () => {
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'readReminder'; });
            expect(isExist).toBeTruthy();
        });

        it('add changeDueDateResponsibility inline taskmenu', () => {
            service.viewData = { canChangeDueDateResponsibility: true };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'changeDueDateResponsibility'; });
            expect(isExist).toBeTruthy();
        });

        it('does not add changeDueDateResponsibility and forwardReminder inline taskmenus', () => {
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(true);
            taskPlannerService.hasEmployeeReminder = jest.fn().mockReturnValue(true);
            taskPlannerService.isReminderOrAdHoc = jest.fn().mockReturnValue(true);
            service.viewData = { canChangeDueDateResponsibility: false };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'changeDueDateResponsibility'; });
            expect(isExist).toBeFalsy();
        });

        it('add provideInstructions inline taskmenu', () => {
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(true);
            service.viewData = { provideDueDateInstructions: true };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^1234', isRead: false, hasInstructions: true });
            const isExist = _.any(result, item => { return item.id === 'provideInstructions'; });
            expect(isExist).toBeTruthy();
        });

        it('does not add provideInstructions inline taskmenus if it is not due date or reminder', () => {
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(false);
            service.viewData = { provideDueDateInstructions: true };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'A^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'provideInstructions'; });
            expect(isExist).toBeFalsy();
        });

        it('does not add provideInstructions inline taskmenus if does not have provideDueDateInstructions task security', () => {
            taskPlannerService.isReminderOrDueDate = jest.fn().mockReturnValue(true);
            service.viewData = { provideDueDateInstructions: false };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'provideInstructions'; });
            expect(isExist).toBeFalsy();
        });

        it('add forwardReminder inline taskmenu', () => {
            service.viewData = { canChangeDueDateResponsibility: true };
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'forwardReminder'; });
            expect(isExist).toBeTruthy();
        });

        it('add SendEmail inline taskmenu', () => {
            const result = service.configureTaskPlannerMenuItems({ taskPlannerRowKey: 'C^45^1234', isRead: false });
            const isExist = _.any(result, item => { return item.id === 'sendEmail'; });
            expect(isExist).toBeTruthy();
        });

        it('should call openAdHoc', () => {
            const taskPlannerRowKey = 'C^45^1234';
            service.openAdHoc(taskPlannerRowKey);
            expect(adhocDateService.caseEventDetails).toHaveBeenCalled();
            expect(adhocDateService.viewData).toHaveBeenCalled();
        });
    });
});