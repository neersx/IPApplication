import { CaseSummaryServiceMock } from 'accounting/time-recording/case-summary-details/case-summary-service.mock';
import { DateServiceMock } from 'ajs-upgraded-providers/mocks/date-service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { WindowRefMock } from 'core/window-ref.mock';
import { HttpClientMock, NotificationServiceMock } from 'mocks';
import { FeatureDetectionMock } from 'mocks/feature-detection.mock';
import { of } from 'rxjs';
import { TaskPlannerService } from '../task-planner.service';
import { CaseSummaryComponent } from './case-summary.component';

describe('Case Names and Critical Dates Summary', () => {
    let component: CaseSummaryComponent;
    let taskPlannerService: TaskPlannerService;
    let dateService: DateServiceMock;
    let localSettings: LocalSettingsMock;
    let caseSummaryService: CaseSummaryServiceMock;
    let windowRefMock: WindowRefMock;
    let nservice: NotificationServiceMock;
    let featureDetection: FeatureDetectionMock;

    beforeEach(() => {
        dateService = new DateServiceMock();
        taskPlannerService = new TaskPlannerService(HttpClientMock as any, {} as any, {} as any);
        localSettings = new LocalSettingsMock();
        caseSummaryService = new CaseSummaryServiceMock();
        windowRefMock = new WindowRefMock();
        featureDetection = new FeatureDetectionMock();
        nservice = new NotificationServiceMock();
        component = new CaseSummaryComponent(caseSummaryService as any
            , taskPlannerService as any, {} as any
            , localSettings as any,
            windowRefMock as any,
            featureDetection as any,
            nservice as any);
    });

    describe('loading the component', () => {
        it('initialize component', () => {
            component.ngOnInit();
            expect(component.showCaseSummary).toBeTruthy();
            expect(component.showCaseNames).toBeTruthy();
            expect(component.showCriticalDates).toBeTruthy();
            expect(component.hideTaskDetails).toBeFalsy();
        });
        it('toggle showcase summary', () => {
            component.showCaseSummary = true;
            component.toggleShowCaseSummary();
            expect(component.showCaseSummary).toBeFalsy();
            expect(localSettings.keys.taskPlanner.summary.caseSummary.setSession).toBeCalledWith(false);
        });

        it('toggle showTaskDetails summary', () => {
            component.hideTaskDetails = true;
            component.toggleShowTaskDetails();
            expect(component.hideTaskDetails).toBeFalsy();
            expect(localSettings.keys.taskPlanner.summary.taskDetails.setSession).toBeCalledWith(false);
        });

        it('toggle case names', () => {
            component.showCaseNames = true;
            component.toggleShowCaseNames();
            expect(component.showCaseNames).toBeFalsy();
            expect(localSettings.keys.taskPlanner.summary.caseNames.setSession).toBeCalledWith(false);
        });

        it('toggle case critical dates', () => {
            component.showCriticalDates = true;
            component.toggleShowCriticalDates();
            expect(component.showCriticalDates).toBeFalsy();
            expect(localSettings.keys.taskPlanner.summary.criticalDates.setSession).toBeCalledWith(false);
        });

        it('verify sendEmail', () => {
            const email = 'xyz@email.com';
            const emailContent = { subject: 'subject test', body: 'body test' };
            component.emailContent = emailContent;
            component.sendEmail(email);
            const emailUrl = 'mailto:' + email + '?subject=' + encodeURIComponent(emailContent.subject) + '&body=' + encodeURIComponent(emailContent.body);
            expect(windowRefMock.nativeWindow.open).toBeCalledWith(emailUrl, '_blank');
        });

        it('verify Ad Hoc Date For in More Details panel', () => {
            const taskSummary = { type: 'A', eventDescription: 'test', emailSubject: 'subject test', emailBody: 'body test', adhocResponsibleName: 'Grey', forwardedFrom: '' };
            component.taskSummary = taskSummary;
            component.getTaskDetailsSummary();
            expect(component.taskSummary.adhocResponsibleName).toEqual('Grey');
        });

    });

    describe('loading the data', () => {
        it('calls the service to retrieve case summary details', () => {
            const caseSummarySpy = spyOn(taskPlannerService, 'getSearchResultsViewData').and.returnValue(of());
            component.caseKey = 1234;
            taskPlannerService.rowSelected.next(component.caseKey);
            // tslint:disable-next-line: no-unbound-method
            taskPlannerService.rowSelected.subscribe(() => {
                expect(caseSummarySpy).toHaveBeenCalledWith(1234);
            });
        });
    });

    describe('taskplanner summary', () => {
        it('calls getTaskDetailsSummary service', () => {
            spyOn(taskPlannerService, 'taskPlannerRowKey').and.returnValue(of());
            component.getTaskDetailsSummary();
            taskPlannerService.rowSelected.next(component.caseKey);
            // tslint:disable-next-line: no-unbound-method
            taskPlannerService.rowSelected.subscribe(() => {
                expect(caseSummaryService.getTaskDetailsSummary).toHaveBeenCalled();
                expect(component.taskPlannerKey).toBeDefined();
            });
        });

        it('calls getEmailContent service', () => {
            spyOn(taskPlannerService, 'taskPlannerRowKey').and.returnValue(of());
            component.getEmailContent();
            taskPlannerService.rowSelected.next(component.caseKey);
            // tslint:disable-next-line: no-unbound-method
            taskPlannerService.rowSelected.subscribe(() => {
                expect(taskPlannerService.getEmailContent).toHaveBeenCalled();
                expect(component.taskPlannerKey).toBeDefined();
            });
        });
    });

    describe('taskplanner toCaseDetails', () => {
        it('calls notificationService.ieRequired ', () => {
            const caseData = {
                irn: '1234/a',
                caseKey: 1
            };
            const caseUrl = 'http://localhost/apps/?caseref=' + encodeURIComponent(caseData.irn);
            component.isIe = false;
            component.inproVersion16 = false;
            featureDetection.getAbsoluteUrl.mockReturnValue(caseUrl);
            component.toCaseDetails(caseData);
            expect(featureDetection.getAbsoluteUrl).toHaveBeenCalledWith('?caseref=' + encodeURIComponent(caseData.irn));
            expect(nservice.ieRequired).toHaveBeenCalledWith(caseUrl.replace('/apps/?caseref=', '/?caseref='));
        });

        it('calls windoeRef.nativeWindow.open ', () => {
            const caseData = {
                irn: '1234/a',
                caseKey: 1
            };
            const caseViewLink = 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ caseKey: caseData.caseKey }));
            component.isIe = true;
            component.toCaseDetails(caseData);
            expect(windowRefMock.nativeWindow.open).toHaveBeenCalledWith(caseViewLink, '_blank');
        });

    });
});
