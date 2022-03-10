import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject } from 'rxjs';
import { takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { TaxCodeOverviewTopic, TaxCodeRatesTopic } from './tax-code-topics/tax-code.topics';
import { TaxCodeService } from './tax-code.service';

@Component({
    selector: 'ipx-tax-code',
    templateUrl: './tax-code-details.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaxCodeDetailsComponent implements OnInit {
    @Input() viewData: any;
    @Input() stateParams: {
        id: number,
        rowKey: string
    };
    taxCodeTitle: string;
    topicOptions: TopicOptions;
    hasPreviousState = false;
    navData: {
        keys: Array<any>,
        totalRows: number,
        pageSize: number,
        fetchCallback(currentIndex: number): any
    };
    navigationState: string;
    taxCodeIds: Array<any>;
    showNavigation: BehaviorSubject<boolean> = new BehaviorSubject(true);
    showNavigation$ = this.showNavigation.asObservable();
    rowKey: any;
    taxCodeIndex: number;
    isLoading = false;

    constructor(private readonly taxCodeService: TaxCodeService,
        private readonly state: StateService,
        private readonly navService: GridNavigationService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly notificationService: NotificationService,
        private readonly translate: TranslateService,
        private readonly localSettings: LocalSettings) { }

    ngOnInit(): void {
        if (this.stateParams.id) {
            this.taxCodeIds = this.localSettings.keys.navigation.ids.getLocal;
            this.hasPreviousState = (this.stateParams.id && this.stateParams.rowKey) ? true : false;
            this.initializeTaxCodeTopics();
            this.taxCodeIndex = _.indexOf(this.taxCodeIds, this.stateParams.id);
            this.taxCodeService._taxCodeDescription$.subscribe(r => {
                if (r !== null) {
                    this.taxCodeTitle = r;
                }
            });
        }
        this.initializeTaxCodeTopics();
        this.navigationState = this.state.current.name;
        this.navData = {
            ...this.navService.getNavigationData(),
            fetchCallback: (currentIndex: number): any => {
                return this.navService.fetchNext$(currentIndex).toPromise();
            }
        };
        if (!this.stateParams.rowKey) {
            this.rowKey = _.first(this.navData.keys.filter(x => x.value === this.stateParams.id.toString())).key;
        }
        this.showNavigation.next(true);
    }

    delete = (): void => {
        if (this.stateParams.id) {
            const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('roleDetails.deletemsg');
            notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
                .subscribe(() => {
                    const ids: Array<number> = [];
                    ids.push(this.stateParams.id);
                    this.taxCodeService.deleteTaxCodes(ids).subscribe((response: any) => {
                        if (response.hasError) {
                            const message = this.translate.instant('roleDetails.alert.alreadyInUseOnDetail');
                            const title = 'modal.unableToComplete';
                            this.notificationService.alert({
                                title,
                                message
                            });
                        } else {
                            this.taxCodeService.getTaxCodes(this.localSettings.keys.navigation.searchCriteria.getLocal, this.localSettings.keys.navigation.queryParams.getLocal).subscribe(res => {
                                this.notificationService.success();
                                this.navigateToNext();
                            });
                        }
                    });
                });
        }
    };

    onSave = (): void => {
        if (this.isFormDirty()) {
            this.isLoading = true;
            const taxCodeDetails = this.getFormData();
            this.taxCodeService.updateTaxCodeDetails(taxCodeDetails.formData).subscribe(result => {
                if (result) {
                    this.notificationService.success();
                    this.isLoading = false;
                    this.clearAndRevert();
                }
            });
        }
    };

    revert = (): void => {
        if (this.isFormDirty()) {
            const roleDetailsNotificationModalRef = this.ipxNotificationService.openDiscardModal();
            roleDetailsNotificationModalRef.content.confirmed$.subscribe(() => {
                this.isLoading = false;
                this.clearAndRevert();
            });
        }
    };

    clearAndRevert = (): void => {
        _.each(this.topicOptions.topics, (t: any) => {
            if (_.isFunction(t.clear) && (_.isFunction(t.revert))) {
                t.revert();
                t.clear();
            }
        });
    };

    diasble = (): boolean => {
        const dirty = !this.isFormDirty();
        const valid = this.isFormInValid();

        return dirty || valid || this.isLoading;
    };

    private getFormData(): any {
        if (!this.topicOptions.topics) {
            return null;
        }
        const data = { filterCriteria: { searchRequest: {} as any }, formData: {} };
        _.each(this.topicOptions.topics, (t: any) => {
            if (_.isFunction(t.getFormData)) {
                const topicData = t.getFormData();
                if (topicData) {
                    _.extend(data.formData, topicData.formData);
                }
            }
        });

        return data;
    }

    isFormDirty(): boolean {
        const isDirty = _.any(this.topicOptions.topics, (t: any) => {
            return _.isFunction(t.isDirty) && t.isDirty();
        });

        return isDirty;
    }

    isFormInValid(): boolean {
        const isInValid = _.any(this.topicOptions.topics, (t: any) => {
            return _.isFunction(t.isValid) && !t.isValid();
        });

        return isInValid;
    }

    navigateToNext = (): void => {
        this.taxCodeIds = this.localSettings.keys.navigation.ids.getLocal;
        const ids = this.taxCodeIds;
        const total: any = ids ? ids.length : 0;
        const stateParam = {
            id: this.stateParams.id
        };
        if (total === 0) {
            this.state.go('taxcodes', { location: 'replace' });

            return;
        } else if (this.taxCodeIndex < total) {
            stateParam.id = total === 1 && this.taxCodeIndex !== 0 ? ids[this.taxCodeIndex - 1] : ids[this.taxCodeIndex];
        } else if (this.taxCodeIndex === total) {
            stateParam.id = ids[this.taxCodeIndex - 1];
        }

        const navKeyIndex = _.findIndex(this.navData.keys, (data: any) => {
            return data.value === this.stateParams.id.toString();
        });
        this.navData.keys.splice(navKeyIndex, 1);
        _.each(this.navData.keys, (item, index) => {
            item.key = (index + 1).toString();
        });
        const rowkey = _.first(this.navData.keys.filter(x => x.value === stateParam.id.toString())).key;

        this.state.go('tax-details', {
            id: stateParam.id,
            rowKey: rowkey
        }, { location: 'replace' });
    };

    goToTaxCode = (): void => {
        this.state.go('taxcodes', { location: 'replace' });
    };

    activeTopicChanged(topicKey: string): void {
        this.taxCodeService.setSelectedTopic(topicKey);
    }

    initializeTaxCodeTopics = (): void => {
        const params = {
            viewData: {
                taxRateId: this.stateParams.id,
                taskSecurity: this.viewData
            }
        };
        const topics = {
            taxOverview: new TaxCodeOverviewTopic(
                params
            ),
            taxRates: new TaxCodeRatesTopic(
                params
            )
        };
        this.topicOptions = {
            topics: [
                topics.taxOverview,
                topics.taxRates
            ],
            actions: []
        };
    };
}