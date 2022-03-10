import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { LocalSettings } from 'core/local-settings';
import { SingleBillViewData } from 'search/wip-overview/wip-overview.data';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { BillingService } from './billing-service';
import { BillingStepsPersistanceService } from './billing-steps-persistance.service';
import { BillingWizardMultistepComponent } from './billing-wizard-multistep/billing-wizard-multistep.component';
import { BillingType } from './billing.model';

@Component({
    selector: 'billing',
    templateUrl: './billing.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    animations: [slideInOutVisible]
})
export class BillingComponent implements OnInit, AfterViewInit {
    @ViewChild('multiStep', { static: false }) billingSteps: BillingWizardMultistepComponent;
    billingType: number;
    billingTypeEnum = BillingType;
    showSearchBar = true;
    openItemNo: string;
    entityId: number;
    openItemData: any;
    currentStep: any;
    @Input() viewData: any;
    singleBillViewData: SingleBillViewData;
    billingHeader: string;

    constructor(private readonly stateService: StateService, private readonly service: BillingService, readonly cdRef: ChangeDetectorRef,
        private readonly billingStepsService: BillingStepsPersistanceService,
        private readonly dateHelper: DateHelper, private readonly translate: TranslateService,
        private readonly ipxNotificationService: IpxNotificationService) { }

    ngOnInit(): void {
        this.billingStepsService.initializeSteps();
        this.billingType = this.stateService.params.type;
        this.openItemNo = this.stateService.params.openItemNo;
        this.singleBillViewData = this.viewData.singleBillData;
        this.entityId = this.singleBillViewData ? this.singleBillViewData.billPreparationData.entityId : this.stateService.params.entityId;
        this.service.reasonList$.next(this.viewData.Site.ReasonList);
        this.billingHeader = this.billingType === this.billingTypeEnum.credit ? this.translate.instant('accounting.billing.creditNote') : this.translate.instant('accounting.billing.debitNote');

        if (this.singleBillViewData) {
            const itemDate = this.singleBillViewData.billPreparationData.fromDate ? this.singleBillViewData.billPreparationData.fromDate : new Date();
            this.setOpenItemData({
                ItemDate: this.dateHelper.convertForDatePicker(itemDate),
                StaffId: this.singleBillViewData.billPreparationData.raisedBy.key,
                StaffName: this.singleBillViewData.billPreparationData.raisedBy.displayName,
                ItemEntityId: this.singleBillViewData.billPreparationData.entityId,
                ItemType: this.singleBillViewData.itemType,
                CanUseRenewalDebtor: this.singleBillViewData.billPreparationData.useRenewalDebtor,
                IncludeOnlyWip: this.singleBillViewData.billPreparationData.useRenewalDebtor ? 'R' : null
            });
        } else {
            this.service.getOpenItem$(this.billingType, this.entityId, this.openItemNo).subscribe((openItem) => {
                this.setOpenItemData(openItem);
            });
        }
    }

    private readonly setOpenItemData = (openItem: any) => {
        if (openItem.ItemType !== 0) {
            this.billingType = openItem.ItemType;
        } else {
            openItem.ItemType = this.billingType;
        }
        if (openItem.OpenItemNo) {
            this.billingHeader += ' - ' + openItem.OpenItemNo;
        } else {
            this.checkBillWriteUpExchConfiguration();
        }
        this.openItemData = openItem;
        this.service.openItemData$.next(openItem);
        this.cdRef.markForCheck();
    };

    ngAfterViewInit(): void {
        this.billingStepsService.changeStep$.subscribe(change => {
            if (change && this.billingSteps) {
                this.currentStep = change;
                this.billingSteps.goTo(this.currentStep.id);
            }
            this.cdRef.detectChanges();
        });
    }

    checkBillWriteUpExchConfiguration = () => {
        if (!this.viewData.Site.IsBillWriteUpConfigurationValid) {
            this.ipxNotificationService.openWarningModal(null, 'accounting.billing.autoExchangeWriteupWarning');
        }
    };
}