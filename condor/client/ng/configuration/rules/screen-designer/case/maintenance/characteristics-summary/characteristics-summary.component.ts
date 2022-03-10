import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { criteriaPurposeCode, SearchService } from '../../search/search.service';

@Component({
  selector: 'app-characteristics-summary',
  templateUrl: './characteristics-summary.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CaseValidCombinationService
  ]
})
export class CharacteristicsSummaryComponent implements OnInit {
  topic: Topic;
  formData: any;
  viewData: any;
  picklistValidCombination: any;
  extendPicklistQuery: any;
  @ViewChild('characteristicEditForm', { static: true }) form: NgForm;

  constructor(public cvs: CaseValidCombinationService, public searchService: SearchService, private readonly cdRef: ChangeDetectorRef) {
    this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
    this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
  }

  ngOnInit(): void {
    this.formData = this.topic.params.viewData.criteriaData;
    this.viewData = this.topic.params.viewData.viewData;
    this.cvs.initFormData(this.formData);
    this.cdRef.markForCheck();
  }

  onCriteriaChange = _.debounce(() => {
    this.searchService.validateCaseCharacteristics$(this.form, criteriaPurposeCode.ScreenDesignerCases);
  }, 100);
}
