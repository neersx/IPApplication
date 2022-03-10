import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { ControlContainer, NgForm } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { CaseValidateCharacteristicsCombinationService } from 'portfolio/case/case-validate-characteristics-combination.service';
import { BehaviorSubject } from 'rxjs/internal/BehaviorSubject';
import * as _ from 'underscore';
import { SearchService } from '../../../screen-designer/case/search/search.service';
import { ChecklistConfigurationViewData } from '../../checklists.models';

@Component({
  selector: 'ipx-common-checklist-characteristics',
  templateUrl: './common-checklist-characteristics.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  viewProviders: [{ provide: ControlContainer, useExisting: NgForm }]
})
export class CommonChecklistCharacteristicsComponent implements OnInit {
  @Input() viewData: ChecklistConfigurationViewData;
  @Output() readonly clear = new EventEmitter();
  formData: any = {};
  appliesToOptions: Array<any>;
  extendPicklistQuery: any;
  picklistValidCombination: any;
  isCaseCategoryDisabled = new BehaviorSubject(true);
  @ViewChild('commonChecklistCharacteristics', { static: true }) form: NgForm;

  constructor(private readonly searchService: SearchService, private readonly cdRef: ChangeDetectorRef, public cvs: CaseValidCombinationService, public cvccs: CaseValidateCharacteristicsCombinationService) {
      this.appliesToOptions = [{
          value: 'local-clients',
          label: 'checklistConfiguration.search.localOrForeignDropdown.localClients'
      }, {
          value: 'foreign-clients',
          label: 'checklistConfiguration.search.localOrForeignDropdown.foreignClients'
      }];
  }

  ngOnInit(): void {
      this.resetFormData();
  }

  onCriteriaChange = _.debounce(() => {
    this.formData = this.formData;
      this.cvccs.validateCaseCharacteristics$(this.form.control, 'C').then(validationResults => {
          this.verifyCaseCategoryStatus();
      });
  }, 100);

  verifyCaseCategoryStatus = () => {
      this.isCaseCategoryDisabled.next(this.cvs.isCaseCategoryDisabled());
  };

  resetFormData(): void {
      this.formData = {
          includeProtectedCriteria: this.viewData?.canMaintainProtectedRules,
          matchType: 'exact-match'
      };
      this.cvs.initFormData(this.formData);
      this.isCaseCategoryDisabled.next(true);
      this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
      this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
      this.clear.emit();
      this.cdRef.markForCheck();
  }

  defaultFieldsFromCase(selectedCase: any): void {
    if (selectedCase && selectedCase.key) {
        this.searchService.getCaseCharacteristics$(selectedCase.key, 'C').subscribe((caseCharacteristics) => {
            this.formData.jurisdiction = caseCharacteristics.jurisdiction;
            this.formData.basis = caseCharacteristics.basis;
            this.formData.caseCategory = caseCharacteristics.caseCategory;
            this.formData.caseType = caseCharacteristics.caseType;
            this.formData.office = caseCharacteristics.office;
            this.formData.program = caseCharacteristics.program;
            this.formData.propertyType = caseCharacteristics.propertyType;
            this.formData.subType = caseCharacteristics.subType;
            this.verifyCaseCategoryStatus();
            this.cdRef.markForCheck();
            this.onCriteriaChange();
        });
    }
}
}