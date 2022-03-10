import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { BusService } from 'core/bus.service';
import { LocalSettings } from 'core/local-settings';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject } from 'rxjs';
import { take } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { PingService } from 'shared/shared-services/ping.service';
import { MaintenanceTopicContract } from '../base/case-view-topics.base.component';
import { CaseDetailService, TopicChanges } from '../case-detail.service';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { PolicingService } from '../policing/policing.service';
import { CaseViewViewData } from '../view-data.model';
import { CaseviewActionEventComponent } from './action-events.component';
import { ActionModel } from './action-model';
import { CaseViewActionsService } from './case-view.actions.service';

@Component({
    selector: 'ipx-case-view-action',
    templateUrl: './actions.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseviewActionsComponent implements MaintenanceTopicContract, OnInit, OnDestroy {
    @ViewChild('ipxKendoGridRef') grid: IpxKendoGridComponent;
    @ViewChild('ipxActionStatusColumn') statusCol: TemplateRef<any>;
    @ViewChild('ipxPoliceColumn') policeColumn: TemplateRef<any>;
    @ViewChild('actionEvents') actionEvents: CaseviewActionEventComponent;
    @ViewChild('ipxHasNotesColumn', { static: true }) hasNotesCol: TemplateRef<any>;

    topic: Topic;
    viewData: CaseViewViewData;
    dmsConfigured: boolean;
    gridOptions: IpxGridOptions;
    importanceLevelOptions: any;
    selectedAction: ActionModel;
    permissions = {
        canMaintainWorkflow: false,
        canPoliceActions: false,
        requireImportanceLevel: false
    };
    formData = {
        importanceLevel: null,
        includeOpenActions: true,
        includeClosedActions: false,
        includePotentialActions: false
    };

    eventNoteTypes: any;
    subscription: any;
    isPoliceImmediately: boolean;

    isEditing = false;
    constructor(private readonly service: CaseViewActionsService,
        private readonly caseDetailService: CaseDetailService,
        private readonly localSettings: LocalSettings,
        private readonly cdr: ChangeDetectorRef,
        private readonly policingService: PolicingService,
        private readonly notificationService: IpxNotificationService,
        private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly bus: BusService,
        private readonly ping: PingService
    ) {
    }

    ngOnInit(): void {
        this.viewData = this.topic.params.viewData;

        this.service.getViewData$(this.viewData.caseKey).subscribe(resp => {
            this.permissions.canMaintainWorkflow = resp.canMaintainWorkflow;
            this.permissions.canPoliceActions = resp.canPoliceActions;
            this.viewData.canViewRuleDetails = resp.canViewRuleDetails;
            this.isPoliceImmediately = resp.isPoliceImmediately;
            this.viewData.maintainEventNotes = resp.maintainEventNotes;
            this.viewData.canMaintainCaseEvent = resp.maintainCaseEvent;
            this.viewData.clearCaseEventDates = resp.clearCaseEventDates;
            this.viewData.canAddAttachment = resp.canAddAttachment;
            this.dmsConfigured = resp.canAccessDocumentsFromDms;
            this.populateOptions();
            this.caseDetailService.getImportanceLevelAndEventNoteTypes$().subscribe(response => {
                this.formData.importanceLevel = this.defaultImportanceLevel(response.importanceLevel, response.importanceLevelOptions);
                this.permissions.requireImportanceLevel = response.requireImportanceLevel;
                this.importanceLevelOptions = response.importanceLevelOptions;
                this.eventNoteTypes = response.eventNoteTypes;
                this.gridOptions = this.buildGridOptions();
                this.cdr.markForCheck();
                setTimeout(() => {
                    this.searchAndSelectGrid();
                    this.cdr.markForCheck();
                }, 0);
            });
        });

        this.subscription = this.bus.channel('policingCompleted').subscribe(() => this.gridOptions._search());
        this.caseDetailService.hasPendingChanges$.subscribe(s => {
            this.isEditing = s;
            this.cdr.markForCheck();
        });
    }

    ngOnDestroy(): void {
        this.subscription.unsubscribe();
    }
    changeImportanceLevel = (): void => {
        this.searchAndSelectGrid();
        this.localSettings.keys.caseView.importanceLevelCacheKey.setSession(this.formData.importanceLevel);
    };

    getChanges = (): { [key: string]: any } => {

        return this.actionEvents.getChanges();
    };
    onError = (): void => {
        if (this.topic.setErrors) {
            this.topic.setErrors(true);
        }
    };

    applyOption = (source: 'open' | 'close' | 'potential') => {
        switch (source) {
            case 'open':
                this.localSettings.keys.caseView.actionOptions.includeOpenActions.setLocal(this.formData.includeOpenActions);
                break;
            case 'close':
                this.localSettings.keys.caseView.actionOptions.includeClosedActions.setLocal(this.formData.includeClosedActions);
                break;
            case 'potential':
                this.localSettings.keys.caseView.actionOptions.includePotentialActions.setLocal(this.formData.includePotentialActions);
                break;
            default:
                break;
        }
        this.loadAction();
    };

    loadAction = () => {
        this.searchAndSelectGrid();
    };

    private readonly populateOptions = (): void => {
        this.formData.includeOpenActions = this.localSettings.keys.caseView.actionOptions.includeOpenActions.getLocal != null ? this.localSettings.keys.caseView.actionOptions.includeOpenActions.getLocal : true;
        this.formData.includeClosedActions = this.localSettings.keys.caseView.actionOptions.includeClosedActions.getLocal || false;
        this.formData.includePotentialActions = this.localSettings.keys.caseView.actionOptions.includePotentialActions.getLocal || false;
    };
    private readonly buildGridOptions = (): IpxGridOptions => {
        return {
            // id: 'caseview-actions',
            sortable: true,
            navigable: true,
            showGridMessagesUsingInlineAlert: false,
            resetGridSelectionOnDataBind: false,
            autobind: false,
            reorderable: true,
            pageable: {
                pageSizes: [5, 10, 20, 50],
                pageSizeSetting: this.localSettings.keys.caseView.actions.pageNumber
            },
            selectable: {
                mode: 'single'
            },
            customRowClass: (context) => {
                if (context.dataItem.isPotential) {
                    return 'text-grey-highlight';
                }
                if (context.dataItem.isClosed) {
                    return 'text-red-dark';
                }

                return '';
            },
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: ''
            },
            read$: (queryParams) => {
                return this.service.getActions$(this.viewData.caseKey, this.formData.importanceLevel, this.formData.includeOpenActions, this.formData.includeClosedActions, this.formData.includePotentialActions, queryParams);
            },

            columns: this.getColumns()
        };
    };

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const eventNotesColumn = this.eventNoteTypes && this.eventNoteTypes.length > 0 ? [{
            width: 40,
            title: '',
            field: 'hasNotes',
            fixed: true,
            sortable: false,
            menu: false,
            template: this.hasNotesCol
        }] : [];

        const policingTaskPermissionColumn = this.permissions.canPoliceActions ? [{
            title: 'caseview.actions.police',
            field: 'name',
            template: this.policeColumn
        }] : [];

        const refreshEventsColumn = {
            title: 'caseview.actions.refreshAction',
            field: 'refresh',
            width: 10,
            sortable: false,
            template: true
        };

        return [
            ...eventNotesColumn, {
                title: 'caseview.actions.actions',
                field: 'name'
            }, {
                title: 'caseview.actions.cycle',
                field: 'cycle'
            }, {
                title: 'caseview.actions.status',
                field: 'status',
                template: this.statusCol
            }, {
                title: 'caseview.actions.criteria',
                field: 'criteriaId',
                template: true
            }, ...policingTaskPermissionColumn, refreshEventsColumn];
    };

    private readonly searchAndSelectGrid = () => {
        this.grid.search();
    };

    private readonly defaultImportanceLevel = (importanceLevel: number, importanceLevelOptions: Array<{ code: number, description: string }>): number => {
        const cacheValue = this.localSettings.keys.caseView.importanceLevelCacheKey.getSession;
        if (cacheValue && importanceLevelOptions.find((item: any) => {
            return item.code === cacheValue;
        })) {
            return cacheValue;
        }

        return importanceLevel;
    };

    caseviewActionDatabound = (): void => {
        let selectedActionCode = '';
        if (this.selectedAction) {
            selectedActionCode = this.selectedAction.actionId;
        }
        this.selectedAction = null;
        const data: Array<any> = this.grid.getCurrentData();
        if (data && data.length > 0) {
            const index = data.findIndex((item: any) => {
                return item.code === selectedActionCode;
            });
            this.grid.navigateByIndex(index > 0 ? index : 0);
        }
    };

    policeAction = (action): void => {
        const notificationRef = this.notificationService.openConfirmationModal('caseview.actions.confirmPolicing', 'caseview.actions.areYouSurePolicing', 'caseview.actions.police');

        notificationRef.content.confirmed$.pipe(
            take(1))
            .subscribe(() => {
                this.policeActionConfirmed(action);
            });
    };

    onRequestDataResponseReceived = {} as any;
    policeActionConfirmed = (action): void => {
        this.windowParentMessagingService.postRequestForData('isPoliceImmediately', 'actionHost', this, () => {
            return Promise.resolve(this.isPoliceImmediately);
        }).then(isPoliceImmediately => {
            this.policeImmediatelyResolved(action, isPoliceImmediately);
        });
    };

    policeImmediatelyResolved = (action, isPoliceImmediately: boolean): void => {
        let policingModal: BsModalRef = null;
        const policeActionModel = {
            actionId: action.code,
            caseId: this.viewData.caseKey,
            cycle: action.cycle,
            isPoliceImmediately: isPoliceImmediately == null ? this.isPoliceImmediately : isPoliceImmediately
        };
        this.ping.ping().then(() => {
            if (policeActionModel.isPoliceImmediately) {
                this.windowParentMessagingService.postNavigationMessage({
                    action: 'StartPolicing',
                    args: [policeActionModel.caseId, policeActionModel.actionId]
                }, () => {
                    policingModal = this.notificationService.openPolicingModal();
                });
            }
            this.policingService.policeAction(policeActionModel).then(() => {
                this.windowParentMessagingService.postNavigationMessage({
                    action: 'StopPolicing',
                    args: [this.viewData.caseKey, action.code, true]
                });
                this.loadAction();
                if (policingModal) {
                    policingModal.hide();
                    this.cdr.markForCheck();
                }
            }).catch(() => {
                this.windowParentMessagingService.postNavigationMessage({
                    action: 'StopPolicing',
                    args: [this.viewData.caseKey, action.code, false]
                });
                if (policingModal) {
                    policingModal.hide();
                    this.cdr.markForCheck();
                }
            });
        });
    };

    itemClicked = (selected: any, isForced = false): void => {
        if (isForced || (selected && (!this.selectedAction || this.selectedAction.actionId !== selected.code || this.selectedAction.cycle !== selected.cycle))) {
            this.selectedAction = selected ? new ActionModel(selected.code, selected.name, selected.criteriaId, selected.cycle, this.formData.importanceLevel, selected.cycles > 1, this.permissions.canMaintainWorkflow, selected.hasEditableCriteria, selected.isPotential, selected.isOpen) : null;
        }
    };

    onReload = (): void => {
        this.actionEvents.onReload();
    };

    refreshEvents = (item: any): void => {
        this.itemClicked(item, true);
    };
}
export class CaseviewActionsTopic extends Topic {
    readonly key = 'actions';
    readonly title = caseViewTopicTitles.actions;
    readonly component = CaseviewActionsComponent;
    constructor(public params: any) {
        super();
    }
}