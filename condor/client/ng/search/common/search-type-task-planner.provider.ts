import { Injectable } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { ReminderActionProvider } from 'search/task-planner/reminder-action.provider';
import { TaskPlannerSearchHelperService } from 'search/task-planner/task-planner-search-result/task-planner-search.helper.service';
import { ReminderActionStatus, ReminderRequestType } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { queryContextKeyEnum } from './search-type-config.provider';

@Injectable()
export class SearchTypeTaskPlannerProvider {

    viewData: any;
    queryContextKey: number;

    constructor(
        private readonly notificationService: NotificationService,
        private readonly taskPlannerService: TaskPlannerService,
        private readonly reminderActionProvider: ReminderActionProvider,
        private readonly searchHelperService: TaskPlannerSearchHelperService
    ) {
    }

    getConfigurationActionMenuItems = (queryContextKey: number, viewData: any): Array<IpxBulkActionOptions> => {
        const menuItems = [];
        this.viewData = viewData;
        this.viewData.queryContextKey = queryContextKey;

        switch (queryContextKey) {
            case queryContextKeyEnum.taskPlannerSearch:
                if (this.viewData.reminderDeleteButton === 0 || this.viewData.reminderDeleteButton === 2) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'dismiss-reminders',
                        icon: 'cpa-icon cpa-icon-bell-slash',
                        text: 'taskPlannerBulkActionMenu.dismissReminders',
                        enabled: false,
                        click: this.dismissRemindersEvent
                    });
                }
                menuItems.push({
                    ...new IpxBulkActionOptions(),
                    id: 'defer-reminders',
                    icon: 'cpa-icon cpa-icon-bell-semicircle-inline',
                    text: 'taskPlannerBulkActionMenu.deferReminders',
                    enabled: false,
                    items: [
                        {
                            ...new IpxBulkActionOptions(),
                            id: 'defer-to-entered-date',
                            text: 'taskPlannerBulkActionMenu.toEnteredDate',
                            enabled: true,
                            click: this.deferToEnteredDate
                        }, {
                            ...new IpxBulkActionOptions(),
                            id: 'defer-to-next-calculated-date',
                            text: 'taskPlannerBulkActionMenu.toNextCalculatedDate',
                            enabled: true,
                            click: this.deferToNextCalculatedDate
                        }
                    ]
                });
                menuItems.push({
                    ...new IpxBulkActionOptions(),
                    id: 'mark-as-read-unread',
                    icon: 'cpa-icon cpa-icon-check',
                    text: 'taskPlannerBulkActionMenu.markRemindersAs',
                    enabled: false,
                    items: [
                        {
                            ...new IpxBulkActionOptions(),
                            id: 'mark-as-read',
                            text: 'taskPlannerBulkActionMenu.read',
                            enabled: true,
                            click: this.markAsRead
                        }, {
                            ...new IpxBulkActionOptions(),
                            id: 'mark-as-unread',
                            text: 'taskPlannerBulkActionMenu.unread',
                            enabled: true,
                            click: this.markAsUnread
                        }
                    ]
                });
                if (this.viewData.canFinaliseAdhocDate) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'finalise',
                        text: 'taskPlannerTaskMenu.finaliseAdHocDates',
                        icon: 'cpa-icon cpa-icon-bell-check-o',
                        enabled: false,
                        click: this.finaliseAdhoc
                    });
                }

                if (this.viewData.canChangeDueDateResponsibility) {
                    menuItems.push({
                        ...new IpxBulkActionOptions(),
                        id: 'change-due-date-responsibility',
                        icon: 'cpa-icon cpa-icon-calendar-semicircle',
                        text: 'taskPlannerBulkActionMenu.changeDueDateResponsibility',
                        enabled: false,
                        click: this.changeDueDateResponsibility
                    });
                }

                menuItems.push({
                    ...new IpxBulkActionOptions(),
                    id: 'forward-reminders',
                    icon: 'cpa-icon cpa-icon-bell-semicircle',
                    text: 'taskPlannerBulkActionMenu.forwardReminders',
                    enabled: false,
                    click: this.forwardReminders
                });

                break;
            default:
                break;
        }

        return menuItems;
    };

    private readonly dismissRemindersEvent = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.dismissReminders);
    };

    private readonly deferToEnteredDate = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.deferToEnteredDate);
    };

    private readonly changeDueDateResponsibility = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.changeDueDateResponsibility);
    };

    private readonly finaliseAdhoc = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.finalise, {
            resolveReasons: this.viewData.resolveReasons
        });
    };

    private readonly forwardReminders = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.forwardReminders);
    };

    private readonly deferToNextCalculatedDate = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.deferToNextCalculatedDate);
    };

    private readonly markAsRead = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.markAsRead);
    };

    private readonly markAsUnread = (resultGrid: IpxKendoGridComponent) => {
        this.handleTaskPlannerActionMenuEvent(resultGrid, TaskPlannerOperationType.markAsUnread);
    };

    private readonly handleTaskPlannerActionMenuEvent = (resultGrid: IpxKendoGridComponent, type: string, viewData?: any) => {

        let searchRequestParams = null;
        let selectedRowKeys = null;
        if (resultGrid.getRowSelectionParams().isAllPageSelect) {
            const deSelectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allDeSelectedItems, 'rowKey');
            searchRequestParams = this.searchHelperService.getSearchRequestParams(deSelectedRowKeys);
        } else if (_.any(resultGrid.getRowSelectionParams().allSelectedItems)) {
            selectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allSelectedItems, 'taskPlannerRowKey');
        }
        this.manageTaskPlannerBulkOperation(type, selectedRowKeys, searchRequestParams, viewData);
    };

    private readonly manageTaskPlannerBulkOperation = (type: string, selectedTaskPlannerRowKeys: Array<string>, searchRequestParams: any, viewData?: any) => {
        switch (type) {
            case TaskPlannerOperationType.dismissReminders:
                this.reminderActionProvider.dismissReminders(selectedTaskPlannerRowKeys, searchRequestParams, ReminderRequestType.BulkAction);
                break;
            case TaskPlannerOperationType.deferToEnteredDate:
                this.reminderActionProvider.deferRemindersToEnteredDate(ReminderRequestType.BulkAction, selectedTaskPlannerRowKeys, searchRequestParams);
                break;
            case TaskPlannerOperationType.deferToNextCalculatedDate:
                this.reminderActionProvider.deferReminders(ReminderRequestType.BulkAction, selectedTaskPlannerRowKeys, null, searchRequestParams);
                break;
            case TaskPlannerOperationType.markAsRead:
                this.reminderActionProvider.markAsReadOrUnread(selectedTaskPlannerRowKeys, true, searchRequestParams);
                break;
            case TaskPlannerOperationType.markAsUnread:
                this.reminderActionProvider.markAsReadOrUnread(selectedTaskPlannerRowKeys, false, searchRequestParams);
                break;
            case TaskPlannerOperationType.changeDueDateResponsibility:
                this.reminderActionProvider.changeDueDateResponsibility(selectedTaskPlannerRowKeys, searchRequestParams, ReminderRequestType.BulkAction);
                break;
            case TaskPlannerOperationType.forwardReminders:
                this.reminderActionProvider.forwardReminders(selectedTaskPlannerRowKeys, ReminderRequestType.BulkAction, searchRequestParams);
                break;
            case TaskPlannerOperationType.finalise:
                this.reminderActionProvider.bulkFinalise(selectedTaskPlannerRowKeys, searchRequestParams, viewData);
                break;
            default:
                break;
        }
    };
}

enum TaskPlannerOperationType {
    dismissReminders = 'dismiss-reminders',
    deferToEnteredDate = 'defer-to-entered-date',
    changeDueDateResponsibility = 'changed-due-date-responsibility',
    deferToNextCalculatedDate = 'defer-to-next-calculated-date',
    forwardReminders = 'forward-reminders',
    markAsRead = 'mark-as-read',
    markAsUnread = 'mark-as-unread',
    finalise = 'finalise'
}