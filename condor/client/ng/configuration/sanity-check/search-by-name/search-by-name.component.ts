
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { ControlContainer, NgForm, NgModelGroup } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { BehaviorSubject } from 'rxjs';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import * as _ from 'underscore';
import { SanitySearchBaseClass } from '../sanity-search-base-class';

@Component({
    selector: 'ipx-sanity-check-search-by-name',
    templateUrl: './search-by-name.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [
        CaseValidCombinationService
    ],
    viewProviders: [{ provide: ControlContainer, useExisting: NgForm }]
})
export class SearchByNameComponent extends SanitySearchBaseClass implements OnInit {
    isInstructionTypeSelected = new BehaviorSubject(false);
    @ViewChild('searchForm', { static: true }) form: NgModelGroup;
    @ViewChild('casePicklist', { static: true }) casePicklist: IpxTypeaheadComponent;
    formData: any = {};
    appliesToOptions: Array<any>;
    characteristicsExtendQuery = this.characteristicsFor.bind(this);

    constructor(private readonly cdRef: ChangeDetectorRef) {
        super();
        this.appliesToOptions = [{
            value: 'local-clients',
            label: 'sanityCheck.configurations.localOrForeignDropdown.localClients'
        }, {
            value: 'foreign-clients',
            label: 'sanityCheck.configurations.localOrForeignDropdown.foreignClients'
        }];
    }

    ngOnInit(): void {
        this.resetFormData();
    }

    onCriteriaChange = _.debounce(() => {
        this.cdRef.markForCheck();
    }, 100);

    resetExclusion = (baseData: any, exclusion: any): void => {
        if (!baseData) {
            this.formData[exclusion] = null;
        }
    };

    resetFormData(data: any = null): void {
        this.formData = !!data ? { ...data } : {};
        this.cdRef.markForCheck();
    }

    instructionTypeSelected(flag: boolean): void {
        this.isInstructionTypeSelected.next(flag);
        this.formData.characteristic = undefined;
    }

    private characteristicsFor(query: any): any {
        const selectedInstructionType = this.formData.instructionType;
        const extended = _.extend({}, query, {
            instructionTypeCode: selectedInstructionType ? selectedInstructionType.code : null
        });

        return extended;
    }

    tableColumnForCategory(query: any): any {
        return _.extend({}, query, {
            tableType: 'Category'
        });
    }
}