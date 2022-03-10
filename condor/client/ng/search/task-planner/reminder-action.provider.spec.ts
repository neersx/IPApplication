import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { WindowRefMock } from 'core/window-ref.mock';
import { AdhocDateServiceMock } from 'dates/adhoc-date.service.mock';
import { DateHelperMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { Observable } from 'rxjs';
import { TaskPlannerServiceMock } from 'search/task-planner/task-planner.service.mock';
import { ReminderActionProvider } from './reminder-action.provider';
import { ReminderRequestType } from './task-planner.data';

describe('ReminderActionProvider', () => {

    let service: ReminderActionProvider;
    let taskPlannerService: TaskPlannerServiceMock;
    let notificationService: NotificationServiceMock;
    let commonUtilityServiceMock: CommonUtilityServiceMock;
    let translateServiceMock: TranslateServiceMock;
    let adhocDateServiceMock: AdhocDateServiceMock;
    let dateHelperMock: DateHelperMock;
    let modalServiceMock: ModalServiceMock;
    let windowRefMock: WindowRefMock;
    const provideInstructionsServiceMock = { getProvideInstructions: jest.fn().mockReturnValue(new Observable()) };

    beforeEach(() => {
        taskPlannerService = new TaskPlannerServiceMock();
        notificationService = new NotificationServiceMock();
        commonUtilityServiceMock = new CommonUtilityServiceMock();
        translateServiceMock = new TranslateServiceMock();
        dateHelperMock = new DateHelperMock();
        modalServiceMock = new ModalServiceMock();
        adhocDateServiceMock = new AdhocDateServiceMock();
        windowRefMock = new WindowRefMock();
        service = new ReminderActionProvider(notificationService as any,
            taskPlannerService as any,
            modalServiceMock as any,
            dateHelperMock as any,
            commonUtilityServiceMock as any,
            translateServiceMock as any,
            {} as any,
            adhocDateServiceMock as any,
            windowRefMock as any,
            provideInstructionsServiceMock as any);
    });

    it('should create the service', () => {
        expect(service).toBeTruthy();
    });

    it('verify deferReminders', () => {
        const rowKeys = ['A^12^3434^788^445'];
        const holdDate = new Date();
        service.deferReminders(ReminderRequestType.InlineTask, rowKeys, holdDate, null);
        expect(taskPlannerService.deferReminders).toHaveBeenCalledWith(ReminderRequestType.InlineTask, rowKeys, holdDate, null);
    });

    it('verify deferRemindersToEnteredDate', () => {
        const rowKeys = ['A^12^3434^788^445'];
        service.deferRemindersToEnteredDate(ReminderRequestType.InlineTask, rowKeys, null);
        expect(modalServiceMock.openModal).toHaveBeenCalled();
    });

    it('verify changeDueDateResponsibility with inline', () => {
        const rowKey = 'A^12^3434^788^445';
        service.changeDueDateResponsibility([rowKey], null, ReminderRequestType.InlineTask);
        expect(taskPlannerService.getDueDateResponsibility).toHaveBeenCalledWith(rowKey);
    });

    it('verify changeDueDateResponsibility with bulk', () => {
        const rowKeys = ['A^12^3434^788^445'];
        service.changeDueDateResponsibility(rowKeys, null, ReminderRequestType.BulkAction);
        expect(modalServiceMock.openModal).toHaveBeenCalled();
        expect(service.modalRef.content.saveClicked).toBeDefined();
    });

    it('verify single finalise', () => {
        const rowKeys = 'A^12^3434^788^445^1';
        const viewData = {
            resolveReasons: [{
                userCode: '3',
                description: 'Event Occurred'
            }]
        };

        service.finalise(rowKeys, viewData);

        expect(adhocDateServiceMock.adhocDate).toBeCalled();
        expect(modalServiceMock.openModal).toHaveBeenCalled();
    });

    it('verify bulk finalise', () => {
        const rowKeys = ['A^12^3434^788^445^1'];
        const viewData = {
            resolveReasons: [{
                userCode: '3',
                description: 'Event Occurred'
            }]
        };

        service.bulkFinalise(rowKeys, null, viewData);

        expect(modalServiceMock.openModal).toHaveBeenCalled();
        expect(service.modalRef.content.finaliseClicked).toBeDefined();
    });

    it('verify sendEmails', () => {
        const rowKeys = ['A^12^3434'];
        service.sendEmails(rowKeys, null);
        expect(modalServiceMock.openModal).toHaveBeenCalled();
        expect(service.modalRef.content.sendClicked).toBeDefined();
    });

    it('verify provideInstructions', () => {
        const rowKey = 'C^12^3434';
        service.provideInstructions(rowKey, null);
        expect(provideInstructionsServiceMock.getProvideInstructions).toHaveBeenCalledWith(rowKey);
    });

});
