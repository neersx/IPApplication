import { Injectable, Injector, Type } from '@angular/core';
import { StateService } from '@uirouter/angular';
import { TimeRecordingWidgetComponent } from 'accounting/time-recording-widget/time-recording-widget.component';
import { AppTimerHostComponent } from 'accounting/time-recording-widget/timer-host.component';
import { CasenamesWarningsComponent } from 'accounting/warnings/case-names-warning/casenames-warnings.component';
import { WarningService } from 'accounting/warnings/warning-service';
import { WipWarningData } from 'accounting/warnings/warnings-model';
import { AdjustWipComponent } from 'accounting/wip/adjust-wip/adjust-wip.component';
import { SplitWipComponent } from 'accounting/wip/split-wip/split-wip.component';
import { CaseviewActionsComponent } from 'cases/case-view/actions/actions.component';
import { AffectedCasesComponent } from 'cases/case-view/assignment-recordal/affected-cases.component';
import { CaseDetailService } from 'cases/case-view/case-detail.service';
import { ChecklistsComponent } from 'cases/case-view/checklists/checklists.component';
import { DesignElementsComponent } from 'cases/case-view/design-elements/design-elements.component';
import { FileLocationsComponent } from 'cases/case-view/file-locations/file-locations.component';
import { AttachmentMaintenanceComponent } from 'common/attachments/attachment-maintenance/attachment-maintenance.component';
import { AttachmentService } from 'common/attachments/attachment.service';
import { DmsComponent } from 'common/case-name/dms/dms.component';
import { GenerateDocumentComponent } from 'common/case-name/generate-document/generate-document.component';
import { NameViewService } from 'names/name-view/name-view.service';
import { SupplierDetailsComponent } from 'names/name-view/supplier-details/supplier-details.component';
import { TrustAccountingComponent } from 'names/name-view/trust-accounting/trust-accounting.component';
import { forkJoin, Observable, of } from 'rxjs';
import { flatMap, map } from 'rxjs/operators';
import { SearchPresentationComponent } from 'search/presentation/search-presentation.component';
import { SearchPresentationService } from 'search/presentation/search-presentation.service';
import { SearchResultsComponent } from 'search/results/search-results.component';
import { SearchResultsService } from 'search/results/search-results.service';
import * as _ from 'underscore';
import { HostedCaseTopicComponent } from './hosted-topic/hosted-case-topic.component';
import { HostedNameTopicComponent } from './hosted-topic/hosted-name-topic.component';

@Injectable()
export class ComponentLoaderConfigService {

    private configurations: { [propName: string]: ComponentData; };
    private stateParams: any;
    constructor(private readonly injector: Injector) {
        this.initConfigs();
    }

    initialize = (stateParams: any) => { // TODO strongly typed
        this.stateParams = stateParams;
    };

    getConfiguration = (serviceName: string) => this.configurations[serviceName];

    private readonly getStateParams = (): any => this.stateParams || this.injector.get(StateService).params;

    private readonly getScreenControl = (topicsName: string, rules: any) => {
        if (!rules) {
            return null;
        }

        if (rules.topics && rules.topics.length > 0) {
            return rules.topics.filter((t: any) => (t).name === topicsName);
        }

        return null;
    };

    private readonly getScreenControlForAffectedCases = (rules: any) => {
        if (!rules) {
            return null;
        }

        if (rules.topics && rules.topics.length > 0) {
            return rules.topics.filter((t: any) => (t).name === 'assignedCases' || (t).name === 'changeOfOwner');
        }

        return null;
    };

    private readonly initConfigs = (): void => {
        this.configurations = {};
        this.addCaseActionsTopicConfig();
        this.addCaseSearchResultConfig();
        this.addSearchPresentationConfig();
        this.addNameSupplierTopicConfig();
        this.addTrustAccountingTopicConfig();
        this.addCaseDesignElementTopicConfig();
        this.addCaseDocumentManagementTopicConfig();
        this.addNameDocumentManagementTopicConfig();
        this.addCaseChecklistTopicConfig();
        this.addCaseFileLocationsTopicConfig();
        this.addWorkflowWizardChecklistTopicConfig();
        this.addCaseNameWarningPopup();
        this.addAttachmentMaintenanceTopicConfig();
        this.addStartTimerForCaseConfig();
        this.addGenerateDocumentConfig();
        this.addTimerWidgetConfig();
        this.addCaseAffectedCasesTopicConfig();
        this.addAdjustWIPConfig();
        this.addSplitWipConfig();
    };

    private readonly addSearchPresentationConfig = () => {
        this.configurations.searchPresentation = {
            component: SearchPresentationComponent,
            resolve: () => {
                const service = this.injector.get(SearchPresentationService);

                return service.getPresentationViewData(this.stateParams).pipe(map(res => {

                    return { viewData: res, stateParams: this.stateParams };
                }));
            }
        };
    };

    private readonly addCaseNameWarningPopup = () => {
        this.configurations.additionalCaseInfoHost = {
            component: CasenamesWarningsComponent,
            resolve: () => {
                const service = this.injector.get(WarningService);
                const today = new Date();
                service.restrictOnWip = this.stateParams.restrictOnWip.toLowerCase() === 'true';

                return service.getCasenamesWarnings(this.stateParams.id, today).pipe(map((warningResponse: WipWarningData) => {
                    if (!warningResponse) {
                        return { stateParams: this.stateParams };
                    }
                    const caseNamesRes = warningResponse.caseWipWarnings;
                    if (!!warningResponse.budgetCheckResult || (!!warningResponse.prepaymentCheckResult && warningResponse.prepaymentCheckResult.exceeded) || !!warningResponse.billingCapCheckResult || caseNamesRes.length && _.any(caseNamesRes, cn => {
                        return cn.caseName.debtorStatusActionFlag !== null || (cn.creditLimitCheckResult && cn.creditLimitCheckResult.exceeded);
                    })) {
                        return { caseNames: caseNamesRes, budgetCheckResult: warningResponse.budgetCheckResult, selectedEntryDate: today, prepaymentCheckResult: warningResponse.prepaymentCheckResult, billingCapCheckResults: warningResponse.billingCapCheckResult, hostId: this.stateParams.hostId };
                    }
                }));
            }
        };
    };

    private readonly addWorkflowWizardChecklistTopicConfig = () => {
        this.configurations.checklistWizardHost = {
            component: ChecklistsComponent,
            resolve: () => {
                return this.getCaseWorkflowTopic(ChecklistsComponent);
            }
        };
    };

    private readonly addCaseSearchResultConfig = () => {
        this.configurations.caseSearchResult = {
            component: SearchResultsComponent,
            resolve: () => {
                const service = this.injector.get(SearchResultsService);

                return service.getSearchResultsViewData({
                    filter: this.stateParams.payload,
                    queryKey: this.stateParams.queryKey,
                    searchQueryKey: false,
                    rowKey: null,
                    isLevelUp: false,
                    queryContext: this.stateParams.queryContextKey,
                    selectedColumns: this.stateParams.selectedColumns
                }).pipe(map(res => {

                    return { viewData: res, savedSearchData: null };
                }));
            }
        };
    };

    private readonly getCaseWorkflowTopic = (caseComponent: Type<any>): Observable<any> => {
        const service = this.injector.get(CaseDetailService);
        const stateParams: {
            id: number,
            section: string,
            programId: string,
            hostId: string,
            genericKey: number
        } = this.getStateParams();

        const viewDataParam = { caseKey: stateParams.id, genericKey: stateParams.genericKey };
        const hostId = stateParams.hostId;
        const preReqs = forkJoin(
            of(viewDataParam),
            service.getCaseViewData$()
        ).pipe(map(res => {
            return {
                viewData: { ...res[0], ...res[1], hostId }
            };
        }));

        return preReqs
            .pipe(flatMap(({
                viewData
            }) => {
                return of({
                    component: caseComponent,
                    key: stateParams.section,
                    params: {
                        viewData
                    }
                }).pipe(map(res => ({
                    topic: res
                })));
            }));
    };

    private readonly getCaseTopic = (caseComponent: Type<any>, getOverviewData = false, getData = false): Observable<any> => {
        const service = this.injector.get(CaseDetailService);
        const stateParams: {
            id: number,
            rowKey: number,
            section: string,
            programId: string,
            hostId: string,
            genericKey: number
        } = this.getStateParams();

        const viewDataParam = getData ? { caseKey: stateParams.id, genericKey: stateParams.genericKey } : { caseKey: stateParams.id };
        const hostId = stateParams.hostId;
        const preReqs = forkJoin(
            getOverviewData ? service.getOverview$(stateParams.id, stateParams.rowKey) : of(viewDataParam),
            service.getCaseViewData$(),
            service.getScreenControl$(stateParams.id, stateParams.programId)
        ).pipe(map(res => {
            return {
                viewData: { ...res[0], ...res[1], hostId },
                screenControl: res[2]
            };
        }));

        return preReqs
            .pipe(flatMap(({
                viewData,
                screenControl
            }) => {
                let topicControl = this.getScreenControl(stateParams.section, screenControl);
                if (topicControl.length === 0 && stateParams.section === 'affectedCases') {
                    topicControl = this.getScreenControlForAffectedCases(screenControl);
                }
                const topic = topicControl[0];

                return of({
                    component: caseComponent,
                    key: stateParams.section,
                    params: {
                        viewData,
                        filters: topic.filters,
                        suffix: topic.suffix,
                        contextKey: topic.ref,
                        title: topic.title
                    }
                }).pipe(map(res => ({
                    topic: res
                })));
            }));
    };

    private readonly getNameTopic = (nameComponent: Type<any>): Observable<any> => {
        const service = this.injector.get(NameViewService);
        const stateParams: {
            id: number,
            hostId: string
        } = this.getStateParams();
        const isHosted = stateParams.hostId === 'supplierHost';
        const hostId = stateParams.hostId;
        const preReqs = forkJoin(
            service.getNameViewData$(stateParams.id)
        ).pipe(map(res => {
            return {
                viewData: { ...res[0], isHosted, hostId },
                callerType: 'NameView'
            };
        }));

        return preReqs
            .pipe(flatMap(({
                viewData,
                callerType
            }) => {
                return of({
                    component: nameComponent,
                    params: {
                        viewData,
                        callerType
                    }
                }).pipe(map(res => ({
                    topic: res
                })));
            }));
    };

    private readonly addCaseActionsTopicConfig = () => {
        this.configurations.caseViewActions = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(CaseviewActionsComponent, true);
            }
        };
    };

    private readonly addCaseDesignElementTopicConfig = () => {
        this.configurations.caseViewDesignElements = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(DesignElementsComponent);
            }
        };
    };

    private readonly addCaseFileLocationsTopicConfig = () => {
        this.configurations.caseViewFileLocations = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(FileLocationsComponent);
            }
        };
    };

    private readonly addCaseAffectedCasesTopicConfig = () => {
        this.configurations.caseViewAffectedCases = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(AffectedCasesComponent);
            }
        };
    };

    private readonly addCaseDocumentManagementTopicConfig = () => {
        this.configurations.caseViewDocumentManagement = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(DmsComponent);
            }
        };
    };

    private readonly addCaseChecklistTopicConfig = () => {
        this.configurations.caseViewChecklist = {
            component: HostedCaseTopicComponent,
            resolve: () => {
                return this.getCaseTopic(ChecklistsComponent, false, true);
            }
        };
    };

    private readonly addNameDocumentManagementTopicConfig = () => {
        this.configurations.nameViewDocumentManagement = {
            component: HostedNameTopicComponent,
            resolve: () => {
                return this.getNameTopic(DmsComponent);
            }
        };
    };

    private readonly addNameSupplierTopicConfig = () => {
        this.configurations.nameViewSupplier = {
            component: HostedNameTopicComponent,
            resolve: () => {
                return this.getNameTopic(SupplierDetailsComponent);
            }
        };
    };

    private readonly addTrustAccountingTopicConfig = () => {
        this.configurations.nameViewTrust = {
            component: HostedNameTopicComponent,
            resolve: () => {
                return this.getNameTopic(TrustAccountingComponent);
            }
        };
    };

    private readonly addAttachmentMaintenanceTopicConfig = () => {
        this.configurations.attachmentMaintenance = {
            component: AttachmentMaintenanceComponent,
            resolve: () => {
                const service = this.injector.get(AttachmentService);
                const baseType = _.isNumber(this.stateParams.caseId) ? 'case' : _.isNumber(this.stateParams.nameId) ? 'name' : 'activity';

                const params = baseType === 'case' ? { eventKey: this.stateParams.eventKey, eventCycle: this.stateParams.eventCycle, actionKey: this.stateParams.actionKey } : {};
                const viewDetails = service.attachmentMaintenanceView$(baseType, this.stateParams.caseId || this.stateParams.nameId || this.stateParams.activityKey, params)
                    .pipe(map((result) => {
                        if (baseType === 'case' && _.isNumber(this.stateParams.caseId) && this.stateParams.eventCycle !== '' && !!result.event && !_.isNumber(result.event.eventCycle)) {
                            result.event.cycle = this.stateParams.eventCycle;
                        }

                        return result;
                    }));

                const attachmentDetails = this.stateParams.activityKey === 0 || !_.isNumber(this.stateParams.sequenceKey)
                    ? of(null)
                    : service.getAttachment$(baseType, this.stateParams.caseId || this.stateParams.nameId, this.stateParams.activityKey, this.stateParams.sequenceKey);

                return forkJoin([viewDetails, attachmentDetails])
                    .pipe(map(result => {
                        return {
                            viewData: {
                                ...result[0],
                                actionKey: this.stateParams.actionKey,
                                id: this.stateParams.caseId || this.stateParams.nameId,
                                baseType
                            },
                            activityAttachment: result[1],
                            activityDetails: (!!result[0].activityDetails ? result[0].activityDetails : {})
                        };
                    }));
            }
        };
    };

    private readonly addStartTimerForCaseConfig = () => {
        this.configurations.startTimerForCase = {
            component: AppTimerHostComponent,
            resolve: () => {
                return of({
                    caseKey: this.stateParams.caseKey
                });
            }
        };
    };

    private readonly addGenerateDocumentConfig = () => {
        this.configurations.generateDocument = {
            component: GenerateDocumentComponent,
            resolve: () => {
                return of({
                    caseKey: this.stateParams.caseKey,
                    isWord: this.stateParams.isWord,
                    isCase: this.stateParams.isCase,
                    nameKey: this.stateParams.nameKey,
                    nameCode: this.stateParams.nameCode,
                    irn: this.stateParams.irn,
                    isE2e: this.stateParams.isE2e
                });
            }
        };
    };

    private readonly addAdjustWIPConfig = () => {
        this.configurations.adjustWip = {
            component: AdjustWipComponent,
            resolve: () => {
                return of({
                    hostId: this.stateParams.hostId,
                    entityKey: this.stateParams.entityKey,
                    transKey: this.stateParams.transKey,
                    wipSeqKey: this.stateParams.wipSeqKey
                });
            }
        };
    };

    private readonly addTimerWidgetConfig = () => {
        this.configurations.timerWidget = {
            component: TimeRecordingWidgetComponent,
            resolve: () => {
                return of({ hostId: this.stateParams.hostId, isHosted: !!this.stateParams.hostId });
            }
        };
    };

    private readonly addSplitWipConfig = () => {
        this.configurations.splitWip = {
            component: SplitWipComponent,
            resolve: () => {
                return of({
                    hostId: this.stateParams.hostId,
                    entityKey: this.stateParams.entityKey,
                    transKey: this.stateParams.transKey,
                    wipSeqKey: this.stateParams.wipSeqKey
                });
            }
        };
    };
}

export class ComponentData {
    component: Type<any>;
    resolve: () => Observable<any>;
}