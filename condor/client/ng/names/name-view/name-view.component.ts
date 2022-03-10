import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import * as angular from 'angular';
import { DmsTopic } from 'common/case-name/dms/dms.component';
import { GenerateDocumentComponent } from 'common/case-name/generate-document/generate-document.component';
import { AppContextService } from 'core/app-context.service';
import { InternalNameDetailsComponent } from 'rightbarnav/internalnamedetails/internal-name-details.component';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { NameViewService } from './name-view.service';
import { SupplierDetailsTopic } from './supplier-details/supplier-details.component';
import { TrustAccountingTopic } from './trust-accounting/trust-accounting.component';

@Component({
    selector: 'ipx-name-view',
    templateUrl: 'name-view.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class NameViewComponent implements OnInit, OnDestroy {
    nameProgram: string;
    nameViewTitle: string;
    hasValidated: boolean;
    @Input() nameViewData: {
        nameId: number,
        nameCode: string,
        name: string,
        program: string,
        sections: any,
        supplierTypes: any,
        taxRates: any,
        taxTreatments: any,
        paymentTerms: any,
        nameCriteriaId: number,
        dateEntered: Date,
        dateChanged: Date,
        canGenerateWordDocument: boolean,
        canGeneratePdfDocument: boolean
    };
    constructor(private readonly service: NameViewService, private readonly rightBarNavService: RightBarNavService, private readonly appContextService: AppContextService, private readonly cdRef: ChangeDetectorRef, private readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService, private readonly modalService: IpxModalService) {
    }

    topicOptions: TopicOptions;
    isExternal: boolean;
    isSaveEnabled: boolean;
    showWebLink: boolean;

    // tslint:disable-next-line: no-empty
    ngOnDestroy(): void { }
    ngOnInit(): void {
        this.nameProgram = this.nameViewData.program;
        this.nameViewTitle = this.nameViewData.name;
        if (this.nameViewData.nameCode) {
            this.nameViewTitle = this.nameViewData.nameCode + ' - ' + this.nameViewTitle;
        }
        this.appContextService.appContext$.subscribe(v => {
            this.isExternal = v.user.isExternal;
            this.showWebLink = (v.user ? v.user.permissions.canShowLinkforInprotechWeb === true : false);
            this.setContextNavigation();
        });
        this.initialiseTopics();
        this.service.enableSave.subscribe((enableSave: boolean) => {
            this.isSaveEnabled = enableSave;
            this.cdRef.detectChanges();
        });
    }

    initialiseTopics(): void {
        const topics = {
            supplierDetails: new SupplierDetailsTopic({
                viewData: this.nameViewData
            }),
            trustAccounting: new TrustAccountingTopic({
                viewData: this.nameViewData,
                showWebLink: this.showWebLink
            }),
            nameDocumentManagementSystem: new DmsTopic({
                viewData: this.nameViewData,
                callerType: 'NameView'
            })
        };
        const actions: Array<{ key: string, title: string, tooltip: string }> = [];
        if (this.nameViewData.canGenerateWordDocument) {
            actions.push(
                {
                    key: 'generateWord',
                    title: 'documentGeneration.generateWord.title',
                    tooltip: 'documentGeneration.generateWord.title'
                });
        }
        if (this.nameViewData.canGeneratePdfDocument) {
            actions.push(
                {
                    key: 'generatePdf',
                    title: 'documentGeneration.generatePdf.title',
                    tooltip: 'documentGeneration.generatePdf.title'
                });
        }
        this.topicOptions = {
            topics: [],
            actions
        };

        this.addTopics(['supplierDetails', 'trustAccounting', 'nameDocumentManagementSystem'], topics);
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
                        isCase: false,
                        nameKey: this.nameViewData.nameId,
                        nameCode: this.nameViewData.nameCode,
                        isWord: true
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
                        isCase: false,
                        nameKey: this.nameViewData.nameId,
                        nameCode: this.nameViewData.nameCode,
                        isWord: false
                    }
                });
                break;
            default:
                break;
        }
    }
    private readonly addTopics = (topics: Array<string>, definedTopics: { [id: string]: Topic }) => {
        const topicControl = this.nameViewData.sections.sections;
        if (topicControl) {
            _.each(topicControl, (e: any) => {
                const showTopic = _.find(topics, (t: string) => {
                    return t === e.name;
                });
                if (showTopic) {
                    const newTopic = angular.extend({}, definedTopics[e.name]);
                    newTopic.key = e.name;
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
                    this.topicOptions.topics.push(newTopic);
                }
            });
        }
    };

    saveNameDetails = (): any => {
        const data = { nameId: this.nameViewData.nameId };
        let beforeSaveAction = () => { this.saveNameData(data); };
        _.each(this.topicOptions.topics, (t: any) => {
            if (t.key === 'supplierDetails' && t.formData) {
                if (t.formData.hasOutstandingPurchases && (t.formData.oldRestrictionKey !== t.formData.restrictionKey)) {
                    beforeSaveAction = () => {
                        const notificationRef = this.ipxNotificationService.openConfirmationModal(null, 'nameview.supplierDetails.restrictionConfirmMessage', null, null, null, null, false);
                        notificationRef.content.confirmed$.pipe(
                            take(1))
                            .subscribe(() => {
                                t.formData.updateOutstandingPurchases = true;
                                _.extend(data,
                                    { supplierDetails: t.formData });
                                this.saveNameData(data);
                            });
                        notificationRef.content.cancelled$.pipe(
                            take(1))
                            .subscribe(() => {
                                t.formData.updateOutstandingPurchases = false;
                                _.extend(data,
                                    { supplierDetails: t.formData });
                                this.saveNameData(data);
                            });
                    };
                } else {
                    _.extend(data,
                        { supplierDetails: t.formData });
                }
            }

        });
        beforeSaveAction();

    };

    saveNameData(data: any): void {
        this.service.maintainName$({ nameId: this.nameViewData.nameId, topics: data }).subscribe(res => {
            if (res.sanityCheckResults && res.sanityCheckResults.length !== 0) {
                const canIgnore = !(_.where(res.sanityCheckResults, {
                    canOverride: false,
                    isWarning: false
                }).length > 0);
                const errorList = _.where(res.sanityCheckResults, {
                    isWarning: false
                });
                const hasErrors = errorList.length > 0;
                const warningList = _.where(res.sanityCheckResults, {
                    isWarning: true
                });
                const title = hasErrors ? 'sanityChecks.error.title' : 'sanityChecks.warning.title';
                const message = hasErrors && !canIgnore ? 'sanityChecks.error.message' : hasErrors && canIgnore ? 'sanityChecks.errorWithBypass.message' : 'sanityChecks.warning.message';
                if (!hasErrors) {
                    this.service.savedSuccessful.next(true);
                }
                const sanityRef = this.ipxNotificationService.openSanityModal(title, message, errorList, warningList, hasErrors && canIgnore, hasErrors);
                sanityRef.content.confirmed$.pipe(
                    take(1))
                    .subscribe(() => {
                        this.service.maintainName$({
                            nameId: this.nameViewData.nameId,
                            ignoreSanityCheck: true,
                            topics: data
                        }).subscribe(result => {
                            if (res.status === 'error') {
                                this.notificationService.alert('unSavedChanges');
                            } else {
                                this.notificationService.success();
                                this.service.savedSuccessful.next(true);
                            }
                        });
                    });
            } else {
                if (res.status === 'error') {
                    this.notificationService.alert('unSavedChanges');
                } else {
                    this.notificationService.success();
                    this.service.savedSuccessful.next(true);
                }
            }
        });
    }

    private readonly setContextNavigation = () => {
        const context: any = {};
        if (!this.isExternal) {
            context.contextNameDetails = new QuickNavModel(InternalNameDetailsComponent, {
                id: 'contextNameDetails',
                title: 'nameview.internalNameDetails.header',
                icon: 'cpa-icon-info-circle', tooltip: 'nameview.contextNavigationTooltip.nameDetails',
                resolve: {
                    viewData: (): Observable<any> => {
                        return this.service.getNameInternalDetails$(this.nameViewData.nameId)
                            .pipe(
                                map((response: any) => {
                                    const details = { criteriaNum: this.nameViewData ? this.nameViewData.nameCriteriaId : null, nameID: this.nameViewData.nameId };

                                    return { ...response, ...details };
                                }));
                    }
                }
            });
        }
        this.rightBarNavService.registercontextuals(context);
    };
}