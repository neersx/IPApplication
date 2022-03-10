import { AfterViewInit, ChangeDetectionStrategy, Component, EventEmitter, Input, OnDestroy, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, forkJoin, of, Subscription } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { eventNoteEnum, EventNoteViewData } from '../../../portfolio/event-note-details/event-notes.model';
import { MaintainActions } from '../task-planner.data';
import { TaskPlannerService } from '../task-planner.service';

@Component({
    selector: 'ipx-task-detail',
    templateUrl: './task-planner-detail.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class TaskPlannerDetailComponent implements OnInit, AfterViewInit, OnDestroy {
    @Input() taskPlannerRowKey: string;
    @Input() showEventNotes: boolean;
    @Input() showReminderComments: boolean;
    @Input() maintainReminderComments: boolean;
    @Input() replaceEventNotes: boolean;
    @Input() maintainEventNotes: boolean;
    @Input() maintainEventNotesPermissions: any;
    @Input() expandAction: string;
    @Output() readonly onEventNoteUpdate: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onReminderCommentUpdate: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onTaskDetailChange: EventEmitter<any> = new EventEmitter<any>();
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild('detailsTemplate', { static: true }) detailsTemplate: TemplateRef<any>;
    gridOptions: IpxGridOptions;
    eventNoteEnum = eventNoteEnum;
    eventNoteTypes: any;
    eventNotes: any;
    eventNotesLoaded = false;
    taskPlannerDetails: Array<any> = [];
    constructor(private readonly localSettings: LocalSettings, private readonly taskPlannerService: TaskPlannerService,
        private readonly ipxNotificationService: IpxNotificationService, private readonly bsModalRef: BsModalRef) { }
    strEventNotes = 'Event Notes';
    strReminderComments = 'Reminder Comments';
    reminderDetailCountSubscription: Subscription;
    eventNoteDetailCountSubscription: Subscription;
    setRemindersCountSubject: BehaviorSubject<any> = new BehaviorSubject<any>(null);
    setEventNotesCountSubject: BehaviorSubject<any> = new BehaviorSubject<any>(null);
    notifyCommentChange = false;
    modalRef: BsModalRef;
    clickcheck = false;
    remindersCount = 0;
    notesCount = 0;
    siteControlId: number;
    noteTypeExist: boolean;
    eventNoteResult = new BehaviorSubject<any>([]);
    eventNoteResult$ = this.eventNoteResult.asObservable();

    ngOnInit(): void {
        this.setRemindersCountSubject.subscribe(e => {
            if (e && e.taskPlannerRowKey === this.taskPlannerRowKey) {
                this.remindersCount = e.remindersCount;
                if (this.remindersCount > 0 && this.expandAction === MaintainActions.notesAndComments.toString()) {
                    this.showEventNotes ? this.grid.wrapper.expandRow(1) : this.grid.wrapper.expandRow(0);
                }
            }
        });
        this.setEventNotesCountSubject.subscribe(e => {
            if (e && e.taskPlannerRowKey === this.taskPlannerRowKey) {
                this.notesCount = e.notesCount;
                if (this.notesCount > 0 && this.showEventNotes && this.expandAction === MaintainActions.notesAndComments.toString()) {
                    this.grid.wrapper.expandRow(0);
                }
            }
        });
        if (this.showReminderComments) {
            this.taskPlannerService.reminderCommentsCount(this.taskPlannerRowKey)
                .subscribe((count) => {
                    this.setRemindersCountSubject.next({
                        taskPlannerRowKey: this.taskPlannerRowKey,
                        remindersCount: count
                    });
                });
        }
        this.gridOptions = this.buildGridOptions();

        if (this.showEventNotes) {
            this.taskPlannerDetails.push({ detail: this.strEventNotes });
            if (!!this.taskPlannerRowKey) {
                const eventNoteTypelst = this.taskPlannerService.getEventNoteTypes$();
                const noteDetails = this.taskPlannerService.getEventNotesDetails$(this.taskPlannerRowKey);
                const existNote = this.taskPlannerService.isPredefinedNoteTypeExist();
                const siteControl = this.taskPlannerService.siteControlId();
                forkJoin([eventNoteTypelst, noteDetails, existNote, siteControl])
                    .subscribe(([eventNoteResponse, noteDetail, noteTypeExist, siteControlId]) => {
                        this.eventNoteTypes = eventNoteResponse;
                        this.eventNotes = noteDetail;
                        this.siteControlId = siteControlId;
                        this.noteTypeExist = noteTypeExist;
                        const filteredCategories = this.eventNotes ? this.getCategories(this.eventNotes.map(n => n.noteType), this.eventNoteTypes) : null;
                        const eventTextItems = this.getEventitems(this.eventNotes, filteredCategories);
                        this.setEventNotesCountSubject.next({
                            taskPlannerRowKey: this.taskPlannerRowKey,
                            notesCount: eventTextItems.length
                        });
                        this.eventNoteResult.next({
                            taskPlannerRowKey: this.taskPlannerRowKey,
                            eventNotesLoaded: true
                        });
                    });
            }
        }

        if (this.showReminderComments) {
            this.taskPlannerDetails.push({ detail: this.strReminderComments });
        }

        this.taskPlannerService.isCommentDirty$.subscribe(e => {
            if (e && e.rowKey === this.taskPlannerRowKey) {
                this.notifyCommentChange = e.dirty;
            }
        });
    }

    handelOnEventNoteUpdate = (event: any) => {
        this.onEventNoteUpdate.emit(event);
    };

    handleOnNoteOrCommentChange = (event: any) => {
        this.onTaskDetailChange.emit(event);
    };

    handelOnReminderCommentUpdate = (event: any) => {
        this.onReminderCommentUpdate.emit(event);
    };

    private readonly getEventitems = (notes: Array<any>, filteredCategories: Array<any>) => {
        let items = [];
        if (notes.length > 0) {
            notes.forEach((value) => {
                const noteTypeText = filteredCategories.filter(c => c.code === value.noteType);

                items = items.concat(value.eventText.split(/(?=\n---)/g).map(r => ({
                    noteText: r.replace(/\n---/g, '---'),
                    notetype: value.noteType,
                    noteTypeDescription: noteTypeText.length === 0 ? null : noteTypeText[0].description,
                    noteLastUpdatedDate: value.lastUpdatedDateTime
                })));
            });
        }

        return items;
    };

    private readonly getCategories = (noteTypes: Array<number>, categories: Array<any>) => {
        return categories.filter(c => c.code === '' || c.isDefault || noteTypes.indexOf(c.code) > -1);
    };

    ngAfterViewInit(): void {
        this.subscribeToDetailCount();
        let shouldExpandEventNotes = this.localSettings.keys.taskPlanner.showEventNotes.getSession;
        let shouldExpandReminderComments = this.localSettings.keys.taskPlanner.showReminderComments.getSession;
        if (this.expandAction) {
            if (this.expandAction === MaintainActions.notes.toString()) {
                shouldExpandEventNotes = true;
                shouldExpandReminderComments = false;
            } else if (this.expandAction === MaintainActions.comments.toString()) {
                shouldExpandEventNotes = false;
                shouldExpandReminderComments = true;
            }
        }
        if (this.expandAction !== MaintainActions.notesAndComments.toString()) {
            shouldExpandEventNotes && this.showEventNotes ? this.grid.wrapper.expandRow(0) : this.grid.wrapper.collapseRow(0);
            this.showEventNotes ? (shouldExpandReminderComments ? this.grid.wrapper.expandRow(1) : this.grid.wrapper.collapseRow(1)) : (shouldExpandReminderComments ? this.grid.wrapper.expandRow(0) : this.grid.wrapper.collapseRow(0));
        }
    }

    subscribeToDetailCount = () => {
        this.reminderDetailCountSubscription = this.taskPlannerService.reminderDetailCount$
            .subscribe((e) => {
                if (e != null && e.taskPlannerRowKey === this.taskPlannerRowKey) {
                    this.setRemindersCountSubject.next({
                        taskPlannerRowKey: this.taskPlannerRowKey,
                        remindersCount: e.count
                    });
                }
            });

        this.eventNoteDetailCountSubscription = this.taskPlannerService.eventNoteDetailCount$
            .subscribe((e) => {
                if (e != null && e.taskPlannerRowKey === this.taskPlannerRowKey) {
                    this.setEventNotesCountSubject.next({
                        taskPlannerRowKey: this.taskPlannerRowKey,
                        notesCount: e.count
                    });
                }
            });
    };

    setNotesCount = (event): void => {
        this.taskPlannerService.eventNoteDetailCount$.next({
            taskPlannerRowKey: this.taskPlannerRowKey,
            count: event
        });
    };

    ngOnDestroy(): void {
        if (this.reminderDetailCountSubscription) {
            this.reminderDetailCountSubscription.unsubscribe();
        }
        if (this.eventNoteDetailCountSubscription) {
            this.eventNoteDetailCountSubscription.unsubscribe();
        }
    }

    onExpand(event: any): void {
        if (event.dataItem.detail === this.strEventNotes) {
            this.localSettings.keys.taskPlanner
                .showEventNotes.setSession(true);
        }
        if (event.dataItem.detail === this.strReminderComments) {
            this.localSettings.keys.taskPlanner
                .showReminderComments.setSession(true);
        }
        this.expandAction = null;
    }

    onCollapse(event: any): void {
        if (this.clickcheck) {
            this.clickcheck = false;

            return;
        }
        if (this.notifyCommentChange && event.dataItem.detail === this.strReminderComments) {
            event.prevented = true;
            this.modalRef = this.ipxNotificationService.openDiscardModal();
            this.modalRef.content.confirmed$.subscribe(() => {
                this.setDetails(event);
                const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
                if (collapseElement) {
                    this.clickcheck = true;
                    collapseElement.click();
                    this.taskPlannerService.isCommentDirty$.next({
                        rowKey: this.taskPlannerRowKey,
                        dirty: false
                    });
                }
                this.bsModalRef.hide();
            });
        } else {
            this.setDetails(event);
        }
        this.expandAction = null;
    }

    setDetails(event: any): void {
        if (event.dataItem.detail === this.strEventNotes) {
            this.localSettings.keys.taskPlanner
                .showEventNotes.setSession(false);
        }
        if (event.dataItem.detail === this.strReminderComments) {
            this.localSettings.keys.taskPlanner
                .showReminderComments.setSession(false);
        }
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            groups: [],
            hideHeader: true,
            selectable: {
                mode: 'single'
            },
            read$: () => of(this.taskPlannerDetails).pipe(delay(100)),
            columns: [{
                field: 'detail', title: '', template: true
            }]
        };

        options.detailTemplateShowCondition = (dataItem: any): boolean => true;
        options.detailTemplate = this.detailsTemplate;

        return options;
    }
}