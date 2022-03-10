import { Injectable } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { BillingType } from 'accounting/billing/billing.model';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { CreateBillsModalComponent } from './create-bills-modal/create-bills-modal.component';
import { BillPreparationData } from './wip-overview.data';
import { WipOverviewService } from './wip-overview.service';

@Injectable()
export class WipOverviewProvider {

    modalRef: BsModalRef;
    constructor(
        private readonly wipOverviewService: WipOverviewService,
        private readonly modalService: IpxModalService,
        private readonly stateService: StateService,
        private readonly notificationService: IpxNotificationService,
        private readonly translate: TranslateService
    ) {
    }

    createSingleBill = (selectedItems: Array<any>, entities: Array<any>): void => {
        this.wipOverviewService.singleBillViewData = null;
        this.wipOverviewService.validateSingleBillCreation(selectedItems).subscribe((response) => {
            if (response && response.length > 0) {
                const errors: Array<string> = [];
                _.each(response, (error: any) => {
                    errors.push(this.translate.instant('wipOverviewSearch.createBills.validationErrors.' + error.errorCode)
                        + (error.caseReference ? ' - ' + error.caseReference : '')
                    );
                });
                if (errors.length === 1) {
                    this.notificationService.openAlertModal('modal.unableToComplete', errors[0]);

                } else {
                    this.notificationService.openAlertListModal('modal.unableToComplete', 'wipOverviewSearch.createBills.validationErrors.header', 'button.ok', null, null, errors, null, null, null, null, true, 'lg');
                }

            } else {
                this.openCreateBillsModal(selectedItems, entities);
            }
        });

    };

    private readonly openCreateBillsModal = (selectedItems: Array<any>, entities: Array<any>): void => {
        this.modalRef = this.modalService.openModal(CreateBillsModalComponent, {
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                selectedItems,
                entities
            }
        });

        this.modalRef.content.proceedClicked.subscribe((formData: BillPreparationData) => {
            if (formData) {
                this.wipOverviewService.singleBillViewData = { billPreparationData: formData, selectedItems, itemType: BillingType.debit };
                this.stateService.go('create-single-bill');
            }
        });
    };
}
