import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchService } from 'configuration/rules/screen-designer/case/search/search.service';
import * as _ from 'underscore';
import { ChecklistConfigurationViewData } from '../../checklists.models';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';

@Component({
    selector: 'ipx-checklist-search-by-question',
    templateUrl: './search-by-question.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class SearchByQuestionComponent implements AfterViewInit {
    @Input() viewData: ChecklistConfigurationViewData;
    @Output() readonly search = new EventEmitter();
    @Output() readonly clear = new EventEmitter();
    formData: any = {};
    @ViewChild('questionSearchForm', { static: true }) form: NgForm;
    @ViewChild('characteristics', { static: true }) commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;

    constructor(private readonly searchService: SearchService, private readonly cdRef: ChangeDetectorRef) {
    }

    ngAfterViewInit(): void {
        this.resetFormData();
    }

    resetFormData(): void {
        this.commonChecklistCharacteristics.resetFormData();
        this.formData = { };
        this.clear.emit();
        this.cdRef.markForCheck();
    }

    submitForm(): void {
        this.searchService.setSearchData('questionSearchForm', this.formData);
        this.search.emit({ ...this.formData, ...this.commonChecklistCharacteristics.formData });
    }
}