import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnChanges, OnInit, SimpleChanges, TemplateRef, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { AttachmentPopupService } from 'common/attachments/attachments-popup/attachment-popup.service';
import { LocalSettings } from 'core/local-settings';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import * as moment from 'moment';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { eventNoteEnum } from 'portfolio/event-note-details/event-notes.model';
import { FormControlWarning } from 'shared/component/forms/form-control-warning';
import { ValidationError } from 'shared/component/forms/validation-error';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { CaseDetailService } from '../case-detail.service';
import { EventRulesComponent } from '../event-rules/event-rules.component';
import { CaseViewViewData } from '../view-data.model';
import { ActionEventsCriteria, ActionEventsRequestModel, ActionModel } from './action-model';
import { CaseViewActionsService } from './case-view.actions.service';

@Component({
    selector: 'ipx-case-view-action-events',
    templateUrl: './action-events.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseviewActionEventComponent implements OnInit, OnChanges {
    formData?: any;
    topic: Topic;
    @ViewChild('grid', { static: true }) grid: IpxKendoGridComponent;
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChild('ipxHasNotesColumn', { static: true }) hasNotesCol: TemplateRef<any>;
    @ViewChild('ipxdefaultEventTextColumn', { static: true }) defaultEventTextCol: TemplateRef<any>;

    @Input() viewData: CaseViewViewData;
    @Input() dmsConfigured: boolean;
    @Input() action: ActionModel;
    @Input() isPotential: any;
    @Input() eventNoteTypes: any;
    errorsDetails: Array<ValidationError>;
    rowEditUpdates: { [rowKey: string]: any };
    eventNoteEnum = eventNoteEnum;
    today = moment();
    formGroup: FormGroup;
    selectedAction: ActionModel;
    gridOptions: IpxGridOptions;
    gridSearchFlags = {
        gridCreated: false,
        searchOnCreation: false,
        isAllEvents: false,
        isAllEventDetails: false,
        isAllCycles: false
    };
    isFirstPotential = false;
    originalData: any;
    isHosted = false;
    canViewRuleDetails = false;
    ruleDetailsModalRef: BsModalRef;
    q: ActionEventsRequestModel;
    siteControlId: number;
    eventNotesLoaded = false;
    taskItems: any;
    notesHoverText: string;
    baseType: 'case' | 'name' | 'activity';
    modalRef: BsModalRef;

    private readonly rowMaintenanceSetting = {
        canEdit: true, inline: true, hideButtons: true,
        rowEditKeyField: 'eventCompositeKey'

    };
    constructor(private readonly service: CaseViewActionsService,
        private readonly localSettings: LocalSettings,
        private readonly cdr: ChangeDetectorRef,
        private readonly windowParentMessagingService: WindowParentMessagingService,
        private readonly rootScopeService: RootScopeService,
        private readonly caseDetailService: CaseDetailService,
        private readonly formBuilder: FormBuilder,
        private readonly dateHelper: DateHelper,
        private readonly notificationService: NotificationService,
        private readonly modalService: IpxModalService,
        private readonly attachmentModalService: AttachmentModalService,
        private readonly attachmentPopupService: AttachmentPopupService
        ) {
    }

    ngOnInit(): void {
        this.service.siteControlId().subscribe(siteControl => {
            this.siteControlId = siteControl;
            this.eventNotesLoaded = true;
        });
        this.canViewRuleDetails = this.viewData.canViewRuleDetails;
        this.isHosted = this.rootScopeService.isHosted;
        this.baseType = 'case';
        this.notesHoverText = this.isHosted ? 'caseview.actions.events.eventNoteHover' : 'caseview.actions.events.eventNoteHover';
        this.populateFlags();
        this.gridOptions = this.buildGridOptions();
        this.caseDetailService.resetChanges$.subscribe((val: boolean) => {
            if (val) {
                this.resetForms();
            }
        });
        if (!!this.viewData.canMaintainCaseEvent) {
            this.rowEditUpdates = {};
            this.caseDetailService.errorDetails$.subscribe(errs => {
                this.setErrors(errs);
            });
        }

        this.attachmentModalService.attachmentsModified.subscribe(() => {
            this.grid.search();
            this.cdr.markForCheck();
        });
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes.isPotential && changes.isPotential.currentValue) {
            this.isFirstPotential = changes.isPotential.currentValue === true;
        }
        if (changes.action) {
            this.selectedAction = changes.action.currentValue;
            this.attachmentPopupService.clearCache();
            if (changes.action.currentValue.isPotential === true && this.isFirstPotential) {
                this.gridSearchFlags.isAllEvents = true;
                this.isFirstPotential = false;
                this.searchAllEvents();
            } else {
                this.search();
            }
        }
    }

    createFormGroup = (dataItem: any): FormGroup => {
        const formGroup = this.formBuilder.group({
            eventCompositeKey: dataItem.eventCompositeKey,
            eventDate: (!dataItem || !dataItem.eventDate) ? null : new FormControlWarning(new Date(dataItem.eventDate)),
            eventDueDate: (!dataItem || !dataItem.eventDueDate) ? null : new FormControlWarning(new Date(dataItem.eventDueDate)),
            name: new FormControl(),
            nameType: new FormControl()
        });

        this.gridOptions.formGroup = formGroup;

        setTimeout(() => {
            formGroup.controls.name.setValue(!dataItem || !dataItem.nameId ? null : { key: dataItem.nameId, displayName: dataItem.responsibility });
            formGroup.controls.nameType.setValue((!dataItem || !dataItem.nameTypeId) ? null : { key: dataItem.nameTypeId, value: dataItem.responsibility });
            formGroup.markAsPristine();
        }, 10);

        return formGroup;
    };

    getChanges = (): any => {
        const rows = Object.keys(this.rowEditUpdates).map((k: string) => this.rowEditUpdates[k]) || [];

        return { actions: { rows } };
    };

    viewRuleDetails = (eventNo: number): void => {
        this.ruleDetailsModalRef = this.modalService.openModal(EventRulesComponent, {
            animated: false,
            ignoreBackdropClick: true,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                eventNo,
                canMaintainWorkflow: this.selectedAction.hasEditableCriteria,
                q: this.q
            }
        });
    };

    setErrors = (errors: Array<ValidationError>): void => {
        if (errors) {
            this.clearWarnings();
            errors.map((errs) => {
                const fg = this.grid.rowEditFormGroups[String(errs.id)];
                if (fg) {
                    if (errs.field.toLowerCase() === 'eventdate' && fg.controls.eventDate) {
                        if (errs.severity === 'warning') {
                            (fg.controls.eventDate as FormControlWarning).warnings = [...(fg.controls.eventDate as FormControlWarning).warnings || [], ...[errs.message]];
                            fg.controls.eventDate.setErrors(fg.controls.eventDate.errors ? { messages: fg.controls.eventDate.errors.messages } : null);
                        } else if (errs.severity === 'error') {
                            fg.controls.eventDate.setErrors({ messages: fg.controls.eventDate.errors ? [...fg.controls.eventDate.errors.messages || [], ...[errs.message]] : [errs.message] });
                        }
                    } else if (errs.field.toLowerCase() === 'duedate' && fg.controls.eventDueDate) {
                        if (errs.severity === 'warning') {
                            (fg.controls.eventDueDate as FormControlWarning).warnings = [...(fg.controls.eventDueDate as FormControlWarning).warnings || [], ...[errs.message]];
                            fg.controls.eventDueDate.setErrors(fg.controls.eventDueDate.errors ? { messages: fg.controls.eventDueDate.errors.messages } : []);
                        } else if (errs.severity === 'error') {
                            fg.controls.eventDueDate.setErrors({ messages: fg.controls.eventDueDate.errors ? [...fg.controls.eventDueDate.errors.messages || [], ...[errs.message]] : [errs.message] });
                        }
                    } else if (errs.field && fg.controls[errs.field]) {
                        fg.controls[errs.field].setErrors({ messages: errs.message });
                    }

                    this.refreshStatus();
                    this.cdr.markForCheck();
                }
            });
        }
    };

    private readonly populateFlags = (): void => {
        this.gridSearchFlags.isAllEvents = this.localSettings.keys.caseView.eventOptions.isAllEvents.getLocal || false;
        this.gridSearchFlags.isAllCycles = this.localSettings.keys.caseView.eventOptions.isAllCycles.getLocal || false;
        this.gridSearchFlags.isAllEventDetails = this.localSettings.keys.caseView.eventOptions.isAllEventDetails.getLocal || false;
    };
    private readonly clearWarnings = () => {
        Object.keys(this.grid.rowEditFormGroups).forEach((k) => {
            Object.keys(this.grid.rowEditFormGroups[k].controls).map((fcKey) => {
                (this.grid.rowEditFormGroups[k].controls[fcKey] as FormControlWarning).warnings = null;
            });
        });
    };
    private resetForms(): void {
        this.rowEditUpdates = {};
        this.grid.rowEditFormGroups = null;
        this.grid.search();
    }

    dataBound = (data: Array<any>): void => {
        this.originalData = data;
    };

    searchAllEvents = () => {
        this.gridSearchFlags.isAllCycles = this.gridSearchFlags.isAllEvents;
        this.localSettings.keys.caseView.eventOptions.isAllEvents.setLocal(this.gridSearchFlags.isAllEvents);
        this.localSettings.keys.caseView.eventOptions.isAllCycles.setLocal(this.gridSearchFlags.isAllCycles);
        this.search();
    };

    searchAllCycles = () => {
        if (!this.gridSearchFlags.isAllCycles) {
            this.gridSearchFlags.isAllEvents = false;
        }
        this.localSettings.keys.caseView.eventOptions.isAllEvents.setLocal(this.gridSearchFlags.isAllEvents);
        this.localSettings.keys.caseView.eventOptions.isAllCycles.setLocal(this.gridSearchFlags.isAllCycles);
        this.search();
    };

    search = () => {
        if (this.selectedAction && this.gridOptions) {
            this.gridOptions._search();
        }
    };

    isAllEventDetailsChanged = () => {
        this.localSettings.keys.caseView.eventOptions.isAllEventDetails.setLocal(this.gridSearchFlags.isAllEventDetails);
    };

    private readonly buildGridOptions = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            sortable: true,
            scrollableOptions: { mode: scrollableMode.scrollable },
            showGridMessagesUsingInlineAlert: false,
            reorderable: true,
            pageable: {
                pageSizeSetting: this.localSettings.keys.caseView.actions.eventPageNumber
            },
            selectable: {
                mode: 'single'
            },
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: ''
            },
            read$: (queryParams) => {
                const criteria: ActionEventsCriteria = {
                    caseKey: this.viewData.caseKey, actionId: this.selectedAction.actionId, cycle: this.selectedAction.cycle,
                    criteriaId: this.selectedAction.criteriaId, importanceLevel: this.selectedAction.importanceLevel, isCyclic: this.selectedAction.isCyclic,
                    isAllEvents: this.gridSearchFlags.isAllEvents, isMostRecentCycle: !this.gridSearchFlags.isAllCycles
                };
                this.q = {
                    criteria,
                    params: queryParams
                };

                return this.service.getActionEvents$(this.q);
            },
            customRowClass: (context) => {
                let returnValue = '';

                if (context.dataItem.isProtentialEvents) {
                    returnValue += 'text-grey-highlight';
                }
                if (context.dataItem.isEdited) {
                    returnValue += ' edited';
                }

                return returnValue;
            },
            columns: this.getColumns(),
            columnPicker: true,
            columnSelection: {
                localSetting: this.localSettings.keys.caseView.actions.eventsColumnsSelection
            },
            onDataBound: (boundData: any) => {
                this.gridOptions._closeEditMode();
            },
            showContextMenu: (!!this.isHosted && (!!this.viewData.canMaintainCaseEvent || !!this.viewData.maintainEventNotes)) || !!this.viewData.canAddAttachment
        };

        if (!!this.viewData.canMaintainCaseEvent && this.rootScopeService.isHosted) {
            Object.assign(options, {
                rowMaintenance: this.rowMaintenanceSetting,

                // tslint:disable-next-line: unnecessary-bind
                createFormGroup: this.createFormGroup.bind(this)

            });
        }

        return this.setGridOptionsForEventNotes(options);
    };
    alertEventDate = (data: any, fg: FormGroup, rowIndex: number) => {
        const pageRowIndex = this.grid.pageRowIndex(rowIndex);
        const areDatesEqual = this.dateHelper.areDatesEqual(fg.value.eventDate, String(this.originalData.data[pageRowIndex].eventDate));
        const bothNull = (fg.value.eventDate === null) && (this.originalData.data[pageRowIndex].eventDate == null);
        if (this.originalData.data[pageRowIndex].eventCompositeKey === fg.value.eventCompositeKey) {
            (fg.controls.eventDate as FormControlWarning).warnings = null;
            if (bothNull || !this.dateHelper.areDatesEqual(data, String(this.originalData.data[pageRowIndex].eventDate))) {
                if (data && moment().isBefore(moment(data), 'day')) {
                    this.notificationService.info(
                        { message: 'caseview.actions.events.eventDateAlert', continue: 'Ok' });

                }
                if (!this.viewData.clearCaseEventDates && (this.originalData.data[pageRowIndex].eventDate && !data)) {
                    fg.controls.eventDate.setValue(new Date(this.originalData.data[pageRowIndex].eventDate));
                    this.notificationService.alert(
                        { message: 'field.errors.caseview.actions.events.noClearEventDatePermission', continue: 'Ok' });
                } else {
                    this.rowChanged(fg.value, pageRowIndex, bothNull || !areDatesEqual);
                }
            } else {
                fg.controls.eventDate.markAsPristine();
                fg.controls.eventDate.markAsTouched();
                this.rowChanged(fg.value, pageRowIndex, bothNull || !areDatesEqual);
            }
            this.cdr.markForCheck();
        }
    };
    alertDueDate = (data: any, fg: FormGroup, rowIndex: number) => {
        const pageRowIndex = this.grid.pageRowIndex(rowIndex);
        const areDatesEqual = this.dateHelper.areDatesEqual(fg.value.eventDueDate, String(this.originalData.data[pageRowIndex].eventDueDate));
        const bothNull = (fg.value.eventDueDate === null) && (this.originalData.data[pageRowIndex].eventDueDate == null);
        if (this.originalData.data[pageRowIndex].eventCompositeKey === fg.value.eventCompositeKey) {
            (fg.controls.eventDueDate as FormControlWarning).warnings = null;
            if (bothNull || !this.dateHelper.areDatesEqual(data, String(this.originalData.data[pageRowIndex].eventDueDate))) {
                if (data && moment().isAfter(moment(data), 'day')) {
                    this.notificationService.info(
                        { message: 'caseview.actions.events.eventDueDateAlert', continue: 'Ok' });
                    const element: any = document.querySelector('#actionFirstRow');
                    if (element) {
                        setTimeout(() => {
                            element.scrollIntoView();
                        }, 100);
                    }
                }
                this.rowChanged(fg.value, pageRowIndex, bothNull || !areDatesEqual);
            } else {
                fg.controls.eventDueDate.markAsPristine();
                fg.controls.eventDueDate.markAsTouched();
                this.rowChanged(fg.value, pageRowIndex, bothNull || !areDatesEqual);
            }
            this.cdr.markForCheck();
        }
    };

    updateNameOrNameType = (caller: 'name' | 'nameType', data: any, fg: FormGroup, rowIndex: number) => {
        const pageRowIndex = this.grid.pageRowIndex(rowIndex);
        if (caller === 'name' && fg.controls.name.dirty) {
            if (data && fg.value.nameType !== null) {
                fg.controls.nameType.reset();
            }

            this.rowChanged(fg.value, pageRowIndex, (data ? data.key : null) !== this.originalData.data[pageRowIndex].nameId);

        } else if (caller === 'nameType' && fg.controls.nameType.dirty) {
            if (data && fg.value.name !== null) {
                fg.controls.name.reset();
            }
            this.rowChanged(fg.value, pageRowIndex, (data ? data.key : null) !== this.originalData.data[pageRowIndex].nameTypeId);
        }
    };

    cancelRowEdit = (rowKey: Event) => {
        if (rowKey && this.rowEditUpdates[String(rowKey)]) {
            // tslint:disable-next-line:no-dynamic-delete
            delete this.rowEditUpdates[String(rowKey)];
            this.refreshStatus();
        }
    };

    private readonly rowChanged = (data: any, rowIndex: number, changedFromOrigin: boolean): void => {
        const key = String(this.originalData.data[rowIndex].eventCompositeKey);
        if (changedFromOrigin) {
            Object.assign(this.rowEditUpdates, {
                [key]: {
                    ...data,
                    ...{
                        actionId: this.action.actionId,
                        eventCompositeKey: key,
                        criteriaId: this.action.criteriaId,
                        eventNo: this.originalData.data[rowIndex].eventNo,
                        cycle: this.originalData.data[rowIndex].cycle,
                        eventDate: data.eventDate ? this.dateHelper.toLocal(data.eventDate) : null,
                        eventDueDate: data.eventDueDate ? this.dateHelper.toLocal(data.eventDueDate) : null,
                        nameId: data.name ? data.name.key : null,
                        nameTypeKey: data.nameType ? data.nameType.code : null
                    }
                }
            });
        }
        this.refreshStatus();
    };

    private readonly refreshStatus = () => {
        const isValid = this.grid.isValid();
        this.caseDetailService.hasPendingChanges$.next(isValid && Object.keys(this.rowEditUpdates || {}).length > 0);
    };

    openEventHistoryWindow = (dataItem: any): void => {
        this.windowParentMessagingService.postNavigationMessage({
            args: ['EventHistory', this.viewData.caseKey, dataItem.eventNo, dataItem.cycle, this.action.criteriaId]
        });
    };

    openAttachmentWindow = (dataItem: any): void => {
        if (this.isHosted) {
            this.windowParentMessagingService.postNavigationMessage({
                args: ['CaseEventAttachments', this.viewData.caseKey, this.selectedAction.actionId, dataItem.eventNo, dataItem.cycle]
            });

            return;
        }

        this.attachmentModalService.displayAttachmentModal('case', this.viewData.caseKey, {
            actionKey: this.selectedAction.actionId,
            eventKey: dataItem.eventNo,
            eventCycle: dataItem.cycle
        });
    };

    openEventNotesWindow = (dataItem: any): void => {
        if (this.caseDetailService.hasPendingChanges$.value) {
            this.notificationService.info({
                message: 'caseview.actions.events.editEventNoteAlert',
                continue: 'Ok',
                title: 'caseview.actions.events.warning'
            });
        } else {
            this.windowParentMessagingService.postNavigationMessage({
                args: ['EventNotes', this.viewData.caseKey, dataItem.eventNo, dataItem.cycle]
            });
        }
    };

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const attachmentColumn = this.viewData.hasAccessToAttachmentSubject ? [{
            title: '',
            field: 'attachmentCount',
            width: 40,
            template: true,
            sortable: false,
            fixed: true
        }] : [];

        const historyColumn = this.isHosted && this.viewData.hasCaseEventAuditingConfigured ? [{
            title: '',
            field: 'hasEventHistory',
            width: 30,
            template: true,
            sortable: false
        }] : [];

        return [...attachmentColumn,
        ...historyColumn,
        {
            title: 'caseview.actions.events.event',
            field: 'eventDescription',
            width: 150,
            menu: true,
            template: true
        }, {
            title: 'caseview.actions.events.eventDate',
            field: 'eventDate',
            width: 150,
            menu: true,
            defaultColumnTemplate: DefaultColumnTemplateType.date,
            type: 'date',
            template: true
        }, {
            title: 'caseview.actions.events.dueDate',
            field: 'eventDueDate',
            width: 150,
            menu: true,
            template: true
        }, {
            title: 'caseview.actions.events.cycle',
            field: 'cycle',
            width: 100,
            menu: true
        }, {
            title: 'caseview.actions.events.nextPolice',
            field: 'nextPoliceDate',
            width: 100,
            menu: true,
            defaultColumnTemplate: DefaultColumnTemplateType.date
        }, {
            title: 'caseview.actions.events.eventNo',
            field: 'eventNo',
            width: 100,
            menu: true,
            key: true,
            template: true
        }, {
            title: 'caseview.actions.events.criteria',
            field: 'createdByCriteria',
            width: 80,
            menu: true,
            template: true
        }, {
            title: 'caseview.actions.events.createdByAction',
            field: 'createdByActionDesc',
            width: 150,
            menu: true
        }, {
            title: 'caseview.actions.events.fromCase',
            width: 150,
            field: 'fromCaseIrn',
            menu: true,
            template: true,
            hidden: true
        }, {
            title: 'caseview.actions.events.period',
            field: 'period',
            width: 150,
            menu: true,
            hidden: true
        }, {
            title: 'caseview.actions.events.name',
            field: 'name',
            width: 150,
            menu: true,
            hidden: true,
            template: true
        }, {
            title: 'caseview.actions.events.nameType',
            field: 'nameType',
            width: 150,
            menu: true,
            hidden: true,
            template: true
        }, {
            title: 'caseview.actions.events.stopPolicing',
            field: 'stopPolicing',
            width: 80,
            menu: true,
            template: true,
            hidden: true
        }, {
            title: 'caseview.actions.events.dueDateSaved',
            field: 'isManuallyEntered',
            menu: true,
            hidden: true,
            width: 80,
            template: true
        }];
    };
    onMenuItemSelected = (menuEventDataItem: any): void => {
        menuEventDataItem.event.item.action(menuEventDataItem.dataItem);
    };
    displayTaskItems = (dataItem: any): void => {
        this.taskItems = this.grid.getRowMaintenanceMenuItems(dataItem);
        if (this.viewData.canAddAttachment) {
            this.taskItems.push({
                id: 'addAttachment',
                text: 'caseview.actions.events.addAttachment',
                icon: 'cpa-icon cpa-icon-paperclip',
                action: this.triggerAddAttachment
            });
        }
        if (this.isHosted && this.viewData.maintainEventNotes) {
            this.taskItems.push({
                id: 'maintainEventNote',
                text: 'caseview.actions.events.eventNoteMenuItem',
                icon: 'cpa-icon cpa-icon-file-o',
                action: this.openEventNotesWindow,
                disabled: dataItem.isProtentialEvents
            });
        }
    };
    triggerAddAttachment = (dataItem: any): void => {
        if (this.isHosted) {
            this.windowParentMessagingService.postNavigationMessage({
                args: ['OpenMaintainAttachment', this.viewData.caseKey, '', '', this.selectedAction.actionId, dataItem.eventNo, dataItem.cycle]
            });

            return;
        }

        this.attachmentModalService.triggerAddAttachment('case', this.viewData.caseKey, { eventKey: dataItem.eventNo, eventCycle: dataItem.cycle, actionKey: this.action.actionId });
    };

    private readonly setGridOptionsForEventNotes = (gridOptions: IpxGridOptions): IpxGridOptions => {
        if (this.eventNoteTypes && this.eventNoteTypes.length > 0) {
            gridOptions.detailTemplateShowCondition = (dataItem: any): boolean => dataItem.eventNotes && dataItem.eventNotes.length > 0;

            gridOptions.detailTemplate = this.detailTemplate;
            gridOptions.columns.splice(0, 0, {
                width: 40,
                title: '',
                field: 'hasNotes',
                fixed: true,
                sortable: false,
                menu: false,
                template: this.hasNotesCol
            });
            gridOptions.columns.push({
                title: 'caseview.actions.events.eventNotes',
                field: 'defaultEventText',
                width: 150,
                // encoded: true,
                menu: true,
                hidden: true,
                sortable: false,
                template: this.defaultEventTextCol
            });
        }

        return gridOptions;
    };

    onReload = (): void => {
        this.gridOptions._search();
    };
}