import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/core';
import { TimeRecordingHelper } from 'accounting/time-recording-widget/time-recording-helper';
import { TimeRecordingTimerGlobalService } from 'accounting/time-recording-widget/time-recording-timer-global.service';
import { CaseClassesTopic } from 'ajs-upgraded-providers/directives/caseview/case-classes.component';
import { CaseDesignatedCountriesTopic } from 'ajs-upgraded-providers/directives/caseview/case-designated-countries.component';
import { CaseEFilingTopic } from 'ajs-upgraded-providers/directives/caseview/case-e-filing.component';
import { CaseImagesTopic } from 'ajs-upgraded-providers/directives/caseview/case-images.component';
import { CaseNamesTopic } from 'ajs-upgraded-providers/directives/caseview/case-names.component';
import { CaseSummaryTopic } from 'ajs-upgraded-providers/directives/caseview/case-summary.component';
import { CaseTextsTopic } from 'ajs-upgraded-providers/directives/caseview/case-texts.component';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { CaseNavigationService } from 'cases/core/case-navigation.service';
import { AttachmentModalService } from 'common/attachments/attachment-modal.service';
import { AttachmentPopupService } from 'common/attachments/attachments-popup/attachment-popup.service';
import { DmsTopic } from 'common/case-name/dms/dms.component';
import { AppContextService } from 'core/app-context.service';
import { BusService } from 'core/bus.service';
import { FeatureDetection } from 'core/feature-detection';
import { PageTitleService } from 'core/page-title.service';
import { WindowRef } from 'core/window-ref';
import { CaseWebLinksComponent } from 'rightbarnav/caseweblinks/caseweblinks.component';
import { InternalCaseDetailsComponent } from 'rightbarnav/Internalcasedetails/internal-case-details.component';
import { KeepOnTopNotesViewService, KotViewForEnum, KotViewProgramEnum } from 'rightbarnav/keep-on-top-notes-view.service';
import { KotModel } from 'rightbarnav/keepontopnotes/keep-on-top-notes-models';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { map, take, takeUntil } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { IpxTopicsComponent } from 'shared/component/topics/ipx-topics.component';
import * as _ from 'underscore';
import { GenerateDocumentComponent } from '../../common/case-name/generate-document/generate-document.component';
import { CaseviewActionsTopic } from './actions/actions.component';
import { CaseAffectedCasesTopic } from './assignment-recordal/affected-cases.component';
import { CaseDetailService, IppAvailability } from './case-detail.service';
import { ChecklistsComponentTopic } from './checklists/checklists.component';
import { CaseCriticalDatesTopic } from './critical-dates/critical-dates.component';
import { CustomContentTopic } from './custom-content/custom-content.component';
import { CaseDesignElementsTopic } from './design-elements/design-elements.component';
import { CaseEventsGroupTopic } from './events/events.component';
import { CaseFileLocationsTopic } from './file-locations/file-locations.component';
import { OfficialNumbersGroupTopic } from './official-numbers/official-numbers.component';
import { CaseRelatedCasesTopic } from './related-cases/related-cases.component';
import { RenewalsTopic } from './renewals/renewals.component';
import { StandingInstructionsTopic } from './standing-instructions/standing-instructions.component';
import { CaseViewViewData } from './view-data.model';
declare var angular: any;

@Component({
    selector: 'ipx-case-view',
    templateUrl: 'case-view.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [AttachmentPopupService]
})

export class CaseViewComponent implements OnInit, OnDestroy {
    @Input() stateParams: {
        id: number,
        rowKey: string,
        levelUpState: string,
        section: string,
        programId: string,
        isE2e: boolean
    };
    @Input() ippAvailability: IppAvailability;
    @Input() screenControl: any;
    @Input() caseViewData: any;
    @Input() viewData: CaseViewViewData;
    @ViewChild('topicHost') topicHost: IpxTopicsComponent;
    topicOptions: TopicOptions;
    navData: {
        keys: Array<number>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    caseViewTitle: string;
    caseViewLink: string;
    showWebLink = false;
    policingStatus: string;
    hasFailedPolicing: boolean;
    hasPreviousState = false;
    iconTooltip: string;
    isTrademark: boolean;
    isCopyright: boolean;
    isDesign: boolean;
    isExternal: boolean;
    isNone: boolean;
    isIe: boolean;
    inproVersion16 = false;
    isPatent: boolean;
    navigationState: string;
    caseProgram: string;
    isEditMode = new BehaviorSubject(false);
    topicControlCount: number;
    kotNotes: Array<KotModel>;
    timerService: TimeRecordingTimerGlobalService;
    private isTimeRecordingAllowed: boolean;
    private readonly refreshSettings = {
        refreshTopicNames: ['summary', 'criticalDates', 'actions', 'events', 'eFiling'],
        refreshTopicKeys: ['summary']
    };
    private readonly unsubscribe$ = new Subject();

    constructor(
        readonly sharedService: CaseNavigationService,
        private readonly caseDetailService: CaseDetailService,
        private readonly notificationService: NotificationService,
        private readonly appContextService: AppContextService,
        private readonly state: StateService,
        private readonly featureDetection: FeatureDetection,
        private readonly windoeRef: WindowRef,
        private readonly cdr: ChangeDetectorRef,
        public rightBarNavService: RightBarNavService,
        private readonly pageTitleService: PageTitleService,
        readonly bus: BusService,
        private readonly kotViewService: KeepOnTopNotesViewService,
        private readonly modalService: IpxModalService,
        private readonly injector: Injector,
        private readonly attachmentModalService: AttachmentModalService,
        private readonly attachmentPopupService: AttachmentPopupService) {
    }

    ngOnInit(): void {
        if (this.stateParams.rowKey) {
            this.hasPreviousState = true;
        }
        this.viewData.caseId = this.stateParams.id;
        this.kotViewService.getKotForCaseView(this.viewData.caseId.toString(), KotViewProgramEnum.Case, KotViewForEnum.Case).subscribe(res => {
            this.kotNotes = res.result;
            this.rightBarNavService.registerKot(this.kotNotes);
        });
        this.iconTooltip = this.viewData.status + ' ' + this.viewData.propertyType;
        this.isTrademark = this.viewData.propertyTypeCode === 'T';
        this.isCopyright = this.viewData.propertyTypeCode === 'C';
        this.isDesign = this.viewData.propertyTypeCode === 'D';
        this.isPatent = this.viewData.propertyTypeCode === 'P';
        this.isNone = !this.isPatent && !this.isCopyright && !this.isDesign && !this.isTrademark;
        this.caseViewTitle = this.viewData.irn;

        this.appContextService.appContext$
            .pipe(take(1))
            .subscribe(ctx => {
                this.pageTitleService.setPrefix(this.caseViewTitle);
                this.isExternal = ctx.user.isExternal;
                this.showWebLink = (ctx.user ? ctx.user.permissions.canShowLinkforInprotechWeb === true : false);
                this.isTimeRecordingAllowed = (!!ctx && !!ctx.user && !!ctx.user.permissions) ? ctx.user.permissions.canAccessTimeRecording : false;

                this.initializeTopics();

                this.setContextNavigation();
                this.navigationState = this.state.current.name;
                // tslint:disable-next-line: prefer-object-spread
                this.navData = Object.assign({}, this.sharedService.getNavigationData(), {
                    fetchCallback: (currentIndex: number): any => {
                        return this.sharedService.fetchNext$(currentIndex).toPromise();
                    }
                });
                this.cdr.markForCheck();
            });

        this.isIe = this.featureDetection.isIe();
        this.featureDetection.hasSpecificRelease$(16).subscribe(r => {
            this.inproVersion16 = r;
        });
        this.caseViewLink = 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({ caseKey: this.viewData.caseKey }));

        this.caseDetailService.getCaseProgram$(this.stateParams.programId).subscribe(p => {
            this.caseProgram = p ? p : 'caseview.pageTitle';
            this.cdr.markForCheck();
        });

        this.caseDetailService.hasPendingChanges$.subscribe((data) => {
            this.isEditMode.next(data && Object.keys(data).length > 0);
        });

        this.watchAttachmentChanges();
    }

    initializeTopics(): void {
        const defaultViewData = {
            viewData: this.viewData
        };

        const topics = {
            summary: new CaseSummaryTopic({
                viewData: this.viewData,
                showWebLink: this.showWebLink,
                screenControl: this.screenControlFor('summary', this.screenControl),
                hasScreenControl: (this.screenControl !== null),
                withImage: this.viewData.imageKey != null,
                isExternal: this.isExternal
            }),
            names: new CaseNamesTopic({
                viewData: this.viewData,
                isExternal: this.isExternal,
                showWebLink: this.showWebLink,
                screenCriteriaKey: this.screenControl ? this.screenControl.id : null
            }),
            officialNumbers: new OfficialNumbersGroupTopic(defaultViewData, this.caseViewData.canViewOtherNumbers),
            classes: new CaseClassesTopic({
                viewData: this.viewData,
                enableRichText: this.caseViewData.displayRichTextFormat
            }),
            caseCustomContent: new CustomContentTopic({
                viewData: this.viewData
            }),
            caseText: new CaseTextsTopic({
                viewData: this.viewData,
                enableRichText: this.caseViewData.displayRichTextFormat,
                keepSpecHistory: this.caseViewData.keepSpecHistory
            }),
            images: new CaseImagesTopic(defaultViewData),
            relatedCases: new CaseRelatedCasesTopic({
                viewData: this.viewData,
                ippAvailability: this.ippAvailability,
                isExternal: this.isExternal
            }),
            events: new CaseEventsGroupTopic(defaultViewData),
            criticalDates: new CaseCriticalDatesTopic(defaultViewData),
            actions: new CaseviewActionsTopic(defaultViewData),
            designElement: new CaseDesignElementsTopic(defaultViewData),
            affectedCases: new CaseAffectedCasesTopic({
                viewData: this.viewData,
                showWebLink: this.showWebLink
            }),
            designatedCountries: new CaseDesignatedCountriesTopic({
                viewData: this.viewData,
                ippAvailability: this.ippAvailability,
                showWebLink: this.showWebLink
            }),
            eFiling: new CaseEFilingTopic(defaultViewData),
            caseRenewals: new RenewalsTopic({
                viewData: angular.extend({}, this.viewData, { screenControl: this.screenControl ? this.screenControl.id : null }),
                showWebLink: this.showWebLink
            }),
            caseStandingInstructions: new StandingInstructionsTopic(
                {
                    viewData: this.viewData,
                    showWebLink: this.showWebLink
                }),
            checklist: new ChecklistsComponentTopic(
                {
                    viewData: this.viewData
                }
            ),
            caseDocumentManagementSystem: new DmsTopic({ ...defaultViewData, callerType: 'CaseView' }),
            fileLocations: new CaseFileLocationsTopic({
                viewData: this.viewData
            }
            )
        };
        const actions: Array<{ key: string, title: string, tooltip: string }> = [];
        if (this.caseViewData.canGenerateWordDocument) {
            actions.push(
                {
                    key: 'generateWord',
                    title: 'documentGeneration.generateWord.title',
                    tooltip: 'documentGeneration.generateWord.title'
                });
        } if (this.caseViewData.canGeneratePdfDocument) {
            actions.push(
                {
                    key: 'generatePdf',
                    title: 'documentGeneration.generatePdf.title',
                    tooltip: 'documentGeneration.generatePdf.title'
                });
        }
        if (this.isTimeRecordingAllowed) {
            actions.push({
                key: 'recordTime',
                title: 'caseTaskMenu.recordTime',
                tooltip: ''
            }, {
                key: 'recordTimeWithTimer',
                title: 'caseTaskMenu.recordTimer',
                tooltip: ''
            });
        }
        this.topicOptions = {
            topics: [
                topics.summary
            ],
            actions
        };

        this.addTopics(['checklist', 'caseRenewals', 'names', 'classes', 'caseCustomContent', 'actions', 'designElement', 'criticalDates', 'events', 'relatedCases', 'officialNumbers', 'designatedCountries', 'caseText', 'eFiling', 'images', 'caseStandingInstructions', 'caseDocumentManagementSystem', 'fileLocations', 'affectedCases'], topics);
    }

    reloadTopics = _.debounce((): void => {
        if (this.topicHost && this.refreshSettings.refreshTopicKeys.length > 0) {
            this.caseDetailService.getOverview$(this.stateParams.id, this.stateParams.rowKey as any).subscribe(
                (data) => {
                    this.bus.channel('viewDataChanged').broadcast(data);
                    this.topicOptions.topics.forEach(topic => topic.params.viewData = data);
                }
            );
        }
    }, 2000, true);

    private readonly addTopics = (topics: Array<string>, definedTopics: { [id: string]: Topic }) => {
        const topicControl = this.getScreenControl(topics, this.screenControl);
        const section = this.stateParams.section || this.sharedService.getSelectedTopic();
        if (topicControl) {
            this.topicControlCount = topicControl.length + 1;
            _.each(topicControl, (e: any, index: number) => {
                const newTopic = angular.extend({}, definedTopics[e.name]);
                newTopic.key = e.name + '_' + e.id;
                newTopic.filters = e.filters;
                newTopic.suffix = e.suffix;
                newTopic.contextKey = e.ref;
                const topicTitle = e.title;
                if (topicTitle) {
                    newTopic.title = topicTitle;
                }
                if (newTopic.topics && e.subTopics) {
                    _.each(e.subTopics, (s: any) => {
                        const subTopic = _.find(newTopic.topics, (t: any) => {
                            return t.key === s.name;
                        });
                        if (subTopic) {
                            subTopic.key = s.name + '_' + s.id;
                            if (s.title) {
                                subTopic.title = s.title;
                            }
                        }
                    });
                }
                if (section) {
                    const isActive = (topic): boolean => {
                        return (topic.key && (topic.key.split('_')[0]).toLowerCase() === section.toLowerCase());
                    };
                    newTopic.isActive = isActive(newTopic);
                    _.each(newTopic.topics, (subTopic: any) => {
                        subTopic.isActive = isActive(subTopic);
                    });
                }
                if (this.refreshSettings.refreshTopicNames.indexOf(e.name) > -1) {
                    if (newTopic.topics && newTopic.topics.length > -1) {
                        newTopic.topics.map((t) => {
                            this.refreshSettings.refreshTopicKeys.push(t.key);
                        });
                    } else {
                        this.refreshSettings.refreshTopicKeys.push(newTopic.key);
                    }
                }
                if (newTopic.filters && newTopic.filters.itemKey) {
                    this.caseDetailService.getCustomContentData$(this.viewData.caseId, newTopic.filters.itemKey).subscribe(response => {
                        const docItemFilters: any = {
                            title: response.title,
                            customContentUrl: response.customUrl,
                            className: response.className
                        };

                        newTopic.title = docItemFilters.title ? docItemFilters.title : newTopic.title;
                        newTopic.filters.customContentUrl = docItemFilters.customContentUrl ? docItemFilters.customContentUrl : newTopic.customContentUrl;
                        newTopic.className = docItemFilters.className;

                        this.topicOptions.topics.splice((index + 1), 0, newTopic);
                        this.cdr.markForCheck();
                    });
                } else {
                    this.topicOptions.topics.push(newTopic);
                }
            });
        }
    };

    topicsInitialized = (): boolean => {
        return !this.topicControlCount || this.topicControlCount === this.topicOptions.topics.length;
    };

    activeTopicChanged(topicKey: string): void {
        this.sharedService.setSelectedTopic(topicKey);
    }

    actionClicked(topicKey: string): void {
        switch (topicKey) {
            case 'generateWord':
                this.modalService.openModal(GenerateDocumentComponent, {
                    animated: false,
                    ignoreBackdropClick: true,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isCase: true,
                        caseKey: this.viewData.caseKey,
                        irn: this.viewData.irn,
                        isWord: true,
                        isE2e: this.stateParams.isE2e
                    }
                });
                break;
            case 'generatePdf':
                this.modalService.openModal(GenerateDocumentComponent, {
                    animated: false,
                    ignoreBackdropClick: true,
                    backdrop: 'static',
                    class: 'modal-xl',
                    initialState: {
                        isCase: true,
                        caseKey: this.viewData.caseKey,
                        irn: this.viewData.irn,
                        isWord: false
                    }
                });
                break;
            case 'recordTime':
                TimeRecordingHelper.initiateTimeEntry(this.viewData.caseKey);
                break;
            case 'recordTimeWithTimer':
                if (!this.timerService) {
                    this.timerService = this.injector.get<TimeRecordingTimerGlobalService>(TimeRecordingTimerGlobalService);
                }
                this.timerService.startTimerForCase(this.viewData.caseKey);
                break;
            default:
                break;
        }
    }

    toCaseDetails = () => {
        if (this.isIe || this.inproVersion16) {
            this.windoeRef.nativeWindow.open(this.caseViewLink, '_blank');
        } else {
            const caseUrl = this.featureDetection.getAbsoluteUrl('?caseref=' + encodeURIComponent(this.viewData.irn));
            this.notificationService.ieRequired(caseUrl.replace('/apps/?caseref=', '/?caseref='));
        }
    };

    private readonly screenControlFor = (topic: string, rules: any) => {
        const screenControl = this.getScreenControl([topic], rules);
        if (!screenControl || !screenControl.length) {
            return null;
        }

        return _.indexBy(screenControl[0].fields, 'fieldName');
    };
    private readonly getScreenControl = (topics: Array<string>, rules: any) => {
        if (!rules) {
            return null;
        }

        if (rules.topics && rules.topics.length > 0) {
            rules.topics.map((item) => {
                if (item.name === CommonTopics.ChangeOfOwner) {
                    if (!rules.topics.some(x => x.name === CommonTopics.AssignedCases)
                        && !rules.topics.some(x => x.name === CommonTopics.AffectedCases)) {
                        item.name = CommonTopics.AffectedCases;
                    }
                } else if (item.name === CommonTopics.AssignedCases) {
                    item.name = CommonTopics.AffectedCases;
                }
            });

            return rules.topics.filter((t) => topics.indexOf((t).name) >= 0);
        }

        return null;
    };

    private readonly setContextNavigation = () => {
        const context: any = {};
        context.contextQuickLinks = new QuickNavModel(CaseWebLinksComponent, {
            id: 'contextQuickLinks',
            title: 'caseview.contextNavigationTooltip.quickLinks',
            icon: 'cpa-icon-bookmark',
            tooltip: 'caseview.contextNavigationTooltip.quickLinks',
            resolve: {
                viewData: (): Observable<any> => {
                    return this.caseDetailService.getCaseWebLinks$(this.viewData.caseKey);
                }
            }
        });
        context.contextEmail = new QuickNavModel(null, {
            id: 'contextEmail',
            icon: 'cpa-icon-envelope',
            tooltip: 'caseview.contextNavigationTooltip.email',
            click: () => {
                this.caseDetailService.getCaseSupportUri$(this.viewData.caseKey).toPromise()
                    .then((support) => {
                        window.location.href = support.uri;
                    });
            }
        });
        if (!this.isExternal) {
            context.contextCaseDetails = new QuickNavModel(InternalCaseDetailsComponent, {
                id: 'contextCaseDetails',
                title: 'caseview.internalCaseDetails.header',
                icon: 'cpa-icon-info-circle',
                tooltip: 'caseview.contextNavigationTooltip.caseDetails',
                resolve: {
                    viewData: (): Observable<any> => {
                        return this.caseDetailService.getCaseInternalDetails$(this.viewData.caseKey)
                            .pipe(
                                map((response: any) => {
                                    const details = { criteriaNum: this.screenControl ? this.screenControl.id : null, caseID: this.viewData.caseKey };

                                    return { ...response, ...details };
                                }));
                    }
                }
            });
        }
        if (this.caseViewData.canViewCaseAttachments || this.caseViewData.canAccessDocumentsFromDms) {
            context.contextAttachments = new QuickNavModel(null, {
                id: 'contextAttachments',
                icon: 'cpa-icon-paperclip',
                tooltip: 'caseview.contextNavigationTooltip.attachments',
                click: () => {
                    this.attachmentModalService.displayAttachmentModal('case', this.viewData.caseKey, {});
                }
            });
        }
        this.rightBarNavService.registercontextuals(context);
    };

    private readonly watchAttachmentChanges = (): void => {
        this.attachmentModalService.attachmentsModified
            .pipe(takeUntil(this.unsubscribe$))
            .subscribe(() => {
                this.attachmentPopupService.clearCache();
            });
    };

    ngOnDestroy(): void {
        this.unsubscribe$.next();
        this.unsubscribe$.complete();
    }
}

enum CommonTopics {
    AssignedCases = 'assignedCases',
    ChangeOfOwner = 'changeOfOwner',
    AffectedCases = 'affectedCases'
}
