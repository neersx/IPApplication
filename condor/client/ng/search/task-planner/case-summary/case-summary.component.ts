import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { FeatureDetection } from 'core/feature-detection';
import { LocalSettings } from 'core/local-settings';
import { WindowRef } from 'core/window-ref';
import { AnyMxRecord } from 'dns';
import { combineLatest, merge, of, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, tap } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { findWhere } from 'underscore';
import { ReminderEmailContent } from '../task-planner.data';
import { TaskPlannerService } from '../task-planner.service';
import { CaseSummaryModel, TaskSummaryModel } from './case-summary.model';
import { CaseSummaryService } from './case-summary.service';

@Component({
    selector: 'ipx-case-summary',
    templateUrl: './case-summary.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [
        slideInOutVisible
    ]
})
export class CaseSummaryComponent implements OnInit, AfterViewInit, OnDestroy {
    // tslint:disable-next-line: prefer-inline-decorator
    @Input()
    set caseKey(caseKey: number) {
        this._caseKey = caseKey;
    }
    get caseKey(): number {
        return this._caseKey;
    }

    // tslint:disable-next-line: prefer-inline-decorator
    @Input()
    set taskPlannerKey(taskPlannerKey: number) {
        this._taskPlannerKey = taskPlannerKey;
    }
    get taskPlannerKey(): number {
        return this._taskPlannerKey;
    }

    @Input() showLink = true;
    @Input() isDisplayed: boolean;
    @Input() isExternal: boolean;
    @Input() showLinksForInprotechWeb = false;

    caseRef: string;
    loadDataDebounce: Function;
    caseSummary: CaseSummaryModel;
    taskSummary: TaskSummaryModel;
    showCaseSummary: boolean;
    showCaseNames: boolean;
    showCriticalDates: boolean;
    subscription: Subscription;
    private _caseKey;
    private _taskPlannerKey;
    dateStyle: string;
    hideTaskDetails: boolean;
    hideDelegationDetails: boolean;
    isIe: boolean;
    inproVersion16 = false;
    emailContent: ReminderEmailContent;

    constructor(
        private readonly caseSummaryService: CaseSummaryService,
        private readonly taskPlannerService: TaskPlannerService,
        private readonly cdref: ChangeDetectorRef,
        private readonly localSettings: LocalSettings,
        private readonly windoeRef: WindowRef,
        private readonly featureDetection: FeatureDetection,
        private readonly notificationService: NotificationService
    ) {
    }

    ngOnInit(): void {
        this.showCaseSummary = this.localSettings.keys.taskPlanner.summary.caseSummary.getSession;
        this.showCaseNames = this.localSettings.keys.taskPlanner.summary.caseNames.getSession;
        this.showCriticalDates = this.localSettings.keys.taskPlanner.summary.criticalDates.getSession;
        this.hideTaskDetails = this.localSettings.keys.taskPlanner.summary.taskDetails.getSession;
        this.hideDelegationDetails = this.localSettings.keys.taskPlanner.summary.delegationDetails.getSession;
        this.isIe = this.featureDetection.isIe();
        this.featureDetection.hasSpecificRelease$(16).subscribe(r => {
            this.inproVersion16 = r;
        });
    }

    getCaseSummary(): any {
        return this.taskPlannerService.rowSelected.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap((selectedCaseKey) => {
                this.caseKey = selectedCaseKey ? +selectedCaseKey : null;
            }),
            switchMap(selectedCaseKey => {
                if (selectedCaseKey) {
                    return this.caseSummaryService.getCaseSummary(selectedCaseKey);
                }

                return of(null);
            })
        );
    }

    getTaskDetailsSummary(): any {
        return this.taskPlannerService.taskPlannerRowKey.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap((taskPlannerKey) => {
                this.taskPlannerKey = taskPlannerKey ? +taskPlannerKey : null;
            }),
            switchMap(taskPlannerKey => {
                if (taskPlannerKey) {
                    return this.caseSummaryService.getTaskDetailsSummary(taskPlannerKey);
                }

                return of(null);
            })
        );
    }

    getEmailContent(): any {
        return this.taskPlannerService.taskPlannerRowKey.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap((taskPlannerKey) => {
                this.taskPlannerKey = taskPlannerKey ? +taskPlannerKey : null;
            }),
            switchMap(taskPlannerKey => {
                if (taskPlannerKey) {
                    return this.taskPlannerService.getEmailContent([taskPlannerKey], null);
                }

                return of(null);
            })
        );
    }

    ngAfterViewInit(): void {
        this.subscription = combineLatest([this.getCaseSummary(), this.getTaskDetailsSummary(), this.getEmailContent()]).subscribe(([caseSummary, taskDetailsSummary, emailContents]) => {
            this.cdref.markForCheck();
            if (caseSummary) {
                const summary: any = caseSummary;
                this.caseSummary = summary ? summary as CaseSummaryModel : null;
                if (this.caseSummary) {
                    this.caseSummary.criticalDates =
                        summary.dates.filter((e: { isNextDueEvent: any; isLastEvent: any; }) => !e.isNextDueEvent && !e.isLastEvent);
                    this.caseSummary.nextDueEvent = findWhere(summary.dates, { isNextDueEvent: true });
                    this.caseSummary.lastEvent = findWhere(summary.dates, { isLastEvent: true });
                }
            }
            if (taskDetailsSummary) {
                const taskSummary: any = taskDetailsSummary;
                if (taskSummary) {
                    this.taskSummary = taskSummary;
                }
            } else {
                this.taskSummary = null;
            }
            if (emailContents) {
                this.emailContent = emailContents[0];
            }
        });
    }

    toggleShowCaseSummary = () => {
        this.showCaseSummary = !this.showCaseSummary;
        this.localSettings.keys.taskPlanner.summary.caseSummary.setSession(this.showCaseSummary);
    };

    toggleShowCaseNames = () => {
        this.showCaseNames = !this.showCaseNames;
        this.localSettings.keys.taskPlanner.summary.caseNames.setSession(this.showCaseNames);
    };

    toggleShowCriticalDates = () => {
        this.showCriticalDates = !this.showCriticalDates;
        this.localSettings.keys.taskPlanner.summary.criticalDates.setSession(this.showCriticalDates);
    };

    toggleShowTaskDetails = () => {
        this.hideTaskDetails = !this.hideTaskDetails;
        this.localSettings.keys.taskPlanner.summary.taskDetails.setSession(this.hideTaskDetails);
    };

    togglehideDelegationDetails = () => {
        this.hideDelegationDetails = !this.hideDelegationDetails;
        this.localSettings.keys.taskPlanner.summary.delegationDetails.setSession(this.hideDelegationDetails);
    };

    sendEmail = (email: string) => {
        if (email && this.emailContent) {
            const emailUrl = 'mailto:' + email + '?subject=' + encodeURIComponent(this.emailContent.subject) + '&body=' + encodeURIComponent(this.emailContent.body);
            this.windoeRef.nativeWindow.open(emailUrl, '_blank');
        }
    };

    encodeLinkData = (data: any) => 'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify({ nameKey: data }));

    ngOnDestroy(): void {
        if (!!this.subscription) {
            this.subscription.unsubscribe();
        }
    }

    displayDelegationDetailsPanel(): any {
        return this.taskSummary && (this.taskSummary.caseOffice || this.taskSummary.dueDateResponsibility || this.taskSummary.otherRecipients || this.taskSummary.forwardedFrom || this.taskSummary.adhocResponsibleName);
    }

    toCaseDetails = (caseData: any) => {
        const caseViewLink = 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ caseKey: caseData.caseKey }));
        if (this.isIe || this.inproVersion16) {
            this.windoeRef.nativeWindow.open(caseViewLink, '_blank');
        } else {
            const caseUrl = this.featureDetection.getAbsoluteUrl('?caseref=' + encodeURIComponent(caseData.irn));
            this.notificationService.ieRequired(caseUrl.replace('/apps/?caseref=', '/?caseref='));
        }
    };
}
