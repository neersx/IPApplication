
import { TimeRecordingHelper } from 'accounting/time-recording-widget/time-recording-helper';
import { TimeRecordingTimerGlobalServiceMock } from 'accounting/time-recording-widget/time-recording-timer-global.service.mock';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, InjectorMock, NotificationServiceMock, StateServiceMock } from 'mocks';
import { FeatureDetectionMock } from 'mocks/feature-detection.mock';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { of } from 'rxjs';
import { BusMock } from '../../mocks/bus.mock';
import { CaseViewComponent } from './case-view.component';

describe('CaseViewComponent', () => {
    let component: CaseViewComponent;
    let caseViewService: any;
    let rghtBarNavServiceMock: RightBarNavServiceMock;
    let cdr: ChangeDetectorRefMock;
    let nservice: NotificationServiceMock;
    let navigationService: any;
    let injector: InjectorMock;
    let appContextService: AppContextServiceMock;
    let kotViewService: any;
    let pageTitleService: any;
    let featureDetection: FeatureDetectionMock;
    let state: StateServiceMock;
    let attachmentModalService: AttachmentModalServiceMock;
    beforeEach(() => {
        caseViewService = { getOverview$: jest.fn(), getCaseProgram$: jest.fn().mockReturnValue(of()), hasPendingChanges$: of() };
        navigationService = { getSelectedTopic: () => 'summary' };
        kotViewService = { getKotForCaseView: jest.fn().mockReturnValue(of()) };
        cdr = new ChangeDetectorRefMock();
        nservice = new NotificationServiceMock();
        rghtBarNavServiceMock = new RightBarNavServiceMock();
        pageTitleService = { setPrefix: jest.fn() };
        appContextService = new AppContextServiceMock();
        featureDetection = new FeatureDetectionMock();
        injector = new InjectorMock();
        state = new StateServiceMock();
        attachmentModalService = new AttachmentModalServiceMock();
        component = new CaseViewComponent(navigationService,
            caseViewService, nservice as any,
            appContextService as any, state as any,
            featureDetection as any, undefined, cdr as any, rghtBarNavServiceMock as any,
            pageTitleService, new BusMock() as any, kotViewService, undefined, injector, attachmentModalService as any, undefined);
    });

    it('should create the component', (() => {
        expect(component).toBeTruthy();
    }));

    xit('should reload topics ', (() => {
        component.topicHost = {
            reloadTopics: jest.fn()
        } as any;
        component.stateParams = { id: 1, rowKey: 1 } as any;
        caseViewService.getOverview$.mockReturnValue(of({ caseId: 1001 }));

        component.reloadTopics();
        expect(component.topicHost.reloadTopics).toHaveBeenCalledWith(['summary']);
        expect(nservice.success).toHaveBeenCalled();
    }));

    it('should create correct topic & sub-topics lists ', (() => {
        component.caseViewData = { canViewOtherNumbers: false };
        component.viewData = { caseId: 1111, imageKey: 111 };
        component.stateParams = { id: 1, rowKey: 1 } as any;
        caseViewService.getOverview$.mockReturnValue(of({ caseId: 1001 }));
        component.screenControl = { topics: [{ name: 'names', id: 1 }, { name: 'actions', id: 2 }, { name: 'events', topics: [] }] };

        component.initializeTopics();

        component.topicHost = {
            reloadTopics: jest.fn()
        } as any;
        component.stateParams = { id: 1, rowKey: 1 } as any;
        caseViewService.getOverview$.mockReturnValue(of({ caseId: 1001 }));
    }));

    describe('time recording related actions - when task security is not provided', () => {
        beforeEach(() => {
            appContextService.appContext = {
                user: {
                    permissions: {
                        canAccessTimeRecording: false
                    }
                }
            };
            component.stateParams = { id: 1, rowKey: 1 } as any;
            component.caseViewData = { canViewOtherNumbers: false };
            component.viewData = {};
            component.ngOnInit();
        });

        it('should not add time recording actions', () => {
            expect(component.topicOptions.actions.length).toBe(0);
        });
    });

    describe('time recording related actions - when task security is provided ', () => {
        beforeEach(() => {
            appContextService.appContext = {
                user: {
                    permissions: {
                        canAccessTimeRecording: true
                    }
                }
            };
            component.stateParams = { id: 1, rowKey: 1 } as any;
            component.viewData = {};
            component.caseViewData = {};
            component.ngOnInit();
        });

        it('should add time recording actions - when task security is provided', () => {
            expect(component.topicOptions.actions.length).toBe(2);
            expect(component.topicOptions.actions[0].key).toBe('recordTime');
            expect(component.topicOptions.actions[1].key).toBe('recordTimeWithTimer');
        });

        it('record time menu, opens a link on trigger', () => {
            const initiateTimeEntrySpy = jest.spyOn(TimeRecordingHelper, 'initiateTimeEntry');
            component.viewData = { caseKey: 10 };

            component.actionClicked('recordTime');
            expect(initiateTimeEntrySpy).toHaveBeenCalledWith(10);
        });

        it('record time with timer triggers call to timer global service for starting timer', () => {
            const timerServiceMock = new TimeRecordingTimerGlobalServiceMock();
            injector.get.mockReturnValue(timerServiceMock);

            component.viewData = { caseKey: 10 };
            component.actionClicked('recordTimeWithTimer');
            expect(injector.get).toHaveBeenCalled();
            expect(timerServiceMock.startTimerForCase).toHaveBeenCalledWith(10);
        });
    });
});