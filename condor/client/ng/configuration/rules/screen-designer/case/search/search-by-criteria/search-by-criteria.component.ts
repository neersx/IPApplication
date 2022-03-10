import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { ScreenDesignerViewData } from '../../../screen-designer.service';
import { SearchStateParams } from '../search.component';
import { SearchService } from '../search.service';

@Component({
  selector: 'ipx-search-by-criteria',
  templateUrl: './search-by-criteria.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SearchByCriteriaComponent implements OnInit {
  @Input() viewData: ScreenDesignerViewData;
  @Input() stateParams: SearchStateParams;

  @Output() readonly search = new EventEmitter();
  @Output() readonly clear = new EventEmitter();
  formData: any = {};
  @ViewChild('criteriaSearchForm', { static: true }) form: NgForm;

  constructor(private readonly searchService: SearchService, private readonly cdRef: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.resetFormData(true);
  }

  resetFormData(firstLoad?: boolean): void {
    if (this.stateParams.isLevelUp && firstLoad) {
      this.formData = this.searchService.getSearchData('criteriaSearchForm') || {};
    } else {
      this.formData = {
      };
    }
    this.clear.emit();
    this.cdRef.markForCheck();
  }
  submitForm(): void {
    this.searchService.setSearchData('criteriaSearchForm', this.formData);
    this.search.emit(this.form.value);
  }
}
