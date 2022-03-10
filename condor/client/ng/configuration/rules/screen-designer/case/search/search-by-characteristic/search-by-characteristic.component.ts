import { ChangeDetectionStrategy, Component, EventEmitter, Injector, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { ScreenDesignerViewData } from '../../../screen-designer.service';
import { ScreenDesignerSearchType } from '../screen-designer-search-type';
import { SearchStateParams } from '../search.component';
import { criteriaPurposeCode, SearchService } from '../search.service';

@Component({
  selector: 'ipx-search-by-characteristic',
  templateUrl: './search-by-characteristic.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CaseValidCombinationService
  ]
})
export class SearchByCharacteristicComponent implements OnInit, ScreenDesignerSearchType {
  @Input() viewData: ScreenDesignerViewData;
  @Output() readonly search = new EventEmitter();
  @Output() readonly clear = new EventEmitter();
  @Input() stateParams: SearchStateParams;
  picklistValidCombination: any;
  extendPicklistQuery: any;
  isCaseCategoryDisabled = new BehaviorSubject(true);
  formData: any = {};
  @ViewChild('characteristicSearchForm', { static: true }) form: NgForm;

  constructor(public cvs: CaseValidCombinationService, public searchService: SearchService) {
  }

  ngOnInit(): void {
    this.resetFormData(true);
  }

  verifyCaseCategoryStatus = () => {
    this.isCaseCategoryDisabled.next(this.cvs.isCaseCategoryDisabled());
  };

  resetFormData(firstLoad?: boolean): void {
    if (this.stateParams.isLevelUp && firstLoad) {
      this.formData = this.searchService.getSearchData('characteristicsSearchForm') || {
        includeProtectedCriteria: this.viewData.canMaintainProtectedRules,
        matchType: 'exact-match'
      };
    } else {
      this.formData = {
        includeProtectedCriteria: this.viewData.canMaintainProtectedRules,
        matchType: 'exact-match'
      };
    }
    this.cvs.initFormData(this.formData);
    this.isCaseCategoryDisabled.next(true);
    this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
    this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
    this.clear.emit();
  }

  submitForm(): void {
    this.searchService.setSearchData('characteristicsSearchForm', this.formData);
    this.search.emit(this.form.value);
  }

  onCriteriaChange = _.debounce(() => {
    this.searchService.validateCaseCharacteristics$(this.form, criteriaPurposeCode.ScreenDesignerCases).then(validationResults => {
      this.verifyCaseCategoryStatus();
    });
  }, 100);
}
