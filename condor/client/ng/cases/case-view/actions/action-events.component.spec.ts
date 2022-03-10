import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, FormGroup } from '@angular/forms';
import { RootScopeServiceMock } from 'ajs-upgraded-providers/mocks/rootscope.service.mock';
import { AttachmentModalServiceMock } from 'common/attachments/attachment-modal.service.mock';
import { AttachmentPopupServiceMock } from 'common/attachments/attachments-popup/attachment-popup.service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, DateHelperMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { WindowParentMessagingServiceMock } from 'mocks/window-parent-messaging.service.mock';
import { of } from 'rxjs/internal/observable/of';
import { delay } from 'rxjs/operators';
import { FormControlWarning } from 'shared/component/forms/form-control-warning';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { CaseViewViewData } from '../view-data.model';
import { CaseviewActionEventComponent } from './action-events.component';
import { CaseViewActionsServiceMock } from './case-view.actions.service.mock';

describe('Case view Action Event Component', () => {
    let component: (viewData?: CaseViewViewData) => CaseviewActionEventComponent;
    let service: CaseViewActionsServiceMock;
    let localSettings: LocalSettingsMock;
    let cdr: ChangeDetectorRefMock;
    let windowParentMessagingService: WindowParentMessagingServiceMock;
    let rootscopeService: RootScopeServiceMock;
    let caseDetailService: CaseDetailServiceMock;
    let notificationService: NotificationServiceMock;
    let datehelper: DateHelperMock;
    let modalService: ModalServiceMock;
    let attachmentModalService: AttachmentModalServiceMock;
    let attachmentPopupService: AttachmentPopupServiceMock;

    beforeEach(() => {
        service = new CaseViewActionsServiceMock();
        localSettings = new LocalSettingsMock();
        cdr = new ChangeDetectorRefMock();
        windowParentMessagingService = new WindowParentMessagingServiceMock();
        caseDetailService = new CaseDetailServiceMock();
        notificationService = new NotificationServiceMock();
        datehelper = new DateHelperMock();
        modalService = new ModalServiceMock();
        rootscopeService = new RootScopeServiceMock();
        attachmentModalService = new AttachmentModalServiceMock();
        attachmentPopupService = new AttachmentPopupServiceMock();
        component = (viewData?: CaseViewViewData): CaseviewActionEventComponent => {
            const c = new CaseviewActionEventComponent(service as any, localSettings,
                cdr as any,
                windowParentMessagingService as any,
                rootscopeService as any,
                caseDetailService as any,
                new FormBuilder(),
                datehelper as any,
                notificationService as any,
                modalService as any,
                attachmentModalService as any,
                attachmentPopupService as any
            );
            c.viewData = viewData || {
                caseKey: 1
            };
            c.ngOnInit();
            c.gridOptions._search = jest.fn();
            c.grid = new IpxKendoGridComponentMock() as any;

            return c;
        };
    });

    it('initialize', () => {
        const c = component();
        expect(c.gridOptions).toBeDefined();
    });

    it('should set isHosted to the rootscopeService value', () => {
        rootscopeService.isHosted = true;
        const c = component();

        expect(c.isHosted).toBeTruthy();
    });

    it('should not have attachmentColumn if not isHosted', () => {
        rootscopeService.isHosted = false;
        const c = component();

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'attachmentCount'));
        expect(attachmentColumn).toBeFalsy();
    });

    it('should not have attachmentColumn if does not have access to attachment subject', () => {
        rootscopeService.isHosted = true;
        const c = component({
            hasAccessToAttachmentSubject: false
        });

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'attachmentCount'));
        expect(attachmentColumn).toBeFalsy();
    });

    it('should have attachmentColumn if isHosted', () => {
        rootscopeService.isHosted = true;
        const c = component({
            hasAccessToAttachmentSubject: true
        });

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'attachmentCount'));
        expect(attachmentColumn).toBeTruthy();
    });

    it('should not have hasEventHistory if not isHosted', () => {
        rootscopeService.isHosted = false;
        const c = component();

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'hasEventHistory'));
        expect(attachmentColumn).toBeFalsy();
    });

    it('should not have hasEventHistory if does not have access to attachment subject', () => {
        rootscopeService.isHosted = true;
        const c = component({
            hasCaseEventAuditingConfigured: false
        });

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'hasEventHistory'));
        expect(attachmentColumn).toBeFalsy();
    });

    it('should have hasEventHistory if isHosted', () => {
        rootscopeService.isHosted = true;
        const c = component({
            hasCaseEventAuditingConfigured: true
        });

        const attachmentColumn = c.gridOptions.columns.find((col => col.field === 'hasEventHistory'));
        expect(attachmentColumn).toBeTruthy();
    });

    it('should clear cache when action change', () => {
        const c = component();
        const changeed = {
            action: {
                currentValue: {
                    actionId: 'ac',
                    cycle: 1,
                    criteriaId: 1,
                    importanceLevel: 5,
                    isCyclic: false
                }
            }
        };
        c.ngOnChanges(changeed as any);
        expect(attachmentPopupService.clearCache).toHaveBeenCalled();
    });

    it('searches on change', () => {
        const c = component();
        const changeed = {
            action: {
                currentValue: {
                    actionId: 'ac',
                    cycle: 1,
                    criteriaId: 1,
                    importanceLevel: 5,
                    isCyclic: false
                }
            }
        };
        c.ngOnChanges(changeed as any);
        expect(c.selectedAction).toBe(changeed.action.currentValue);
        expect(c.gridOptions._search).toHaveBeenCalled();
    });

    it('searches on change', () => {
        const c = component();
        const changeed = {
            action: {
                currentValue: {
                    actionId: 'ac',
                    cycle: 1,
                    criteriaId: 1,
                    importanceLevel: 5,
                    isCyclic: false
                }
            }
        };
        c.ngOnChanges(changeed as any);
        expect(c.selectedAction).toBe(changeed.action.currentValue);
        expect(c.gridOptions._search).toHaveBeenCalled();
    });

    describe('openAttachmentWindow', () => {
        it('should post a navigation message to the parent to open the attachment window', () => {
            const c = component();
            rootscopeService.isHosted = true;
            const dataItem = {
                eventNo: 777,
                cycle: 123
            };
            c.selectedAction = {
                actionId: 'abc'
            } as any;
            c.openAttachmentWindow(dataItem);

            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: ['CaseEventAttachments', 1, 'abc', 777, 123]
            });
        });

        it('should open the attachments window as popup- if not hosted', () => {
            rootscopeService.isHosted = false;
            const c = component({ caseKey: 99 });
            c.dmsConfigured = true;
            const dataItem = {
                eventNo: 777,
                cycle: 123
            };
            c.selectedAction = {
                actionId: 'abc'
            } as any;
            c.openAttachmentWindow(dataItem);

            expect(attachmentModalService.displayAttachmentModal).toHaveBeenCalled();
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][0]).toBe('case');
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][1]).toBe(99);
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2].actionKey).toBe(c.selectedAction.actionId);
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2].eventKey).toBe(dataItem.eventNo);
            expect(attachmentModalService.displayAttachmentModal.mock.calls[0][2].eventCycle).toBe(dataItem.cycle);
        });
    });

    describe('openEventNotesWindow', () => {
        it('should post a navigation message to the parent to open the event notes window', () => {
            const c = component();
            const dataItem = {
                eventNo: 777,
                cycle: 123
            };
            caseDetailService.hasPendingChanges$.next(false);
            c.openEventNotesWindow(dataItem);

            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: ['EventNotes', 1, 777, 123]
            });
        });

        it('should post a navigation message to the parent to open the event notes window', () => {
            const c = component();
            const dataItem = {
                eventNo: 777,
                cycle: 123
            };
            caseDetailService.hasPendingChanges$.next(true);
            c.openEventNotesWindow(dataItem);

            expect(windowParentMessagingService.postNavigationMessage).not.toHaveBeenCalled();
        });
    });

    describe('openEventHistoryWindow', () => {
        it('should post a navigation message to the parent to open the event history window', () => {
            const c = component();
            c.action = {
                criteriaId: 110
            } as any;
            const dataItem = {
                eventNo: 777,
                cycle: 123
            };
            c.openEventHistoryWindow(dataItem);

            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: ['EventHistory', 1, 777, 123, 110]
            });
        });
    });

    describe('search', () => {
        let c: CaseviewActionEventComponent;
        beforeEach(() => {
            c = component();
            c.selectedAction = {} as any;
        });
        it('search all cycles events', () => {
            c.gridSearchFlags.isAllCycles = true;
            c.gridSearchFlags.isAllEvents = true;
            c.searchAllCycles();

            expect(c.gridOptions._search).toHaveBeenCalled();
            expect(c.gridSearchFlags.isAllCycles).toBeTruthy();
            expect(c.gridSearchFlags.isAllEvents).toBeTruthy();
        });

        it('sets All Events to false if All Cycles is set to false', () => {

            c.gridSearchFlags.isAllCycles = false;
            c.gridSearchFlags.isAllEvents = true;
            c.searchAllCycles();

            expect(c.gridOptions._search).toHaveBeenCalled();
            expect(c.gridSearchFlags.isAllCycles).toBeFalsy();
            expect(c.gridSearchFlags.isAllEvents).toBeFalsy();
        });

        it('search all events sets cycle value to all events value', () => {
            c.gridSearchFlags.isAllEvents = true;
            c.gridSearchFlags.isAllCycles = false;
            c.searchAllEvents();

            expect(c.gridOptions._search).toHaveBeenCalled();
            expect(c.gridSearchFlags.isAllCycles).toBeTruthy();
            expect(c.gridSearchFlags.isAllEvents).toBeTruthy();

            c.gridSearchFlags.isAllEvents = false;
            c.searchAllEvents();
            expect(c.gridSearchFlags.isAllCycles).toBeFalsy();
            expect(c.gridSearchFlags.isAllEvents).toBeFalsy();

        });
        it('createFromGroup', () => {
            const dataItem = { eventNo: 10, eventCompositeKey: '10-', eventDate: '07-Jun-2020', eventDueDate: '07-Jun-2019' };
            const group = c.createFormGroup(dataItem);
            expect(group).toEqual(expect.any(FormGroup));
            expect(Object.keys(group.controls)).toEqual(['eventCompositeKey', 'eventDate', 'eventDueDate', 'name', 'nameType']);
        });

        it('reset form should empty collection', () => {
            c.grid = { rowEditFormGroups: { ['1001']: new FormGroup({}) } } as any;
            c.ngOnInit();
            caseDetailService.resetChanges$.next(true);
            expect(c.grid.rowEditFormGroups).toBeNull();
        });
        it('eventDate on change', () => {
            const dataItem = { eventNo: 10, eventCompositeKey: '10-', eventDate: '07-Jun-2080', eventDueDate: '07-Jun-2019' };
            c.originalData = {
                data: {
                    1: dataItem
                }
            };
            c.viewData = { canMaintainCaseEvent: true };
            c.grid = { isValid: () => true } as any;
            c.action = { actionId: '1001' } as any;
            const group = c.createFormGroup(dataItem);
            datehelper.areDatesEqual.mockReturnValue(false);
            rootscopeService.isHosted = true;
            c.grid.pageRowIndex = (val) => val;
            c.ngOnInit();
            c.alertEventDate(dataItem.eventDate, group, 1);
            expect(notificationService.info).toHaveBeenCalledWith({ continue: 'Ok', message: 'caseview.actions.events.eventDateAlert' });
            expect(c.rowEditUpdates).not.toBeNull();
            expect(caseDetailService.hasPendingChanges$.getValue()).toBeTruthy();
        });
        it('eventDueDate on change', () => {
            const dataItem = { eventNo: 10, eventCompositeKey: '10-', eventDate: '07-Jun-2080', eventDueDate: '07-Jun-2019' };
            c.originalData = {
                data: {
                    1: dataItem
                }
            };
            c.viewData = { canMaintainCaseEvent: true };
            c.grid = { isValid: () => true } as any;
            c.action = { actionId: '1001' } as any;
            rootscopeService.isHosted = true;
            const group = c.createFormGroup(dataItem);
            datehelper.areDatesEqual.mockReturnValue(false);
            c.grid.pageRowIndex = (val) => val;

            c.ngOnInit();
            c.alertDueDate(dataItem.eventDueDate, group, 1);
            expect(notificationService.info).toHaveBeenCalledWith({ continue: 'Ok', message: 'caseview.actions.events.eventDueDateAlert' });
            expect(c.rowEditUpdates).not.toBeNull();
            expect(caseDetailService.hasPendingChanges$.getValue()).toBeTruthy();
        });

        it('set errors', () => {
            const errors = [{ severity: 'warning', message: 'message1', topic: 'action', field: 'eventDate', id: '-13-1', displayMessage: true, customValidationMessage: '' },
            { severity: 'warning', message: 'message2', topic: 'action', field: 'eventDate', id: '-13-1', displayMessage: true, customValidationMessage: '' },
            { severity: 'warning', message: 'message4', topic: 'action', field: 'eventDate', id: '-13-1', displayMessage: true, customValidationMessage: '' },
            { severity: 'error', message: 'message1', topic: 'action', field: 'eventDate', id: '-16-1', displayMessage: true, customValidationMessage: '' },
            { severity: 'warning', message: 'messge2', topic: 'action', field: 'eventDate', id: '-16-1', displayMessage: true, customValidationMessage: '' }];
            c.grid = {
                rowEditFormGroups: {
                    ['-13-1']: new FormGroup({
                        eventDate: new FormControlWarning(),
                        eventDueDate: new FormControlWarning()
                    }),
                    ['-16-1']: new FormGroup({
                        eventDate: new FormControlWarning(),
                        eventDueDate: new FormControlWarning()
                    })
                }
            } as any;

            c.grid.isValid = () => true;

            c.setErrors(errors as any);
            expect(c.grid.rowEditFormGroups['-13-1'].controls.eventDate.valid);
            expect(c.grid.rowEditFormGroups['-16-1'].controls.eventDate.invalid);
        });

        it('viewruleDetail permission should open modal', () => {

            modalService.openModal = jest.fn(() => {
                return { hide: null, setClass: null };
            });
            c.originalData = {
                data: [{ eventNo: -123 }, { eventNo: -134 }, { eventNo: -133 }],
                total: 10,
                pageSize: 10
            };
            c.viewRuleDetails(-133);
            expect(c.ruleDetailsModalRef).toBeDefined();
        });
    });

    describe('menu items', () => {
        let c: CaseviewActionEventComponent;
        beforeEach(() => {
            c = component();
            c.selectedAction = {} as any;
            c.grid = {
                getRowMaintenanceMenuItems: jest.fn()
            } as any;
            c.grid.getRowMaintenanceMenuItems.mockReturnValue([{
                id: 123, icon: 'cpa-icon'
            }]);
            rootscopeService.isHosted = false;
            c.viewData = { maintainEventNotes: true, canAddAttachment: true };
            c.ngOnInit();
        });
        it('show resolve correct task menus', () => {
            const dataItem = { id: 123 };
            c.isHosted = true;
            c.displayTaskItems(dataItem);

            expect(c.grid.getRowMaintenanceMenuItems).toHaveBeenCalledWith(dataItem);
            expect(c.taskItems).not.toBeNull();
            expect(c.taskItems.length).toBe(3);
            expect(c.taskItems[0]).toEqual({
                id: 123, icon: 'cpa-icon'
            });
            expect(c.taskItems[1].id).toEqual('addAttachment');
            expect(c.taskItems[1].icon).toEqual('cpa-icon cpa-icon-paperclip');
            expect(c.taskItems[2].id).toEqual('maintainEventNote');
            expect(c.taskItems[2].icon).toEqual('cpa-icon cpa-icon-file-o');
        });
        it('disable Maintain Event Note menu item in potential event', () => {
            const dataItem = { id: 123, isProtentialEvents: true };
            c.isHosted = true;
            c.displayTaskItems(dataItem);

            expect(c.grid.getRowMaintenanceMenuItems).toHaveBeenCalledWith(dataItem);
            expect(c.taskItems).not.toBeNull();
            expect(c.taskItems.length).toBe(3);

            expect(c.taskItems[2].id).toEqual('maintainEventNote');
            expect(c.taskItems[2].disabled).toBe(true);
        });
        it('show trigger event', () => {
            const item = {
                event: {
                    item: {
                        action: jest.fn()
                    }
                },
                dataItem: {
                    id: 1
                }
            };
            c.onMenuItemSelected(item);
            expect(item.event.item.action).toHaveBeenCalledWith({
                id: 1
            });
        });
    });
    describe('openAttachmentMaintenanceWindow', () => {
        it('should post a navigation message to the parent to open the attachment maintenance window', () => {
            const c = component({ caseKey: 1001 });
            rootscopeService.isHosted = true;
            const dataItem = {
                eventNo: 1111,
                cycle: 1
            };
            c.selectedAction = {
                actionId: 'abc'
            } as any;
            c.triggerAddAttachment(dataItem);

            expect(windowParentMessagingService.postNavigationMessage).toHaveBeenCalledWith({
                args: ['OpenMaintainAttachment', 1001, '', '', 'abc', 1111, 1]
            });
        });

        it('should open the attachments maintenance window as popup if not hosted', () => {
            rootscopeService.isHosted = false;
            const c = component({ caseKey: 1001 });
            c.dmsConfigured = true;
            c.baseType = 'case';
            c.action = { actionId: 1002 } as any;
            const dataItem = {
                eventNo: 1111,
                cycle: 1
            };
            c.selectedAction = {
                actionId: 'abc'
            } as any;

            c.triggerAddAttachment(dataItem);
            expect(attachmentModalService.triggerAddAttachment).toHaveBeenCalled();
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][0]).toEqual('case');
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][1]).toEqual(1001);
            expect(attachmentModalService.triggerAddAttachment.mock.calls[0][2]).toEqual({ eventKey: 1111, eventCycle: 1, actionKey: 1002 });
        });

        it('should refresh data if dataModified', fakeAsync(() => {
            attachmentModalService.attachmentsModified = of(true).pipe(delay(10));
            const c = component({ caseKey: 1001 });

            tick(10);

            expect(c.grid.search).toHaveBeenCalled();
        }));
    });
});