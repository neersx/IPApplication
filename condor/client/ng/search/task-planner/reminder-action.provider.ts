import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { CommonUtilityService } from 'core/common.utility.service';
import { WindowRef } from 'core/window-ref';
import { AdhocDateService } from 'dates/adhoc-date.service';
import { FinaliseAdHocDateComponent } from 'dates/finalise-adhoc-date.component';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import * as _ from 'underscore';
import { DeferReminderToDateModalComponent } from './defer-reminder-date-modal/defer-reminder-to-date-modal.component';
import { DueDateResponsibilityModalComponent } from './due-date-responsibility-modal/due-date-responsibility-modal.component';
import { ForwardReminderModalComponent } from './forward-reminder-modal/forward-reminder-modal.component';
import { ProvideInstructionsModalComponent } from './provide-instructions-modal/provide-instructions-modal.component';
import { ProvideInstructionsService } from './provide-instructions-modal/provide-instructions.service';
import { SendEmailModalComponent } from './send-email-modal/send-email-modal.component';
import { ReminderActionStatus, ReminderRequestType, TaskPlannerViewData } from './task-planner.data';

@Injectable()
export class ReminderActionProvider {

    modalRef: BsModalRef;
    loading = false;
    constructor(
        private readonly notificationService: NotificationService,
        private readonly taskPlannerService: TaskPlannerService,
        private readonly modalService: IpxModalService,
        private readonly dateHelper: DateHelper,
        private readonly commonService: CommonUtilityService,
        private readonly translate: TranslateService,
        private readonly localDate: LocaleDatePipe,
        private readonly adhocDatesService: AdhocDateService,
        private readonly windoeRef: WindowRef,
        private readonly provideInstructionsService: ProvideInstructionsService
    ) {
    }

    changeDueDateResponsibility = (selectedRowKeys: Array<string>, searchRequestParams, requestType: ReminderRequestType): void => {
        if (requestType === ReminderRequestType.BulkAction) {
            this.openDueDateResponsibilityModal(selectedRowKeys, searchRequestParams, null, requestType);
        } else {
            this.taskPlannerService.getDueDateResponsibility(selectedRowKeys[0]).subscribe((name) => {
                this.loading = false;
                this.openDueDateResponsibilityModal(selectedRowKeys, searchRequestParams, name, requestType);
            });
        }
    };

    provideInstructions = (selectedRowKey: string, viewData: TaskPlannerViewData): void => {
        this.loading = true;
        this.provideInstructionsService.getProvideInstructions(selectedRowKey).subscribe((provideInstructions) => {
            this.loading = false;
            this.openProvideInstructionsModal(selectedRowKey, viewData, provideInstructions);
        });
    };

    private readonly openProvideInstructionsModal = (selectedRowKey: any, viewData: TaskPlannerViewData, provideInstructions: any): void => {
        this.modalRef = this.modalService.openModal(ProvideInstructionsModalComponent, {
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                viewData: provideInstructions,
                taskPlannerRowKey: selectedRowKey,
                resultPageViewData: viewData
            }
        });

        this.modalRef.content.proceedClicked.subscribe((data: any) => {
            if (data) {
                this.loading = true;
                this.provideInstructionsService.save({ provideInstruction: data, taskPlannerRowKey: selectedRowKey }).subscribe(response => {
                    this.loading = false;
                    this.notificationService.success();
                    this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, unprocessedRowKeys: [] });
                });
            }
        });
    };

    private readonly openDueDateResponsibilityModal = (selectedRowKeys: Array<string>, searchRequestParams, name: any, requestType: ReminderRequestType): void => {
        this.modalRef = this.modalService.openModal(DueDateResponsibilityModalComponent, {
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                name,
                requestType
            }
        });

        this.modalRef.content.saveClicked.subscribe((responsibleName: any) => {
            this.saveDueDateResponsibility(selectedRowKeys, responsibleName, searchRequestParams);
        });
    };

    forwardReminders = (selectedRowKeys: Array<string>, requestType: ReminderRequestType, searchRequestParams: any): void => {

        this.modalRef = this.modalService.openModal(ForwardReminderModalComponent, {
            backdrop: 'static',
            class: 'modal-lg'
        });

        this.modalRef.content.saveClicked.subscribe((names: Array<any>) => {
            if (names) {
                const nameIds = _.pluck(names, 'key');
                this.applyForwardReminders(selectedRowKeys, nameIds, requestType, searchRequestParams);
            }
        });
    };

    sendEmails = (selectedRowKeys: Array<string>, searchRequestParams: any): void => {
        this.modalRef = this.modalService.openModal(SendEmailModalComponent, {
            backdrop: 'static',
            class: 'modal-lg'
        });

        this.modalRef.content.sendClicked.subscribe((emails: Array<string>) => {
            this.sendEmailsToNames(emails, selectedRowKeys, searchRequestParams);
        });
    };

    deferRemindersToEnteredDate = (requestType: ReminderRequestType, selectedRowKeys: Array<string>, searchRequestParams: any): void => {

        this.modalRef = this.modalService.openModal(DeferReminderToDateModalComponent, {
            backdrop: 'static',
            class: 'modal-md'
        });

        this.modalRef.content.deferClicked.subscribe((enteredDate: Date) => {
            if (enteredDate) {
                this.deferReminders(requestType, selectedRowKeys, this.dateHelper.toLocal(enteredDate), searchRequestParams);
            }
        });
    };

    deferReminders = (requestType: ReminderRequestType, taskPlannerRowKeys: Array<string>, holdUntilDate: Date, searchRequestParams: any): void => {
        this.loading = true;
        this.taskPlannerService.deferReminders(requestType, taskPlannerRowKeys, holdUntilDate, searchRequestParams).subscribe((response) => {
            this.loading = false;
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status !== ReminderActionStatus.UnableToComplete, unprocessedRowKeys: response.unprocessedRowKeys });

            if (response.status === ReminderActionStatus.Success) {
                this.notificationService.success(response.message);
            } else {
                const message = holdUntilDate ?
                    this.commonService.formatString(this.translate.instant(response.message), this.localDate.transform(holdUntilDate, null))
                    : response.message;
                this.notificationService.alert({ title: response.status === ReminderActionStatus.PartialCompletion ? 'modal.partialComplete' : 'modal.unableToComplete', message, continue: 'Ok' });
            }
        });
    };

    dismissReminders = (selectedTaskPlannerRowKeys: Array<string>, searchRequestParams: any, requestType: ReminderRequestType) => {
        if ((!selectedTaskPlannerRowKeys || selectedTaskPlannerRowKeys.length === 0) && !searchRequestParams) {
            return;
        }
        this.loading = true;
        this.taskPlannerService.dismissReminders(selectedTaskPlannerRowKeys, searchRequestParams, requestType).subscribe((response) => {
            this.loading = false;
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status !== ReminderActionStatus.UnableToComplete, unprocessedRowKeys: response.unprocessedRowKeys });
            if (response.status === ReminderActionStatus.Success) {
                this.notificationService.success(response.message);
            } else {
                this.notificationService.alert({ message: response.message, continue: 'Ok', title: response.messageTitle });
            }
        });
    };

    markAsReadOrUnread = (selectedTaskPlannerRowKeys: Array<string>, isRead: boolean, searchRequestParams: any) => {
        if ((!selectedTaskPlannerRowKeys || selectedTaskPlannerRowKeys.length === 0) && !searchRequestParams) {
            return;
        }
        this.loading = true;
        this.taskPlannerService.markAsReadOrUnread(selectedTaskPlannerRowKeys, isRead, searchRequestParams).subscribe((response) => {
            this.loading = false;
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: true, supressAutoRefreshCheck: true });
        });
    };

    private readonly saveDueDateResponsibility = (taskPlannerRowKeys: Array<string>, toName: any, searchRequestParams: any): void => {
        this.loading = true;
        this.taskPlannerService.changeDueDateResponsibility(taskPlannerRowKeys, toName ? toName.key : null, searchRequestParams).subscribe((response) => {
            this.loading = false;
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status !== ReminderActionStatus.UnableToComplete, unprocessedRowKeys: response.unprocessedRowKeys });

            if (response.status === ReminderActionStatus.Success) {
                this.notificationService.success('taskPlannerBulkActionMenu.changeDueDateSuccess');
            } else {
                const message = response.status === ReminderActionStatus.PartialCompletion ? 'taskPlannerBulkActionMenu.changeDueDatePartialCompletion' : 'taskPlannerBulkActionMenu.changeDueDateUnableToComplete';
                this.notificationService.alert(
                    {
                        title: response.status === ReminderActionStatus.PartialCompletion ? 'modal.partialComplete' : 'modal.unableToComplete',
                        message,
                        continue: 'Ok'
                    });
            }
        });
    };

    private readonly applyForwardReminders = (taskPlannerRowKeys: Array<string>, toNames: Array<number>, requestType: ReminderRequestType, searchRequestParams: any): void => {
        this.loading = true;
        this.taskPlannerService.forwardReminders(taskPlannerRowKeys, toNames, searchRequestParams).subscribe((response) => {
            this.loading = false;
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status !== ReminderActionStatus.UnableToComplete, unprocessedRowKeys: response.unprocessedRowKeys });

            if (response.status === ReminderActionStatus.Success) {
                this.notificationService.success(requestType === ReminderRequestType.BulkAction ? 'taskPlannerBulkActionMenu.forwardReminderSuccess' : 'taskPlannerTaskMenu.forwardReminderSuccess');
            } else {
                const message = response.status === ReminderActionStatus.PartialCompletion ? 'taskPlannerBulkActionMenu.forwardReminderPartialCompletion' : 'taskPlannerBulkActionMenu.forwardReminderUnableToComplete';
                this.notificationService.alert(
                    {
                        title: response.status === ReminderActionStatus.PartialCompletion ? 'modal.partialComplete' : 'modal.unableToComplete',
                        message,
                        continue: 'Ok'
                    });
            }
        });
    };

    private readonly sendEmailsToNames = (emails: Array<string>, taskPlannerRowKeys: Array<string>, searchRequestParams: any): void => {
        if (!emails) {
            return;
        }

        const emailCsv = 'mailto:' + emails.join(';');
        this.taskPlannerService.getEmailContent(taskPlannerRowKeys, searchRequestParams).subscribe(response => {

            response.forEach((content) => {
                let emailUrl = emailCsv;
                emailUrl = emailUrl + '?subject=' + encodeURIComponent(content.subject);
                emailUrl = emailUrl + '&body=' + encodeURIComponent(content.body);
                this.windoeRef.nativeWindow.open(emailUrl, '_blank');
            });
            if (this.modalRef) {
                this.modalRef.hide();
                this.taskPlannerService.onActionComplete$.next({ reloadGrid: true });
            }
        });
    };

    bulkFinalise = (selectedTaskPlannerRowKeys: Array<string>, searchRequestParams: any, viewData?: any) => {
        if (!_.any(selectedTaskPlannerRowKeys) && !searchRequestParams) {
            return;
        }

        const initialState = {
            finaliseData: {
                selectedTaskPlannerRowKeys,
                searchRequestParams,
                resolveReasons: viewData.resolveReasons,
                isBulkUpdate: true
            }
        };
        this.modalRef = this.modalService.openModal(FinaliseAdHocDateComponent, {
            backdrop: 'static',
            class: 'modal-md',
            initialState
        });
        this.modalRef.content.finaliseClicked.subscribe((response: any) => {
            this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status !== ReminderActionStatus.UnableToComplete, unprocessedRowKeys: response.unprocessedRowKeys });
            if (response.status === ReminderActionStatus.Success) {
                this.notificationService.success('taskPlanner.finaliseAdHocDate.successMessage');
            } else {
                const title = response.status === ReminderActionStatus.PartialCompletion ? 'modal.partialComplete' : 'modal.unableToComplete';
                const message = response.status === ReminderActionStatus.PartialCompletion ? 'taskPlanner.finaliseAdHocDate.partialCompleteMessage' : 'taskPlanner.finaliseAdHocDate.unableToCompleteMessage';
                this.notificationService.alert({ message, continue: 'Ok', title });
            }
        });
    };

    finalise = (taskPlannerRowKey: any, viewData: any): void => {
        const keys = taskPlannerRowKey.split('^');
        const alertId = +keys[1];

        this.adhocDatesService.adhocDate(alertId).subscribe(resultData => {
            const initialState = {
                finaliseData: {
                    adHocDateFor: resultData.adHocDateFor,
                    finaliseReference: resultData.finaliseReference,
                    message: resultData.message,
                    dueDate: resultData.dueDate,
                    dateOccurred: resultData.dateOccurred,
                    resolveReasons: viewData.resolveReasons,
                    resolveReason: resultData.resolveReason,
                    alertId,
                    isBulkUpdate: false,
                    taskPlannerRowKey
                }
            };
            this.modalRef = this.modalService.openModal(FinaliseAdHocDateComponent, {
                backdrop: 'static',
                class: 'modal-md',
                initialState
            });
            this.modalRef.content.finaliseClicked.subscribe((response: any) => {
                this.taskPlannerService.onActionComplete$.next({ reloadGrid: response.status === ReminderActionStatus.Success, unprocessedRowKeys: [] });
                if (response.status === ReminderActionStatus.Success) {
                    this.notificationService.success('taskPlanner.finaliseAdHocDate.successMessage');
                }
            });
        });
    };
}
