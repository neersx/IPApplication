
// tslint:disable: no-string-literal
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { BehaviorSubject } from 'rxjs';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import * as _ from 'underscore';
import { ScreenDesignerViewData } from '../../../screen-designer.service';
import { SearchStateParams } from '../search.component';
import { criteriaPurposeCode, SearchService } from '../search.service';

@Component({
  selector: 'ipx-search-by-case',
  templateUrl: './search-by-case.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CaseValidCombinationService
  ]
})
export class SearchByCaseComponent implements OnInit {
  @Input() viewData: ScreenDesignerViewData;
  @Input() stateParams: SearchStateParams;
  @Output() readonly search = new EventEmitter();
  @Output() readonly clear = new EventEmitter();
  picklistValidCombination: any;
  extendPicklistQuery: any;
  isCaseCategoryDisabled = new BehaviorSubject(true);
  formData: any = {};
  @ViewChild('caseSearchForm', { static: true }) form: NgForm;
  @ViewChild('casePicklist', { static: true }) casePicklist: IpxTypeaheadComponent;
  @ViewChild('programPicklist', { static: true }) programPicklist: IpxTypeaheadComponent;

  constructor(public cvs: CaseValidCombinationService, public searchService: SearchService, private readonly cdRef: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.resetFormData(true);
  }

  verifyCaseCategoryStatus = () => {
    this.isCaseCategoryDisabled.next(this.cvs.isCaseCategoryDisabled());
  };

  resetFormData(firstLoad?: boolean): void {
    if (this.stateParams.isLevelUp && firstLoad) {
      this.formData = this.searchService.getSearchData('caseSearchForm') || {
        includeProtectedCriteria: this.viewData.canMaintainProtectedRules,
        matchType: 'best-criteria-only'
      };
    } else {
      // this.form.form.reset();
      this.formData = {
        includeProtectedCriteria: this.viewData.canMaintainProtectedRules,
        matchType: 'best-criteria-only'
      };
    }
    this.form.form.markAsDirty();
    this.form.form.markAsTouched();
    this.markFieldAsDirty('program');
    this.markFieldAsDirty('case');
    this.programPicklist.hasBlurred = true;
    this.casePicklist.hasBlurred = true;
    this.cvs.initFormData(this.formData);
    this.isCaseCategoryDisabled.next(true);
    this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
    this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
    this.clear.emit();
    this.cdRef.markForCheck();
  }

  private markFieldAsDirty(field: string): void {
    if (this.form.controls[field]) {
      this.form.controls[field].markAsDirty();
      this.form.controls[field].markAsTouched();
    }
  }

  submitForm(): void {
    this.searchService.setSearchData('caseSearchForm', this.formData);
    this.search.emit(this.form.value);
  }

  onCaseChange(selectedCase): void {
    if (selectedCase && selectedCase.key) {
      this.searchService.getCaseCharacteristics$(selectedCase.key, criteriaPurposeCode.ScreenDesignerCases).subscribe((caseCharacteristics) => {
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

  onCriteriaChange = _.debounce(() => {
    this.searchService.validateCaseCharacteristics$(this.form, criteriaPurposeCode.ScreenDesignerCases).then(validationResults => {
      this.verifyCaseCategoryStatus();
    });
  }, 100);
}
