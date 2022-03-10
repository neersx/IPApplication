import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchStateParams } from 'configuration/rules/screen-designer/case/search/search.component';
import { SearchService } from '../../../screen-designer/case/search/search.service';
import { ChecklistConfigurationViewData } from '../../checklists.models';

@Component({
  selector: 'ipx-checklist-search-by-criteria',
  templateUrl: './search-by-criteria.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SearchByCriteriaComponent implements OnInit {
  @Input() viewData: ChecklistConfigurationViewData;
  @Input() stateParams: SearchStateParams;
  @Output() readonly search = new EventEmitter();
  @Output() readonly clear = new EventEmitter();
  formData: any = {};
  @ViewChild('criteriaChecklistSearchForm', { static: true }) form: NgForm;

  constructor(private readonly searchService: SearchService, private readonly cdRef: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.resetFormData(true);
  }

  resetFormData(firstLoad?: boolean): void {
    if (firstLoad) {
        this.formData = this.searchService.getSearchData('criteriaChecklistSearchForm') || {};
    } else {
        this.formData = {
        };
    }
    this.clear.emit();
    this.cdRef.markForCheck();
  }
  submitForm(): void {
    this.searchService.setSearchData('criteriaChecklistSearchForm', this.formData);
    this.search.emit(this.form.value);
  }
}
