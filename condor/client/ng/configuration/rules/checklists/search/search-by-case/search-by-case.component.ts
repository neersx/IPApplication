import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { SearchService } from 'configuration/rules/screen-designer/case/search/search.service';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import * as _ from 'underscore';
import { ChecklistConfigurationViewData } from '../../checklists.models';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';

@Component({
    selector: 'ipx-checklist-search-by-case',
    templateUrl: './search-by-case.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [
        CaseValidCombinationService
    ]
})
export class SearchByCaseComponent implements OnInit, AfterViewInit {
    @Input() viewData: ChecklistConfigurationViewData;
    @Output() readonly search = new EventEmitter();
    @Output() readonly clear = new EventEmitter();
    formData: any = {};
    disableSearch: boolean;
    @ViewChild('caseSearchForm', { static: true }) form: NgForm;
    @ViewChild('characteristics', { static: true }) commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;

    constructor(public cvs: CaseValidCombinationService, private readonly cdRef: ChangeDetectorRef, private readonly searchService: SearchService) {
    }

    ngOnInit(): void {
        this.disableSearch = !this.viewData.canMaintainProtectedRules && !this.viewData.canMaintainRules;
    }

    ngAfterViewInit(): void {
        this.resetFormData();
    }

    onCaseChange(selectedCase: any): void {
        if (selectedCase && selectedCase.key) {
            this.commonChecklistCharacteristics.defaultFieldsFromCase(selectedCase);
        }
    }

    submitForm(): void {
        this.searchService.setSearchData('characteristicsSearchForm', this.formData);
        this.search.emit({ ...this.formData, ...this.commonChecklistCharacteristics.formData });
    }

    resetFormData(): void {
        this.formData = { };
        this.commonChecklistCharacteristics.resetFormData();
        this.clear.emit();
        this.cdRef.markForCheck();
    }
}
