import { Injectable, Injector } from '@angular/core';
import { StateService } from '@uirouter/core';
import { TimeRecordingHelper } from 'accounting/time-recording-widget/time-recording-helper';
import { TimeRecordingTimerGlobalService } from 'accounting/time-recording-widget/time-recording-timer-global.service';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { DmsModalComponent } from 'common/case-name/dms-modal/dms-modal.component';
import { AppContextService } from 'core/app-context.service';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { AdHocDateComponent } from 'dates/adhoc-date.component';
import { BehaviorSubject, forkJoin } from 'rxjs';
import { BillSearchProvider, BillSearchTaskMenuItemOperationType } from 'search/bill-search/bill-search.provider';
import { BillSearchPermissions, CaseSearchPermissions, NameSearchPermissions, PriorArtSearchPermissions } from 'search/results/search-results.data';
import { ReminderActionProvider } from 'search/task-planner/reminder-action.provider';
import { MaintainActions, ReminderActionStatus, ReminderRequestType } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { TaskMenuItem } from 'shared/component/grid/ipx-grid.models';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { AdhocDateService } from './../../dates/adhoc-date.service';
import { CaseWebLinksTaskProvider } from './case-web-links-task-provider';
import { queryContextKeyEnum, SearchTypeConfig } from './search-type-config.provider';

@TypeDecorator('SearchResultsTaskMenuProvider')
@Injectable()
export class SearchTypeTaskMenusProvider {
    permissions: any;
    searchConfiguration: SearchTypeConfig;
    viewData: any;
    selectedCaseIds: any;
    filter: any;
    queryContextKey: number;
    isHosted: boolean;
    private _timerService: TimeRecordingTimerGlobalService;
    _baseTasks: any;
    _isTimeRecordingAllowed: boolean;
    isMaintainEventFireTaskMenu$ = new BehaviorSubject<any>(null);
    isMaintainEventFireTaskMenuWhenGrouping$ = new BehaviorSubject<any>(null);

    constructor(private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly stateService: StateService,
        private readonly modalService: IpxModalService,
        private readonly injector: Injector,
        private readonly appContextService: AppContextService,
        private readonly taskPlannerService: TaskPlannerService,
        private readonly notificationService: NotificationService,
        private readonly reminderActionProvider: ReminderActionProvider,
        private readonly adHocDateService: AdhocDateService,
        private readonly attachmentModalService: AttachmentModalService,
        private readonly caseWebLinksProvider: CaseWebLinksTaskProvider,
        private readonly billSearchProvider: BillSearchProvider) {
        this.appContextService.appContext$.subscribe(ctx => {
            this._isTimeRecordingAllowed = (!!ctx && !!ctx.user && !!ctx.user.permissions) ? ctx.user.permissions.canAccessTimeRecording : false;
            if (this._isTimeRecordingAllowed) {
                this._timerService = this.injector.get<TimeRecordingTimerGlobalService>(TimeRecordingTimerGlobalService);
            }
        });
    }

    initializeContext = (permissions: any, queryContextKey: number, isHosted: boolean, viewData: any): void => {
        this.queryContextKey = queryContextKey;
        this.isHosted = isHosted;
        this.viewData = viewData;
        if (permissions) {
            switch (queryContextKey) {
                case queryContextKeyEnum.caseSearch:
                case queryContextKeyEnum.caseSearchExternal:
                    this.permissions = permissions as CaseSearchPermissions;
                    break;
                case queryContextKeyEnum.nameSearch:
                case queryContextKeyEnum.nameSearchExternal:
                    this.permissions = permissions as NameSearchPermissions;
                    break;
                case queryContextKeyEnum.priorArtSearch:
                    this.permissions = permissions as PriorArtSearchPermissions;
                    break;
                case queryContextKeyEnum.billSearch:
                    this.permissions = permissions as BillSearchPermissions;
                    break;
                default:
                    break;
            }
        }
    };

    getConfigurationTaskMenuItems = (dataItem: any): Array<TaskMenuItem> => {
        let tasks = [];
        switch (this.queryContextKey) {
            case queryContextKeyEnum.nameSearch:
                const nsp: NameSearchPermissions = this.permissions;
                tasks = this.configureNameSearchTaskMenuItems(this.isHosted, dataItem, nsp);
                break;
            case queryContextKeyEnum.caseSearch:
                const csp: CaseSearchPermissions = this.permissions;
                tasks = this.configureCaseSearchTaskMenuItems(this.isHosted, dataItem, csp);
                break;
            case queryContextKeyEnum.priorArtSearch:
                const psp: PriorArtSearchPermissions = this.permissions;
                if (this.isHosted && psp.canMaintainPriorArt) {
                    tasks.push(
                        {
                            id: PriorArtTaskMenuItemOperationType.maintainPriorArt,
                            text: 'priorArtSearchTaskMenu.maintainPriorArt',
                            action: this.manageTaskOperation,
                            icon: 'cpa-icon cpa-icon-file-stack-art'
                        });
                }
                break;
            case queryContextKeyEnum.taskPlannerSearch:
                tasks = this.configureTaskPlannerMenuItems(dataItem);
                break;
            case queryContextKeyEnum.billSearch:
                tasks = this.configureBillSearchMenuItems(dataItem);
                break;
            default:
                break;
        }

        return tasks;
    };

    hasTaskMenuItems = (dataItem: any): boolean => {
        const taskItems = this.getConfigurationTaskMenuItems(dataItem);

        return taskItems && taskItems.length > 0;
    };

    initTaskPlannerBaseTasks = (dataItem: any): void => {
        this._baseTasks = [
            {
                menu: {
                    id: 'finalise',
                    text: 'taskPlannerTaskMenu.finaliseAdHocDate',
                    icon: 'cpa-icon cpa-icon-bell-check-o',
                    action: (item: any) => {
                        this.reminderActionProvider.finalise(item.taskPlannerRowKey, {
                            resolveReasons: this.viewData.resolveReasons
                        });
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && this.viewData.canFinaliseAdhocDate && this.taskPlannerService.isAdHoc(item);
                }
            },
            {
                menu: {
                    id: 'maintainAdhocDate',
                    text: 'taskPlannerTaskMenu.maintainAdHocDate',
                    icon: 'cpa-icon cpa-icon-calendar',
                    action: (item: any) => {
                        this.maintainAdHoc(item.taskPlannerRowKey);
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && this.viewData.canMaintainAdhocDate && this.taskPlannerService.isAdHoc(item);
                }
            },
            {
                menu: {
                    id: 'dismissReminder',
                    text: 'taskPlannerTaskMenu.dismissReminder',
                    icon: 'cpa-icon cpa-icon-bell-slash',
                    action: (item: any) => {
                        this.reminderActionProvider.dismissReminders([item.taskPlannerRowKey], null, ReminderRequestType.InlineTask);
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && (this.viewData.reminderDeleteButton === 0 || this.viewData.reminderDeleteButton === 2) && this.taskPlannerService.hasEmployeeReminder(item);
                }
            }, {
                menu: {
                    id: 'deferReminder',
                    text: 'taskPlannerTaskMenu.deferReminder',
                    icon: 'cpa-icon cpa-icon-bell-semicircle-inline',
                    action: this.noAction,
                    items: [{
                        id: 'toEnteredDate',
                        text: 'taskPlannerTaskMenu.toEnteredDate',
                        action: (item: any) => {
                            this.reminderActionProvider.deferRemindersToEnteredDate(ReminderRequestType.InlineTask, [item.taskPlannerRowKey], null);
                        }
                    }, {
                        id: 'toNextCalculatedDate',
                        text: 'taskPlannerTaskMenu.toNextCalculatedDate',
                        action: (item: any) => {
                            this.reminderActionProvider.deferReminders(ReminderRequestType.InlineTask, [item.taskPlannerRowKey], null, null);
                        }
                    }]
                },
                evalAvailable: (item: any) => {
                    return this.taskPlannerService.hasEmployeeReminder(item);
                }
            }, {
                menu: {
                    id: 'readReminder',
                    text: 'taskPlannerTaskMenu.markAsRead',
                    icon: 'cpa-icon cpa-icon-check',
                    action: (item: any) => {
                        this.reminderActionProvider.markAsReadOrUnread([item.taskPlannerRowKey], true, null);
                    }
                },
                evalAvailable: (item: any) => {
                    return !item.isRead && this.taskPlannerService.hasEmployeeReminder(item);
                }
            }, {
                menu: {
                    id: 'unreadReminder',
                    text: 'taskPlannerTaskMenu.markAsUnread',
                    icon: 'cpa-icon cpa-icon-check',
                    action: (item: any) => {
                        this.reminderActionProvider.markAsReadOrUnread([item.taskPlannerRowKey], false, null);
                    }
                },
                evalAvailable: (item: any) => {
                    return item.isRead && this.taskPlannerService.hasEmployeeReminder(item);
                }
            }, {
                menu: {
                    id: 'forwardReminder',
                    text: 'taskPlannerTaskMenu.forwardReminder',
                    icon: 'cpa-icon cpa-icon-bell-semicircle',
                    action: (item: any) => {
                        this.reminderActionProvider.forwardReminders([item.taskPlannerRowKey], ReminderRequestType.InlineTask, null);
                    }
                },
                evalAvailable: (item: any) => {
                    return this.taskPlannerService.isReminderOrAdHoc(item);
                }
            }, {
                menu: {
                    id: 'changeDueDateResponsibility',
                    text: 'taskPlannerTaskMenu.changeDueDateResponsibility',
                    icon: 'cpa-icon cpa-icon-calendar-semicircle',
                    action: (item: any) => {
                        this.reminderActionProvider.changeDueDateResponsibility([item.taskPlannerRowKey], null, ReminderRequestType.InlineTask);
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && this.viewData.canChangeDueDateResponsibility && this.taskPlannerService.isReminderOrDueDate(item);
                }
            }, {
                menu: {
                    id: 'provideInstructions',
                    text: 'taskPlannerTaskMenu.provideInstructions',
                    icon: 'cpa-icon cpa-icon-file-o-edit',
                    action: (item: any) => {
                        this.reminderActionProvider.provideInstructions(item.taskPlannerRowKey, this.viewData);
                    }
                },
                evalAvailable: (item: any) => {
                    return item.hasInstructions && this.viewData && this.viewData.provideDueDateInstructions;
                }
            }, {
                menu: {
                    id: 'maintainEventNotes',
                    text: 'taskPlannerTaskMenu.maintainEventNotes',
                    icon: 'cpa-icon cpa-icon-edit',
                    action: (item: any) => {
                        this.isMaintainEventFireTaskMenu$.next({ taskPlannerRowKey: item.taskPlannerRowKey, maintainActions: MaintainActions.notes, rowIndex: item._rowIndex });
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && (this.viewData.maintainEventNotesPermissions && (this.viewData.maintainEventNotesPermissions.insert || this.viewData.maintainEventNotesPermissions.update)) && this.taskPlannerService.isReminderOrDueDate(item);
                }
            }, {
                menu: {
                    id: 'maintainReminderComment',
                    text: 'taskPlannerTaskMenu.maintainReminderComments',
                    icon: 'cpa-icon cpa-icon-edit',
                    action: (item: any) => {
                        this.isMaintainEventFireTaskMenu$.next({ taskPlannerRowKey: item.taskPlannerRowKey, maintainActions: MaintainActions.comments, rowIndex: item._rowIndex });
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && this.viewData.showReminderComments && this.viewData.maintainReminderComments && this.taskPlannerService.isShowReminderComments(item);
                }
            }, {
                menu: {
                    id: 'addAttachment',
                    text: 'caseview.actions.events.addAttachment',
                    icon: 'cpa-icon cpa-icon-paperclip',
                    action: this.addAttachment
                },
                evalAvailable: (item: any) => {
                    return (this.viewData || {}).canAddCaseAttachments && _.isNumber(item.caseKey) && _.isNumber(item.eventKey);
                }
            }, {
                menu: {
                    id: 'createAdhoc',
                    text: 'taskPlannerTaskMenu.createAdhoc',
                    icon: 'cpa-icon cpa-icon-calendar-plus-o',
                    action: (item: any) => {
                        this.openAdHoc(item.taskPlannerRowKey);
                    }
                },
                evalAvailable: (item: any) => {
                    return this.viewData && this.viewData.canCreateAdhocDate && this.taskPlannerService.isReminderOrDueDate(item);
                }
            }, {
                menu: {
                    id: 'sendEmail',
                    text: 'taskPlannerTaskMenu.sendEmail',
                    icon: 'cpa-icon cpa-icon-envelope',
                    action: (item: any) => {
                        this.reminderActionProvider.sendEmails([item.taskPlannerRowKey], null);
                    }
                },
                evalAvailable: (item: any) => {
                    return true;
                }
            }, {
                menu: {
                    id: 'separator1',
                    isSeparator: true
                },
                evalAvailable: (item: any) => {
                    return true;
                }
            }, {
                menu: {
                    id: 'RecordTime',
                    text: 'caseTaskMenu.recordTime',
                    icon: 'cpa-icon cpa-icon-clock-o',
                    action: (item: any) => {
                        TimeRecordingHelper.initiateTimeEntry(item.caseKey);
                    }
                },
                evalAvailable: (item: any) => {
                    return this._isTimeRecordingAllowed && _.isNumber(item.caseKey);
                }
            },
            {
                menu: {
                    id: 'RecordTimeWithTimer',
                    text: 'caseTaskMenu.recordTimer',
                    icon: 'cpa-icon cpa-icon-clock-timer',
                    action: (item: any) => {
                        this._timerService.startTimerForCase(item.caseKey);
                    }
                },
                evalAvailable: (item: any) => {
                    return this._isTimeRecordingAllowed && _.isNumber(item.caseKey);
                }
            }
        ];

        if (dataItem.caseKey) {
            const webLink = {
                menu: {
                    id: 'caseWebLinks',
                    text: 'caseTaskMenu.openCaseWebLinks',
                    icon: 'cpa-icon cpa-icon-bookmark',
                    action: this.noAction,
                    items: []
                },
                evalAvailable: (item: any) => {
                    return true;
                }
            };
            this._baseTasks.push(webLink);
        }
    };

    addAttachment = (dataItem: any): void => {
        this.attachmentModalService.triggerAddAttachment('case', dataItem.caseKey, { eventKey: dataItem.eventKey, eventCycle: dataItem.eventCycle, actionKey: dataItem.actionKey });
    };

    openAdHoc = (taskPlannerRowKey: any) => {
        const rowKey = taskPlannerRowKey.split('^');
        const caseEventId = Number(rowKey[1]);

        const caseEventDetails$ = this.adHocDateService.caseEventDetails(caseEventId);
        const viewData$ = this.adHocDateService.viewData();

        forkJoin([viewData$, caseEventDetails$])
            .subscribe(([viewData, caseEventDetails]) => {
                const initialState = {
                    viewData,
                    caseEventDetails,
                    taskPlannerRowKey
                };
                this.modalService.openModal(AdHocDateComponent, {
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState
                });
            });
    };

    maintainAdHoc = (taskPlannerRowKey: any) => {
        const rowKey = taskPlannerRowKey.split('^');
        const alertId = +rowKey[1];

        const adhocDateDetails$ = this.adHocDateService.adhocDate(alertId);
        const viewData$ = this.adHocDateService.viewData(alertId);

        forkJoin([viewData$, adhocDateDetails$])
            .subscribe(([viewData, adhocDateDetails]) => {
                const initialState = {
                    resolveReasons: this.viewData.resolveReasons,
                    viewData,
                    adhocDateDetails,
                    mode: 'maintain',
                    taskPlannerRowKey
                };
                this.modalService.openModal(AdHocDateComponent, {
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState
                });
            });
    };

    subscribeCaseWebLinks = (dataItem: any, webLink: any): void => {
        this.caseWebLinksProvider.subscribeCaseWebLinks(dataItem, webLink);
    };

    configureTaskPlannerMenuItems = (dataItem: any): Array<TaskMenuItem> => {
        this.initTaskPlannerBaseTasks(dataItem);

        return _.chain(this._baseTasks)
            .filter((task: any) => {
                return task.evalAvailable(dataItem);
            })
            .map((task: any) => { return task.menu; })
            .value() as Array<TaskMenuItem>;
    };

    configureBillSearchMenuItems = (dataItem: any): Array<TaskMenuItem> => {
        const tasks = [];
        if (this.billSearchProvider.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.reverse)) {
            tasks.push({
                id: BillSearchTaskMenuItemOperationType.reverse,
                text: 'billSearch.inlineTaskMenu.reverse',
                action: this.billSearchProvider.manageTaskOperation,
                icon: 'cpa-icon cpa-icon-revert'
            });
        }
        if (this.billSearchProvider.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.deleteDraftBill)) {
            tasks.push({
                id: BillSearchTaskMenuItemOperationType.deleteDraftBill,
                text: 'billSearch.inlineTaskMenu.deleteDraftBill',
                action: this.billSearchProvider.manageTaskOperation,
                icon: 'cpa-icon cpa-icon-trash-o'
            });
        }
        if (this.billSearchProvider.canAccessTask(dataItem, BillSearchTaskMenuItemOperationType.credit)) {
            tasks.push({
                id: BillSearchTaskMenuItemOperationType.credit,
                text: 'billSearch.inlineTaskMenu.credit',
                action: this.billSearchProvider.manageTaskOperation,
                icon: 'cpa-icon cpa-icon-check-square-o'
            });
        }

        return tasks;
    };

    private readonly manageTaskOperation = (dataItem: any, event: any): void => {
        if (!dataItem || !event || !event.item) { return; }
        switch (event.item.id) {
            case CaseTaskMenuItemOperationType.maintainCase:
            case CaseTaskMenuItemOperationType.docketingWizard:
            case CaseTaskMenuItemOperationType.workflowWizard:
            case CaseTaskMenuItemOperationType.maintainFileLocation:
            case CaseTaskMenuItemOperationType.recordWip:
            case CaseTaskMenuItemOperationType.copyCase:
            case CaseTaskMenuItemOperationType.openFirstToFile:
            case CaseTaskMenuItemOperationType.openReminders:
            case CaseTaskMenuItemOperationType.createAdHocDate:
            case CaseTaskMenuItemOperationType.requestCaseFile:
                this.windowParentMessagingService.postNavigationMessage({ args: [event.item.id, dataItem.caseKey] });
                break;
            case NameTaskMenuItemOperationType.maintainNameText:
            case NameTaskMenuItemOperationType.maintainNameAttributes:
            case NameTaskMenuItemOperationType.maintainName:
            case NameTaskMenuItemOperationType.adHocDateForName:
            case NameTaskMenuItemOperationType.newOpportunityForName:
            case NameTaskMenuItemOperationType.newActivityWizardForName:
                this.windowParentMessagingService.postNavigationMessage({ args: [event.item.id, dataItem.nameKey] });
                break;
            case PriorArtTaskMenuItemOperationType.maintainPriorArt:
                this.windowParentMessagingService.postNavigationMessage({ args: [event.item.id, dataItem.priorArtKey] });
                break;
            default:

                break;
        }
    };

    noAction = (): void => {
        return;
    };

    private configureNameSearchTaskMenuItems(isHosted: boolean, dataItem: any, nsp: NameSearchPermissions): Array<any> {
        const tasks = [];
        if (isHosted && dataItem.isEditable) {
            const editName = {
                id: 'editName',
                text: 'nameSearchTaskMenu.editName',
                icon: 'cpa-icon cpa-icon-edit',
                action: this.noAction,
                items: []
            };
            if (nsp.canMaintainName) {
                editName.items.push({
                    id: NameTaskMenuItemOperationType.maintainName,
                    parent: editName,
                    text: 'nameSearchTaskMenu.maintainNameDetails',
                    action: this.manageTaskOperation
                });
            }
            if (nsp.canMaintainNameAttributes) {
                editName.items.push({
                    id: NameTaskMenuItemOperationType.maintainNameAttributes,
                    parent: editName,
                    text: 'nameSearchTaskMenu.maintainAttributes',
                    action: this.manageTaskOperation
                });
            }
            if (nsp.canMaintainNameNotes) {
                editName.items.push({
                    id: NameTaskMenuItemOperationType.maintainNameText,
                    parent: editName,
                    text: 'nameSearchTaskMenu.maintainNotes',
                    action: this.manageTaskOperation
                });
            }
            if (editName.items.length > 0) {
                tasks.push(editName);
            }
            if (nsp.canMaintainAdHocDate) {
                tasks.push({
                    id: NameTaskMenuItemOperationType.adHocDateForName,
                    text: 'nameSearchTaskMenu.createAdHocDate',
                    icon: 'cpa-icon cpa-icon-calendar-plus-o',
                    action: this.manageTaskOperation
                });
            }
        }
        if (nsp.canAccessDocumentsFromDms) {
            tasks.push({
                id: NameTaskMenuItemOperationType.openDms,
                text: 'searchResults.dms.title',
                icon: 'cpa-icon cpa-icon-file-text-folder-open-o',
                action: () => {
                    this.modalService.openModal(DmsModalComponent, {
                        backdrop: 'static',
                        class: 'modal-xl modal-dms',
                        initialState: {
                            nameKey: dataItem.nameKey
                        }
                    });
                }
            });
        }
        if (isHosted && dataItem.isEditable) {
            if (nsp.canMaintainContactActivity) {
                tasks.push({
                    id: NameTaskMenuItemOperationType.newActivityWizardForName,
                    text: 'nameSearchTaskMenu.createContactActivity',
                    icon: 'cpa-icon cpa-icon-user-circle',
                    action: this.manageTaskOperation
                });
            }
            if (nsp.canMaintainOpportunity) {
                tasks.push({
                    id: NameTaskMenuItemOperationType.newOpportunityForName,
                    text: 'nameSearchTaskMenu.createOpportunity',
                    icon: 'cpa-icon cpa-icon-handshake-o',
                    action: this.manageTaskOperation
                });
            }
        }

        return tasks;
    }

    // tslint:disable-next-line: cyclomatic-complexity
    private configureCaseSearchTaskMenuItems(isHosted: boolean, dataItem: any, csp: CaseSearchPermissions): Array<any> {
        const tasks = [];
        if (isHosted && dataItem.isEditable) {
            const editCase = {
                id: 'editCase',
                text: 'caseTaskMenu.editCase',
                icon: 'cpa-icon cpa-icon-edit',
                action: this.noAction,
                items: []
            };

            if (csp.canMaintainCase) {
                editCase.items.push({
                    id: CaseTaskMenuItemOperationType.maintainCase,
                    parent: editCase,
                    text: 'caseTaskMenu.maintainCaseDetails',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canOpenWorkflowWizard) {
                editCase.items.push({
                    id: CaseTaskMenuItemOperationType.workflowWizard,
                    parent: editCase,
                    text: 'caseTaskMenu.openWorkflowWizard',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canOpenDocketingWizard) {
                editCase.items.push({
                    id: CaseTaskMenuItemOperationType.docketingWizard,
                    parent: editCase,
                    text: 'caseTaskMenu.openDocketingWizard',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canMaintainFileTracking) {
                editCase.items.push({
                    id: CaseTaskMenuItemOperationType.maintainFileLocation,
                    parent: editCase,
                    text: 'caseTaskMenu.maintainFileLocation',
                    action: this.manageTaskOperation
                });
            }
            if (editCase.items.length > 0) {
                tasks.push(editCase);
            }
            if (csp.canOpenFirstToFile) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.openFirstToFile,
                    text: 'caseTaskMenu.firstToFile',
                    icon: 'cpa-icon cpa-icon-folder-open-o',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canOpenWipRecord) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.recordWip,
                    text: 'caseTaskMenu.recordWip',
                    icon: 'cpa-icon cpa-icon-wip-o',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canOpenCopyCase) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.copyCase,
                    text: 'caseTaskMenu.copyCase',
                    icon: 'cpa-icon cpa-icon-file-stack-o',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canOpenReminders) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.openReminders,
                    text: 'caseTaskMenu.openReminders',
                    icon: 'cpa-icon cpa-icon-bell',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canCreateAdHocDate) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.createAdHocDate,
                    text: 'caseTaskMenu.createAdHocDate',
                    icon: 'cpa-icon cpa-icon-calendar-plus-o',
                    action: this.manageTaskOperation
                });
            }
            if (csp.canRequestCaseFile) {
                tasks.push({
                    id: CaseTaskMenuItemOperationType.requestCaseFile,
                    text: 'caseTaskMenu.requestCaseFile',
                    icon: 'cpa-icon cpa-icon-file-o-edit',
                    action: this.manageTaskOperation
                });
            }
        }

        if (this.viewData && this.viewData.programs && this.viewData.programs.length > 1) {
            const openWith = {
                id: 'openWithProgram',
                text: 'caseTaskMenu.openWith',
                icon: 'cpa-icon cpa-icon-folder-open-o',
                action: this.noAction,
                items: []
            };

            tasks.push(openWith);
            this.viewData.programs.forEach((program) => {
                openWith.items.push({
                    id: program.id,
                    text: program.name,
                    parent: openWith,
                    action: this.openWithProgram
                });
            });
        }

        if (csp.canUseTimeRecording) {
            tasks.push({
                id: CaseTaskMenuItemOperationType.recordTime,
                text: 'caseTaskMenu.recordTime',
                icon: 'cpa-icon cpa-icon-clock-o',
                action: () => {
                    TimeRecordingHelper.initiateTimeEntry(dataItem.caseKey);
                }
            }, {
                id: CaseTaskMenuItemOperationType.recordTimeWithTimer,
                text: 'caseTaskMenu.recordTimer',
                icon: 'cpa-icon cpa-icon-clock-timer',
                action: () => {
                    const timerService = this.injector.get<TimeRecordingTimerGlobalService>(TimeRecordingTimerGlobalService);
                    timerService.startTimerForCase(dataItem.caseKey);
                }
            });
        }

        if (csp.canAccessDocumentsFromDms) {
            const dmsTask = {
                id: CaseTaskMenuItemOperationType.openDms,
                text: 'searchResults.dms.title',
                icon: 'cpa-icon cpa-icon-file-text-folder-open-o',
                action: () => {
                    this.modalService.openModal(DmsModalComponent, {
                        backdrop: 'static',
                        class: 'modal-xl modal-dms',
                        initialState: {
                            caseKey: dataItem.caseKey
                        }
                    });
                }
            };

            tasks.splice(1, 0, dmsTask);
        }

        const webLink = {
            id: 'caseWebLinks',
            text: 'caseTaskMenu.openCaseWebLinks',
            icon: 'cpa-icon cpa-icon-bookmark',
            action: this.noAction,
            items: []
        };
        tasks.push(webLink);
        this.subscribeCaseWebLinks(dataItem, webLink);

        return tasks;
    }

    private readonly openWithProgram = (dataItem: any, event: any): void => {
        if (this.isHosted) {
            this.windowParentMessagingService.postNavigationMessage({ args: ['CaseDetails', dataItem.caseKey, dataItem.rowKey, event.item.id] });
        } else {
            const params = {
                id: dataItem.caseKey,
                rowKey: dataItem.rowKey,
                programId: event.item.id
            };
            this.stateService.go('caseview', params);
        }
    };

}

enum CaseTaskMenuItemOperationType {
    maintainCase = 'MaintainCase',
    workflowWizard = 'WorkflowWizard',
    docketingWizard = 'DocketingWizard',
    maintainFileLocation = 'MaintainFileLocation',
    openFirstToFile = 'OpenFirstToFile',
    recordWip = 'RecordWip',
    copyCase = 'CopyCase',
    recordTime = 'RecordTime',
    recordTimeWithTimer = 'RecordTimeWithTimer',
    openReminders = 'OpenReminders',
    createAdHocDate = 'CreateAdHocDate',
    requestCaseFile = 'RequestCaseFile',
    openDms = 'OpenDms'
}

enum NameTaskMenuItemOperationType {
    nameDetails = 'NameDetails',
    maintainNameText = 'MaintainNameText',
    maintainNameAttributes = 'MaintainNameAttributes',
    openDms = 'OpenDms',
    maintainName = 'MaintainName',
    adHocDateForName = 'AdHocDateForName',
    newOpportunityForName = 'NewOpportunityForName',
    newActivityWizardForName = 'NewActivityWizardForName'
}

enum PriorArtTaskMenuItemOperationType {
    maintainPriorArt = 'MaintainPriorArt'
}