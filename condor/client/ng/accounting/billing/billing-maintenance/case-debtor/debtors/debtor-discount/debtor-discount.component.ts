import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';

@Component({
  selector: 'ipx-debtor-discount',
  templateUrl: './debtor-discount.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DebtorDiscountComponent implements OnInit {
  gridOptions: IpxGridOptions;
  @Input() discountsList: any;

  constructor(
    readonly cdRef: ChangeDetectorRef, private readonly sbsModalRef: BsModalRef
  ) { }

  ngOnInit(): void {
    this.gridOptions = this.buildGridOptions();
    this.cdRef.detectChanges();
  }

  buildGridOptions(): IpxGridOptions {

    return {
      autobind: true,
      navigable: true,
      sortable: true,
      reorderable: false,
      showGridMessagesUsingInlineAlert: false,
      read$: () => {
        return of(this.discountsList).pipe(delay(100));
      },
      columns: this.getColumns()
    };
  }

  getColumns = (): Array<GridColumnDefinition> => {
    const columns: Array<GridColumnDefinition> = [{
      title: 'accounting.billing.step1.debtors.discounts.columns.rate',
      field: 'DiscountRate',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.wipCode',
      field: 'WipCode',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.wipType',
      field: 'WipType',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.wipCategory',
      field: 'WipCategoryDescription',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.caseCountry',
      field: 'Country',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.caseType',
      field: 'CaseTypeDescription',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.propertyType',
      field: 'PropertyTypeDescription',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.action',
      field: 'ActionDescription',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.caseOwner',
      field: 'CaseOwnerName',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.employee',
      field: 'StaffName',
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.applyAs',
      field: 'ApplyAs',
      template: true,
      sortable: false
    }, {
      title: 'accounting.billing.step1.debtors.discounts.columns.basedonAmount',
      field: 'BasedOnAmount',
      sortable: false,
      template: true,
      headerClass: 'k-header-center-aligned topic-section-text-wrap',
      width: 80
    }];

    return columns;
  };

  cancel = (): void => {
    this.sbsModalRef.hide();
  };

}
