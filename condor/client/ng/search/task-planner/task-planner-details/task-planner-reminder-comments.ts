import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { map } from 'rxjs/operators';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { MaintainActions } from '../task-planner.data';

@Component({
    selector: 'ipx-task-reminder-comments',
    templateUrl: './task-planner-reminder-comments.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class TaskPlannerReminderCommentsComponent implements OnInit, AfterViewInit {
    @Input() taskPlannerRowKey: string;
    @Input() maintainReminderComments: boolean;
    @Input() expandAction: string;
    @ViewChild('remindersGrid', { static: true }) grid: IpxKendoGridComponent;
    @Output() readonly onReminderCommentUpdate: EventEmitter<any> = new EventEmitter<any>();
    @Output() readonly onReminderCommentChange: EventEmitter<any> = new EventEmitter<any>();
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('remindersGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
        }
    }

    gridOptions: IpxGridOptions;
    reminderFor: string;
    dateFormat: any;
    formGroup: FormGroup;
    currentRowIndex: number;
    saveCall = false;
    reminderCounts: number;
    lastUpdatedDate: any;

    constructor(private readonly taskPlannerService: TaskPlannerService,
        private readonly dateService: DateService, private readonly formBuilder: FormBuilder,
        private readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService, private readonly cdref: ChangeDetectorRef) { }
    ngAfterViewInit(): void {
        setTimeout(() => {
            if (this.gridOptions.canAdd && (this.expandAction && this.expandAction === MaintainActions.comments.toString())) {
                this._resultsGrid.addRow();
            } else if (!this.gridOptions.canAdd && (this.expandAction && this.expandAction === MaintainActions.comments.toString())) {
                this._resultsGrid.rowEditHandler(null, 0, this._resultsGrid.wrapper.data[0]);
            }
        }, 800);
    }

    ngOnInit(): void {
        this.dateFormat = this.dateService.dateFormat;
        this.gridOptions = this.buildGridOptions();
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            sortable: false,
            showGridMessagesUsingInlineAlert: false,
            navigable: true,
            pageable: false,
            gridMessages: { noResultsFound: 'taskPlanner.reminderComments.noRecordMsg' },
            selectable: {
                mode: 'single'
            },
            canAdd: this.maintainReminderComments,
            enableGridAdd: this.maintainReminderComments,
            itemName: 'taskPlanner.reminderComments.itemReminderComment',
            onDataBound: (boundData: any) => {
                _.each(boundData, (comment: any) => {
                    comment.showEditAttributes = comment.isRecipientComment ? { display: true } : { display: false };
                });
                this.taskPlannerService.reminderDetailCount$.next({
                    taskPlannerRowKey: this.taskPlannerRowKey,
                    count: boundData.length
                });
                this.reminderCounts = boundData.length;
            },
            read$: () => {
                return this.taskPlannerService
                    .reminderComments(this.taskPlannerRowKey)
                    .pipe(map((response: any) => {
                        this.reminderFor = response.reminderForDisplayName;
                        if (response.comments.length) {
                            this.gridOptions.canAdd = !_.any(response.comments, (comment: any) => {
                                return _.isEqual(comment.isRecipientComment, true);
                            }) && this.maintainReminderComments;
                        } else {
                            this.gridOptions.canAdd = this.maintainReminderComments;
                        }
                        if (this.gridOptions.canAdd) {
                            this.gridOptions.enableGridAdd = this.maintainReminderComments;
                        }
                        if (this.maintainReminderComments && this.saveCall) {
                            this.onReminderCommentUpdate.emit({
                                lastUpdatedDate: this.lastUpdatedDate,
                                taskPlannerRowKey: this.taskPlannerRowKey
                            });
                        }
                        this.saveCall = false;

                        return response.comments;
                    }));
            },
            columns: [{
                field: 'staffDisplayName', title: 'taskPlanner.reminderComments.titleCommentsOf', width: 210, sortable: false
            }, {
                field: 'comments', title: 'taskPlanner.reminderComments.titleReminderComments', width: 300, sortable: false, template: true
            }, {
                field: 'logDateTimeStamp', title: 'taskPlanner.reminderComments.titleLastUpdatedDate', width: 500, sortable: false, template: true
            }]
        };
        Object.assign(options, {
            rowMaintenance: {
                canEdit: this.maintainReminderComments,
                inline: this.maintainReminderComments,
                rowEditKeyField: 'staffNameKey',
                width: 20
            },

            // tslint:disable-next-line: unnecessary-bind
            createFormGroup: this.createFormGroup.bind(this)
        });

        return options;
    }

    createFormGroup = (dataItem: any): FormGroup => {
        const formGroup = this.formBuilder.group({
            staffNameKey: dataItem.staffNameKey,
            comments: new FormControl()
        });

        formGroup.controls.comments.setValue((!dataItem || !dataItem.comments) ? null : dataItem.comments);
        formGroup.markAsPristine();

        this.gridOptions.formGroup = formGroup;

        if (dataItem.status === 'A') {
            this.gridOptions.enableGridAdd = false;
            dataItem.staffDisplayName = this.reminderFor;
            dataItem.showEditAttributes = { display: false };
        }
        if (dataItem.status === rowStatus.Adding || dataItem.status === rowStatus.editing) {
            dataItem.showRevertAttributes = { display: false };
        }

        return formGroup;
    };

    onReset = (): void => {
        this.gridOptions.formGroup.controls.comments.setValue(null);
        this.taskPlannerService.isCommentDirty$.next({
            rowKey: this.taskPlannerRowKey,
            dirty: false
        });
        this.gridOptions.formGroup.markAsPristine();
    };

    onSave = (): void => {
        if (!this.gridOptions.formGroup.valid) {
            return;
        }

        const reminderComments = {
            taskPlannerRowKey: this.taskPlannerRowKey,
            comments: this.gridOptions.formGroup.value.comments === '' ? null : this.gridOptions.formGroup.value.comments
        };

        this.taskPlannerService.saveReminderComment(reminderComments)
            .subscribe(response => {
                if (response.result === 'success') {
                    this.notificationService.success();
                    this.resetForm();
                    this.saveCall = true;
                    this.lastUpdatedDate = null;
                    if (reminderComments.comments !== null) {
                        this.lastUpdatedDate = new Date();
                    }
                    this.grid.search();
                }
            });
    };

    get isFormDirty(): boolean {
        const isDirty = this.gridOptions.formGroup && this.gridOptions.formGroup.controls.comments.dirty ? true : false;
        this.onReminderCommentChange.emit({
            isDirty,
            rowKey: this.taskPlannerRowKey + '^C'
        });

        return isDirty;
    }

    commentOnChange(e): void {
        this.taskPlannerService.isCommentDirty$.next({
            rowKey: this.taskPlannerRowKey,
            dirty: true
        });
    }

    rowDiscard(): void {
        if (!this.gridOptions.formGroup.dirty) {
            this.gridOptions.enableGridAdd = this.maintainReminderComments;
            this.resetForm();
            this.grid.search();
        } else {
            const commentNotificationModalRef = this.ipxNotificationService.openDiscardModal();
            commentNotificationModalRef.content.confirmed$.subscribe(() => {
                this.gridOptions.enableGridAdd = this.maintainReminderComments;
                this.resetForm();
                this.grid.search();
                commentNotificationModalRef.hide();
            });
        }
    }

    getRowIndex = (event): void => {
        this.currentRowIndex = event;
    };

    resetForm(): void {
        this.taskPlannerService.isCommentDirty$.next({
            rowKey: this.taskPlannerRowKey,
            dirty: false
        });
        this.grid.rowEditFormGroups = null;
        this.gridOptions.formGroup = undefined;
        this.grid.currentEditRowIdx = this.currentRowIndex;
        this.grid.closeRow();
        this.cdref.markForCheck();
    }
}