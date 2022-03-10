import { AfterViewInit, ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { CaseValidCombinationService } from '../../../../../portfolio/case/case-valid-combination.service';
import { SearchService } from '../../../screen-designer/case/search/search.service';
import { ChecklistConfigurationViewData } from '../../checklists.models';
import { CommonChecklistCharacteristicsComponent } from '../common-characteristics/common-checklist-characteristics.component';
@Component({
    selector: 'ipx-checklist-search-by-characteristics',
    templateUrl: './search-by-characteristic.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [
        CaseValidCombinationService
    ]
})
export class SearchByCharacteristicComponent implements AfterViewInit {
    @Input() viewData: ChecklistConfigurationViewData;
    @Output() readonly search = new EventEmitter();
    @Output() readonly clear = new EventEmitter();
    picklistValidCombination: any;
    extendPicklistQuery: any;
    isCaseCategoryDisabled = new BehaviorSubject(true);
    formData: any = {};
    appliesToOptions: Array<any>;
    @ViewChild('characteristicSearchForm', { static: true }) form: NgForm;
    @ViewChild('characteristics', { static: true }) commonChecklistCharacteristics: CommonChecklistCharacteristicsComponent;
    disableSearch: boolean;

    constructor(public cvs: CaseValidCombinationService, private readonly searchService: SearchService) {
    }

    ngAfterViewInit(): void {
        this.disableSearch = !this.viewData.canMaintainProtectedRules && !this.viewData.canMaintainRules;
        this.resetFormData();
    }

    resetFormData(): void {
        this.commonChecklistCharacteristics.resetFormData();
        this.clear.emit();
    }

    submitForm(): void {
        this.searchService.setSearchData('characteristicsSearchForm', this.formData);
        this.search.emit({ ...this.formData, ...this.commonChecklistCharacteristics.formData });
    }
}
