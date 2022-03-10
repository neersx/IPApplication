import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { AdHocDateComponent } from 'dates/adhoc-date.component';
import { forkJoin, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';
import { MaintainActions } from 'search/task-planner/task-planner.data';
import { IpxTextFieldComponent } from 'shared/component/forms/ipx-text-field/ipx-text-field.component';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as  _ from 'underscore';
import { AdhocDateService } from './../../dates/adhoc-date.service';
import { EventNoteDetailsService } from './event-note-details.service';
import { eventNoteEnum, EventNoteViewData } from './event-notes.model';

@Component({
    selector: 'ipx-event-note-details',
    templateUrl: './event-note-details.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class EventNoteDetailsComponent implements OnInit, AfterViewInit {
    @Input() instructionDefinitionKey: number;
    @Output() readonly onUpdateInstructionNotes: EventEmitter<any> = new EventEmitter<any>();
    @Input() taskPlannerRowKey: string;
    @Input() notes: Array<any>;
    @Input() categories: Array<any>;
    @Input() eventNoteFrom: string;
    @Input() replaceEventNotes: string;
    @Input() maintainEventNotes: boolean;
    @Input() maintainEventNotesPermissions: any;
    @Input() isPredefinedNoteExists: boolean;
    @Input() viewData: EventNoteViewData;
    @Input() siteControlId: number;
    @Input() expandAction: string;
    @Output() readonly onSetNotesCount: EventEmitter<number> = new EventEmitter<number>();
    @Output() readonly onEventNoteUpdate: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onEventNoteChange: EventEmitter<any> = new EventEmitter<any>();
    @ViewChild('remindersGrid', { static: true }) grid: IpxKendoGridComponent;
    @ViewChild('eventNoteTextRef', { static: false }) eventNoteTextRef: IpxTextFieldComponent;
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('remindersGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
        }
    }
    canMaintain: boolean;
    gridOptions: IpxGridOptions;
    eventNoteEnum = eventNoteEnum;
    formGroup: FormGroup;
    currentRowIndex: number;
    eventTextItems: Array<{
        rowId: number,
        noteText: String,
        notetype: String,
        noteTypeDescription: String,
        noteLastUpdatedDate: string,
        noteTypeKey: number
    }>;
    hasNoteTypes: boolean;
    filteredCategories: Array<any>;
    status: string;
    startSelection: number;
    endSelection: number;
    defaultSiteControlText: string;
    promptText: string;
    cursorText: string;
    applySelection: boolean;
    saveCall = false;
    constructor(private readonly eventNoteDetailsService: EventNoteDetailsService,
        private readonly cdr: ChangeDetectorRef, readonly translate: TranslateService,
        private readonly formBuilder: FormBuilder,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly notificationService: NotificationService,
        private readonly modalService: IpxModalService,
        private readonly adHocDateService: AdhocDateService
    ) {
    }
    ngAfterViewInit(): void {
        setTimeout(() => {
            if (this.gridOptions.canAdd && (this.expandAction && this.expandAction === MaintainActions.notes.toString())) {
                this._resultsGrid.addRow();
            }
        }, 800);
    }

    ngOnInit(): void {
        this.canMaintain = (eventNoteEnum.taskPlanner === this.eventNoteFrom && this.maintainEventNotes) ||
            (eventNoteEnum.provideInstructions === this.eventNoteFrom && this.maintainEventNotes);
        if (this.categories && this.categories.length > 0) {
            this.hasNoteTypes = true;
        }
        this.filteredCategories = this.notes ? this.getCategories(this.notes.map(n => n.noteType), this.categories) : null;
        this.eventTextItems = this.getEventitems(this.notes, this.filteredCategories);
        this.onSetNotesCount.emit(this.eventTextItems.length);
        this.categories = this.categories.filter(x => x.code !== null);
        this.gridOptions = this.buildGridOptions();
    }

    dataBound = (): void => {
        const defaultNoteTypeDescription = this.filteredCategories.filter(fc => fc.isDefault).map(c => String(c.description));
        const gridMessages = {
            noResultsFound: this.translate.instant('caseview.actions.events.noDefaultEventNoteResults', { noteType: defaultNoteTypeDescription })
        };
        if (_.contains(defaultNoteTypeDescription, 'null')) {
            gridMessages.noResultsFound = 'caseview.actions.events.noGenericEventNoteResults';
        }
        this.gridOptions.gridMessages = gridMessages;
        this.cdr.detectChanges();
    };

    getRowIndex = (event): void => {
        this.currentRowIndex = event;
    };

    getEditedRowIndex = (event): void => {
        this.currentRowIndex = event.rowIndex;
    };

    private readonly buildGridOptions = (): IpxGridOptions => {
        const options: IpxGridOptions = {
            autobind: true,
            pageable: false,
            reorderable: false,
            sortable: false,
            navigable: true,
            filterable: true,
            disableMultiRowEditing: true,
            showGridMessagesUsingInlineAlert: false,
            canAdd: this.maintainEventNotesPermissions && this.maintainEventNotesPermissions.insert,
            enableGridAdd: this.maintainEventNotesPermissions && this.maintainEventNotesPermissions.insert,
            itemName: 'taskPlanner.eventNotes.itemEventNote',
            read$: (queryParams: GridQueryParameters) => {
                if (this.canMaintain) {
                    this.gridOptions.enableGridAdd = this.maintainEventNotesPermissions && this.maintainEventNotesPermissions.insert;
                    this.resetForm();
                    if (this.eventNoteFrom === eventNoteEnum.provideInstructions && this.notes.length > 0) {
                        this.eventTextItems = this.getEventitems(this.notes, this.categories);

                        return of(this.eventTextItems);
                    }
                    const eventNoteTypelst = this.eventNoteDetailsService.getEventNoteTypes$();
                    const noteDetails = this.eventNoteDetailsService.getEventNotesDetails$(this.taskPlannerRowKey);

                    return forkJoin([eventNoteTypelst, noteDetails]).pipe(
                        map(([noteTypeList, noteDetail]) => {
                            this.categories = noteTypeList;
                            if (this.categories && this.categories.length > 0) {
                                this.hasNoteTypes = true;
                            }
                            this.notes = noteDetail;
                            this.filteredCategories = this.notes ? this.getCategories(this.notes.map(n => n.noteType), this.categories) : null;
                            this.eventTextItems = this.getEventitems(this.notes, this.filteredCategories);
                            if (this.canMaintain && this.saveCall) {
                                const lastUpdatedDate = this.getLastUpdatedDate();
                                this.onEventNoteUpdate.emit({
                                    lastUpdatedDate,
                                    taskPlannerRowKey: this.taskPlannerRowKey
                                });
                            }
                            this.onSetNotesCount.emit(this.eventTextItems.length);
                            this.categories = this.categories.filter(x => x.code !== null);
                            if (queryParams && queryParams.filters && queryParams.filters.length > 0) {
                                const filters = queryParams.filters[0].value.split(',');
                                const operator = queryParams.filters[0].operator;
                                const field = queryParams.filters[0].field;
                                this.eventTextItems = this.eventTextItems.filter(t => operator === 'in' && field === 'notetype' ? filters.indexOf(String(t.notetype)) >= 0 : false);
                                _.each(this.eventTextItems, (item, index) => {
                                    item.rowId = index;
                                });

                                return this.eventTextItems;
                            }
                            this.saveCall = false;

                            return this.eventTextItems;
                        }));
                }
                if (queryParams && queryParams.filters && queryParams.filters.length > 0) {
                    const filters = queryParams.filters[0].value.split(',');
                    const operator = queryParams.filters[0].operator;
                    const field = queryParams.filters[0].field;

                    return of(this.eventTextItems
                        .filter(t => operator === 'in' && field === 'notetype' ? filters.indexOf(String(t.notetype)) >= 0 : false)).pipe(delay(100));
                }

                return of(this.eventTextItems).pipe(delay(100));

            },
            filterMetaData$: () => {

                return of(this.filteredCategories.map(i => ({ code: String(i.code), description: i.description }))).pipe(delay(100));
            },
            columns: this.getColumns()
        };
        if (this.canMaintain) {
            Object.assign(options, {
                rowMaintenance: {
                    canEdit: this.maintainEventNotesPermissions && this.maintainEventNotesPermissions.update,
                    inline: this.canMaintain,
                    rowEditKeyField: 'staffNameKey',
                    width: 20
                },
                createFormGroup: this.createFormGroup.bind(this)
            });
        }

        return options;
    };

    getLastUpdatedDate = () => {
        const sortBy = _.sortBy(this.eventTextItems.filter(e => e.noteLastUpdatedDate !== null), (o) => {
            return [new Date(o.noteLastUpdatedDate).getTime()];
        });
        if (sortBy.length > 0) {
            return _.last(sortBy).noteLastUpdatedDate;
        }
    };

    createFormGroup(dataItem: any): FormGroup {
        this.status = dataItem.status;
        let isNoteTypeDisable = this.categories.length > 0 ? false : true;
        if (this.status === rowStatus.editing) {
            isNoteTypeDisable = true;
        }

        let controls = {
            eventNoteType: new FormControl({ value: null, disabled: isNoteTypeDisable }),
            eventNoteText: new FormControl(),
            replaceNote: new FormControl({ value: null, disabled: this.status === rowStatus.editing }),
            createAdhoc: new FormControl()
        };
        if (this.isPredefinedNoteExists) {
            const predefinedNote = {
                predefinedNote: new FormControl({ value: null, disabled: this.status === rowStatus.editing })
            };

            controls = _.extend(controls, predefinedNote);
        }
        const formGroup = this.formBuilder.group(controls);
        if (this.status === rowStatus.Adding) {
            formGroup.controls.eventNoteText.setValidators(Validators.required);
            this.makeDefaultText();
        }
        const defaultNoteType = _.first(this.categories.filter(fc => fc.isDefault));
        if (this.isPredefinedNoteExists) {
            formGroup.controls.predefinedNote.setValue({});
        }
        formGroup.controls.eventNoteType.setValue(this.status === rowStatus.Adding ? defaultNoteType ? defaultNoteType.code : null : dataItem.notetype);
        formGroup.controls.eventNoteText.setValue((!dataItem || !dataItem.noteText) ? '' : dataItem.noteText);
        formGroup.controls.replaceNote.setValue(false);
        formGroup.markAsPristine();
        this.gridOptions.formGroup = formGroup;
        if (dataItem.status === rowStatus.Adding || dataItem.status === rowStatus.editing) {
            dataItem.showRevertAttributes = { display: false };
        }
        this.gridOptions.enableGridAdd = false;

        return formGroup;
    }

    makeDefaultText(): void {
        this.eventNoteDetailsService.viewDataFormatting().subscribe(result => {
            this.viewData = result;
            this.promptText = this.translate.instant('taskPlanner.eventNotes.promptText');
            this.cursorText = this.translate.instant('taskPlanner.eventNotes.cursorText',
                { name: this.viewData.friendlyName, time: this.viewData.timeFormat, date: this.viewData.dateStyle });
            this.defaultSiteControlText = '';
            switch (this.siteControlId) {
                case 1: {
                    this.defaultSiteControlText += this.cursorText + '\r\n' + this.promptText;
                    this.startSelection = this.cursorText.length + 1;
                    this.endSelection = this.startSelection + this.promptText.length;
                    break;
                }
                case 2: {
                    this.defaultSiteControlText += this.promptText + '\r\n' + this.cursorText;
                    this.startSelection = 0;
                    this.endSelection = this.promptText.length;
                    break;
                }
                default: {
                    this.startSelection = 0;
                    this.endSelection = this.promptText.length;
                    break;
                }
            }
            this.gridOptions.formGroup.controls.eventNoteText.setValue(this.defaultSiteControlText);
            if (this.status === rowStatus.Adding) {
                this.eventNoteTextRef.setSelectionRange(this.startSelection, this.endSelection);
            }
            this.cdr.detectChanges();
        });

    }

    rowDiscard(): void {
        if (!this.gridOptions.formGroup.dirty) {
            this.gridOptions.enableGridAdd = this.canMaintain;
            this.resetForm();
            this.grid.search();
        } else {
            const commentNotificationModalRef = this.ipxNotificationService.openDiscardModal();
            commentNotificationModalRef.content.confirmed$.subscribe(() => {
                this.gridOptions.enableGridAdd = this.canMaintain;
                this.resetForm();
                this.grid.search();
                commentNotificationModalRef.hide();
            });
        }
    }

    resetForm(): void {
        this.grid.rowEditFormGroups = null;
        this.gridOptions.formGroup = null;
        this.grid.currentEditRowIdx = this.currentRowIndex;
        this.grid.closeRow();
        this.cdr.detectChanges();
    }

    onSave = (): void => {
        if (!this.gridOptions.formGroup.valid) {
            return;
        }
        this.grid.isRowEditedState = false;
        const eventNotes = {
            caseEventId: null,
            eventNoteType: this.gridOptions.formGroup.value.eventNoteType === '' ? null : this.gridOptions.formGroup.value.eventNoteType,
            eventText: this.gridOptions.formGroup.value.eventNoteText === '' ? null : this.gridOptions.formGroup.value.eventNoteText,
            replaceNote: this.gridOptions.formGroup.value.replaceNote === undefined ? false : this.gridOptions.formGroup.value.replaceNote
        };
        this.makeEventNoteText(eventNotes);
        if (this.eventNoteFrom === eventNoteEnum.provideInstructions) {
            const notetype = eventNotes.eventNoteType === undefined ? null : eventNotes.eventNoteType;
            const note = {
                eventText: eventNotes.eventText,
                lastUpdatedDateTime: new Date(),
                noteType: notetype
            };
            let existingNote = this.notes.find(x => { return x.noteType === note.noteType; });
            if (existingNote) {
                existingNote = note;
            } else {
                this.notes.push(note);
            }
            this.onUpdateInstructionNotes.emit({ instructionDefinitionKey: this.instructionDefinitionKey, note });
            this.resetForm();
            this.saveCall = true;
            this.grid.search();
        } else {
            const rowKey = this.taskPlannerRowKey.split('^');
            eventNotes.caseEventId = Number(rowKey[1]);
            this.eventNoteDetailsService.maintainEventNotes(eventNotes)
                .subscribe(response => {
                    if (response.result === 'success' || response.result === 'partialsuccess') {
                        const createAdhoc = this.gridOptions.formGroup.value.createAdhoc === undefined
                            ? false : this.gridOptions.formGroup.value.createAdhoc;
                        this.resetForm();
                        this.saveCall = true;
                        response.result === 'partialsuccess' ? this.notificationService.info({
                            message: response.message,
                            continue: 'Ok',
                            title: this.translate.instant('modal.information')
                        }) : this.notificationService.success();
                        this.grid.search();
                        if (createAdhoc) {
                            this.launchAdhocDate();
                        }
                    }
                });
        }

    };

    launchAdhocDate = () => {
        const defaultAdhocInfo$ = this.eventNoteDetailsService
            .getDefaultAdhocInfo$(this.taskPlannerRowKey);
        const viewData$ = this.adHocDateService.viewData();

        forkJoin([viewData$, defaultAdhocInfo$])
            .subscribe(([viewData, defaultAdhocInfo]) => {
                const initialState = {
                    viewData,
                    defaultAdhocInfo,
                    fromEventNotes: true
                };
                this.modalService.openModal(AdHocDateComponent, {
                    backdrop: 'static',
                    class: 'modal-lg',
                    initialState
                });
            });
    };

    makeEventNoteText = (eventNotes: any): any => {
        let filterRecord: any;
        if (this.status === rowStatus.Adding) {
            filterRecord = this.eventTextItems.filter(x => x.notetype === (eventNotes.eventNoteType === undefined ? null : eventNotes.eventNoteType));
            eventNotes.eventText += '\r\n';
            if (!eventNotes.replaceNote) {
                eventNotes.eventText += this.arrangeEventNoteText(filterRecord);
            }
        }
        if (this.status === rowStatus.editing) {
            const updateRecord = _.first(this.eventTextItems.filter(x => x.rowId === this.currentRowIndex));
            updateRecord.noteText = eventNotes.eventText;
            eventNotes.eventNoteType = updateRecord.notetype;
            filterRecord = this.eventTextItems.filter(x => x.notetype === (eventNotes.eventNoteType === undefined ? null : eventNotes.eventNoteType));
            if (!eventNotes.replaceNote) {
                eventNotes.eventText = this.arrangeEventNoteText(filterRecord);
            }
        }
    };

    private readonly arrangeEventNoteText = (eventTextItems: Array<any>): string => {
        let result = '';
        if (eventTextItems.length > 0) {
            _.each(eventTextItems.filter(x => x.noteText !== null), (item => {
                if (item.noteText.endsWith('\n')) {
                    result += item.noteText;
                } else {
                    result += item.noteText + '\n';
                }
            }));
        }

        return result;
    };

    onChange = (item: any): void => {
        if (item !== null) {
            let text = this.gridOptions.formGroup.controls.eventNoteText.value;
            switch (this.siteControlId) {
                case 1: {
                    if (text.indexOf(this.promptText) !== -1) {
                        text = text.replace(this.promptText, item.value);
                    } else {
                        text += text.endsWith('\n') ? item.value : '\n' + item.value;
                    }
                    break;
                }
                case 2: {
                    if (text.indexOf(this.promptText) !== -1) {
                        text = text.replace(this.promptText, item.value);
                    } else {
                        text = text.replace('\n' + this.cursorText, '');
                        text += (text.endsWith('\n') || text === '') ? item.value : '\n' + item.value;
                        text += '\n' + this.cursorText;
                    }
                    break;
                }
                default: {
                    if (text === '') {
                        text = item.value;
                    } else {
                        text += '\n' + item.value;
                    }
                    break;
                }
            }
            this.gridOptions.formGroup.controls.eventNoteText.setValue(text);
            this.gridOptions.formGroup.controls.eventNoteText.markAsDirty();
            this.gridOptions.formGroup.updateValueAndValidity();
        }
    };

    get isFormDirty(): boolean {
        const isDirty = this.gridOptions.formGroup && this.gridOptions.formGroup.controls.eventNoteText.dirty && this.gridOptions.formGroup.controls.eventNoteText.valid ? true : false;
        this.onEventNoteChange.emit({
            isDirty,
            rowKey: this.taskPlannerRowKey + '^N'
        });

        return isDirty;
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const initialNoteTypeFilters = this.filteredCategories.filter(fc => fc.isDefault).map(c => String(c.code));
        const columns: Array<GridColumnDefinition> = [{
            title: 'caseview.actions.events.eventDetailType',
            field: 'notetype',
            filter: this.eventNoteFrom !== eventNoteEnum.provideInstructions,
            defaultFilters: initialNoteTypeFilters,
            width: this.eventNoteFrom === eventNoteEnum.taskPlanner ? 200 : 200,
            template: true,
            sortable: false
        },
        {
            title: 'caseview.actions.events.eventDetailNote',
            field: 'notes',
            template: true,
            sortable: false
        },
        {
            title: 'caseview.actions.events.eventNoteLastUpdatedDate',
            field: 'lastUpdatedDateTime',
            filter: false,
            type: 'date',
            width: this.eventNoteFrom === eventNoteEnum.taskPlanner ? 500 : 300,
            template: true,
            defaultColumnTemplate: DefaultColumnTemplateType.date,
            sortable: false
        }];

        if (this.eventNoteFrom === eventNoteEnum.taskPlanner) {
            columns[1].width = 300;
        }
        if (!this.hasNoteTypes) {
            columns.splice(1, 1);
        }

        return columns;
    };

    private readonly getEventitems = (notes: Array<any>, filteredCategories: Array<any>) => {
        const items = [];
        if (notes.length > 0) {
            notes.forEach((value) => {
                const noteTypeText = filteredCategories.filter(c => c.code === value.noteType);
                let noteitems = this.makeEventNotesBasedOnSiteControl(value.eventText);
                noteitems = noteitems.map((r) => ({
                    rowId: 0,
                    noteText: r,
                    notetype: value.noteType,
                    noteTypeDescription: noteTypeText.length === 0 ? null : noteTypeText[0].description,
                    noteLastUpdatedDate: value.lastUpdatedDateTime
                }));
                items.push(noteitems);
            });
        }
        const flattenItems = _.flatten(items);
        _.each(flattenItems, (item, index) => {
            item.rowId = index;
        });

        return this.showOnlyLatestDate(flattenItems);
    };

    private readonly showOnlyLatestDate = (items) => {
        let firstItem: 0;
        items.forEach((item) => {
            const index = items.indexOf(item);
            if (index !== 0 && item.notetype === items[firstItem].notetype) {
                if (new Date(item.noteLastUpdatedDate) > new Date(items[firstItem].noteLastUpdatedDate)) {
                    items[firstItem].noteLastUpdatedDate = item.noteLastUpdatedDate;
                    item.noteLastUpdatedDate = null;
                } else {
                    item.noteLastUpdatedDate = null;
                }
            } else {
                firstItem = items.indexOf(item);
            }
        });

        return items;
    };

    private readonly makeEventNotesBasedOnSiteControl = (eventNotesText: string) => {
        let eventNotes = [];
        if (this.siteControlId === 2) {
            const texts = eventNotesText.split('\n');
            if (texts[texts.length - 1] === '') {
                texts.pop();
            }
            eventNotes.push('');
            for (const text of texts) {
                if (text.startsWith('---')) {
                    eventNotes[eventNotes.length - 1] += text;
                    eventNotes.push('');
                } else {
                    eventNotes[eventNotes.length - 1] += text + '\n';
                }
            }
            if (eventNotes[eventNotes.length - 1] === '') {
                eventNotes.pop();
            }
        } else {
            eventNotes = eventNotesText.split(/(?=\n---)/g);
        }
        eventNotes.forEach(x => x.replace('\n---', '---'));

        return eventNotes;
    };

    private readonly getCategories = (noteTypes: Array<number>, categories: Array<any>) => {
        return categories.filter(c => c.code === '' || c.isDefault || noteTypes.indexOf(c.code) > -1);
    };

    get isFromProvideInstructions(): boolean {

        return this.eventNoteFrom === eventNoteEnum.provideInstructions;
    }
}