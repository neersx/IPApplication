import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { BillingService } from 'accounting/billing/billing-service';
import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { delay, distinctUntilChanged, tap } from 'rxjs/operators';
import * as _ from 'underscore';
import { BillingReferenceService } from './billing-reference.service';

@Component({
  selector: 'ipx-billing-references',
  templateUrl: './billing-references.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BillingReferencesComponent implements OnInit {
  caseStepData: any;
  defaultBillReference: any;
  selectedDebtor: any;
  cases: string;
  narrativePickList: any;
  narrativeExtendQuery: any;
  isFinalised: boolean;
  openItemNo: any;
  persistedData: any;

  constructor(private readonly cdr: ChangeDetectorRef,
    private readonly serviceBill: BillingService,
    private readonly service: BillingReferenceService,
    private readonly billingStepsService: BillingStepsPersistanceService) {
    this.narrativeExtendQuery = this.narrativesFor.bind(this);
  }

  ngOnInit(): void {
    this.caseStepData = this.billingStepsService.getStepData(1).stepData;
    this.prepareReferenceRequest();
    this.serviceBill.openItemData$.pipe(
      distinctUntilChanged(),
      delay(200),
      tap((openItem) => {
        this.isFinalised = openItem.Status === 1;
      })
    ).subscribe((res) => {
      if (res) {
        this.getReferences();
        this.cdr.markForCheck();
      }
    });
  }

  getReferences(): void {
    const data = this.billingStepsService.getStepData(2);
    if (data && data.stepData) {
      this.defaultBillReference = data.stepData.referenceData;
      this.persistedData = data.stepData.referenceData;

      return;
    }
    if (!this.openItemNo && this.cases) {
      this.service.getDefaultReferences(this.cases, this.selectedDebtor.LanguageId, this.selectedDebtor.NameId, this.caseStepData.useRenewalDebtor, this.openItemNo)
        .subscribe(res => {
          this.defaultBillReference = res;
          this.defaultBillReference.ReferenceText = res.ReferenceText;
          this.defaultBillReference.Regarding = this.defaultBillReference.Regarding ?? '';
          this.updateStepData();
          this.cdr.detectChanges();
        });
    }
  }

  private readonly updateStepData = (): void => {
    const data = this.billingStepsService.getStepData(2);
    if (data) {
      if (data.stepData) {
        data.stepData.referenceData = this.defaultBillReference;
      } else {
        data.stepData = {
          referenceData: this.defaultBillReference
        };
      }
    }
    this.persistedData = this.defaultBillReference;
  };

  narrativesFor(query: any): void {
    const extended = _.extend({}, query, {
      debtorKey: this.selectedDebtor ? this.selectedDebtor.NameId : null,
      caseKey: this.cases ? this.cases[0] : null
    });

    return extended;
  }

  prepareReferenceRequest(): any {
    this.selectedDebtor = this.caseStepData.debtorData.filter(x => x.DebtorCheckbox)[0];
    this.cases = this.caseStepData.caseData.map(x => x.CaseId).join(',');
    this.openItemNo = this.caseStepData.openItem ? this.caseStepData.openItem.OpenItemNo : null;
    if (this.openItemNo) {
      this.defaultBillReference = {
        ReferenceText: this.caseStepData.openItem.ReferenceText,
        BillScope: this.caseStepData.openItem.Scope,
        StatementText: this.caseStepData.openItem.StatementRef,
        Regarding: this.caseStepData.openItem.Regarding
      };
      this.updateStepData();
    }
    this.cdr.detectChanges();
  }

  copyCaseTitle(): any {
    const title = this.caseStepData.caseData.map(x => x.Title).join(', ');
    this.defaultBillReference.ReferenceText = this.defaultBillReference.ReferenceText ?? '';
    if (this.defaultBillReference.ReferenceText !== '') {
      this.defaultBillReference.ReferenceText += '\n' + title;
    } else {
      this.defaultBillReference.ReferenceText += title;
    }
    this.updateStepData();
  }

  onNarrativeChange(value): any {
    this.defaultBillReference.Regarding = value.text;
    this.updateStepData();
  }

}
