import { async } from '@angular/core/testing';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { BusMock } from '../../../mocks/bus.mock';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { CaseviewActionsComponent } from './actions.component';
import { CaseViewActionsServiceMock } from './case-view.actions.service.mock';

describe('Case view Actions Component', () => {
    let component: (viewData?: any, canMaintainWorkflow?: boolean) => CaseviewActionsComponent;
    let service: CaseViewActionsServiceMock;
    let caseDetailService: CaseDetailServiceMock;
    let localSettings: LocalSettingsMock;
    let cdr: ChangeDetectorRefMock;
    let ping: {
        ping: jest.Mock
    };
    let policingService: {
        policeAction: jest.Mock
    };
    let notificationService: {
        openConfirmationModal: jest.Mock,
        openPolicingModal: jest.Mock
    };
    let windowParentMessagingService: WindowParentMessagingServiceMock;
    localSettings = new LocalSettingsMock();

    beforeEach(() => {
        component = (viewData?: any, canMaintainWorkflow?: boolean): CaseviewActionsComponent => {
            service = new CaseViewActionsServiceMock();
            caseDetailService = new CaseDetailServiceMock();
            cdr = new ChangeDetectorRefMock();
            policingService = {
                policeAction: jest.fn().mockReturnValue(Promise.resolve(true))
            };
            ping = {
                ping: jest.fn().mockReturnValue(Promise.resolve())
            };
            notificationService = {
                openConfirmationModal: jest.fn(),
                openPolicingModal: jest.fn()
            };
            windowParentMessagingService = new WindowParentMessagingServiceMock();
            service.getViewData$.mockReturnValue(of({
                canMaintainWorkflow: canMaintainWorkflow === undefined ? true : canMaintainWorkflow
            }));
            caseDetailService.getImportanceLevelAndEventNoteTypes$.mockReturnValue(of({
                importanceLevel: 5,
                importanceLevelOptions: [],
                requireImportanceLevel: false,
                eventNoteTypes: '',
                ...viewData
            }));

            const c = new CaseviewActionsComponent(service as any, caseDetailService as any, localSettings, cdr as any, policingService as any, notificationService as any, windowParentMessagingService as any, new BusMock() as any, ping as any);
            c.topic = { params: { viewData: viewData || {} } } as any;
            c.grid = new IpxKendoGridComponentMock() as any;
            c.ngOnInit();

            return c;
        };
    });
    describe('importanceLevelchecking', () => {

        it('initialize', async(() => {
            const c = component();
            expect(c.gridOptions).toBeDefined();
            expect(service.getViewData$).toHaveBeenCalled();

            expect(c.formData.importanceLevel).toBe(5);
            expect(c.formData.includeOpenActions).toBe(true);
            expect(c.formData.includeClosedActions).toBe(false);
            expect(c.permissions.requireImportanceLevel).toBe(false);
            expect(c.permissions.canMaintainWorkflow).toBe(true);
            service.getViewData$().subscribe(() => {
                caseDetailService.getImportanceLevelAndEventNoteTypes$().toPromise().then(() => {
                    setTimeout(() => {
                        expect(c.grid.search).toHaveBeenCalled();
                    }, 0);
                });
            });
        }));

        it('change importance level', () => {
            const c = component();
            expect(c.changeImportanceLevel).toBeDefined();
            c.changeImportanceLevel();

            expect(c.grid.search).toHaveBeenCalled();
            expect(localSettings.storageMock.session.set).toHaveBeenCalled();
        });

        it('gets importance level from cache', () => {
            localSettings.keys.caseView.importanceLevelCacheKey.setSession(3);
            const c = component({
                importanceLevelOptions: [
                    { code: 1, description: 'imp1' },
                    { code: 2, description: 'imp2' },
                    { code: 3, description: 'imp3' }
                ]
            });

            expect(c.gridOptions).toBeDefined();
            expect(service.getViewData$).toHaveBeenCalled();

            expect(localSettings.storageMock.session.get).toHaveBeenCalled();
            expect(c.formData.importanceLevel).toBe(3);

        });

        it('uses default importance level if cache value not present', () => {
            localSettings.keys.caseView.importanceLevelCacheKey.setSession(3);
            const c = component({
                importanceLevelOptions: [
                    { code: 1, description: 'imp1' },
                    { code: 2, description: 'imp2' }
                ]
            });
            expect(c.gridOptions).toBeDefined();
            expect(service.getViewData$).toHaveBeenCalled();

            expect(localSettings.storageMock.session.get).toHaveBeenCalled();
            expect(c.formData.importanceLevel).toBe(5);

        });
    });

    describe('policeAction', () => {
        it('opens the dialog', async(() => {
            const c = component();
            notificationService.openConfirmationModal.mockReturnValue({
                content: {
                    confirmed$: of(null)
                }
            });
            c.policeAction({});

            expect(notificationService.openConfirmationModal).toHaveBeenCalled();
        }));
    });

    describe('policeActionConfirmed', () => {
        it('should call policeImmediately Resolved with the expected output value', async(() => {
            const c = component();
            const action = { test: 'test' };
            c.policeImmediatelyResolved = jest.fn();
            let res = Promise.resolve(true);
            windowParentMessagingService.postRequestForData.mockReturnValue(res);
            c.policeActionConfirmed(action);
            res.then(() => {
                expect(c.policeImmediatelyResolved).toHaveBeenCalledWith(action, true);
                res = Promise.resolve(false);
                windowParentMessagingService.postRequestForData.mockReturnValue(res);

                c.policeActionConfirmed(action);
                res.then(() => {
                    expect(c.policeImmediatelyResolved).toHaveBeenCalledWith(action, false);
                });
            });
        }));
    });

    describe('refreshEvents', () => {
        it('refresh the events', async(() => {
            const c = component();
            const item = {
                code: 'abc'
            };
            c.refreshEvents(item);

            expect(c.selectedAction.actionId).toEqual('abc');
        }));
    });

    describe('policeImmediatelyResolved', () => {
        it('should call policeAction on policing service and no message to parent methods if not immediate', async(() => {
            const viewData = { caseKey: 'a' };
            const c = component(viewData);
            const action = { code: 'test' };

            c.policeImmediatelyResolved(action, false);
            ping.ping().then(() => {
                expect(policingService.policeAction).toHaveBeenCalledWith({
                    actionId: action.code,
                    caseId: viewData.caseKey,
                    isPoliceImmediately: false
                });
                expect(windowParentMessagingService.postNavigationMessage).not.toHaveBeenCalled();
            });
        }));

        it('should call policeAction on policing service and no message to parent methods if not immediate', async(() => {
            const viewData = { caseKey: 'a' };
            const c = component(viewData);
            c.isPoliceImmediately = false;
            const action = { code: 'test' };
            windowParentMessagingService.postNavigationMessage.mockReturnValue(true);

            c.policeImmediatelyResolved(action, null);
            ping.ping().then(() => {
                expect(policingService.policeAction).toHaveBeenCalledWith({
                    actionId: action.code,
                    caseId: viewData.caseKey,
                    isPoliceImmediately: false
                });
                expect(windowParentMessagingService.postNavigationMessage).not.toHaveBeenCalled();
            });
        }));

        it('should call policeAction on policing service and message to parent methods if isImmediate', async(() => {
            const viewData = { caseKey: 'a' };
            const c = component(viewData);
            const action = { code: 'test' };

            c.policeImmediatelyResolved(action, true);

            ping.ping().then(() => {
                expect(policingService.policeAction).toHaveBeenCalledWith({
                    actionId: action.code,
                    caseId: viewData.caseKey,
                    isPoliceImmediately: true
                });
                policingService.policeAction().then(() => {
                    expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledTimes(2);
                    expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith(expect.objectContaining({ action: 'StartPolicing' }), expect.anything());
                    expect(windowParentMessagingService.postNavigationMessage).toHaveBeenLastCalledWith(expect.objectContaining({ action: 'StopPolicing' }));
                });
            });
        }));
    });
});