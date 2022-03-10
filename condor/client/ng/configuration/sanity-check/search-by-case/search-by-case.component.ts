
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { ControlContainer, FormGroup, NgForm, NgModelGroup } from '@angular/forms';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { CaseValidateCharacteristicsCombinationService } from 'portfolio/case/case-validate-characteristics-combination.service';
import { BehaviorSubject } from 'rxjs';
import { IpxTypeaheadComponent } from 'shared/component/typeahead/ipx-typeahead';
import * as _ from 'underscore';
import { SanitySearchBaseClass } from '../sanity-search-base-class';

@Component({
    selector: 'ipx-sanity-check-search-by-case',
    templateUrl: './search-by-case.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [
        CaseValidCombinationService
    ],
    viewProviders: [{ provide: ControlContainer, useExisting: NgForm }]
})
export class SearchByCaseComponent extends SanitySearchBaseClass implements OnInit {
    isCaseCategoryDisabled = new BehaviorSubject(true);
    isInstructionTypeSelected = new BehaviorSubject(false);
    @ViewChild('searchForm', { static: true }) form: NgModelGroup;
    @ViewChild('casePicklist', { static: true }) casePicklist: IpxTypeaheadComponent;
    formData: any = {};
    appliesToOptions: Array<any>;
    extendValidCombinationPickList: any;
    picklistValidCombination: any;
    characteristicsExtendQuery = this.characteristicsFor.bind(this);

    constructor(public cvs: CaseValidCombinationService, private readonly cdRef: ChangeDetectorRef, private readonly validatorService: CaseValidateCharacteristicsCombinationService) {
        super();
        this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
        this.extendValidCombinationPickList = this.cvs.extendValidCombinationPickList;
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

    verifyCaseCategoryStatus = () => {
        const isCaseTypeSelected = this.isCaseTypeSelected();
        if (!isCaseTypeSelected) {
            this.formData.caseCategory = null;
            this.formData.caseCategoryExclude = false;
        }
        this.isCaseCategoryDisabled.next(!isCaseTypeSelected);
    };

    onCriteriaChange = _.debounce(() => {
        this.cdRef.markForCheck();
        this.validatorService.validateCaseCharacteristics$(this.form.control, 'S').then(() => {
            this.verifyCaseCategoryStatus();
            _.each(['caseType', 'jurisdiction', 'propertyType', 'caseCategory', 'subType', 'basis'], (e) => {
                this.resetExclusion(this.formData[e], e + 'Exclude');
            });
        });
    }, 100);

    resetExclusion = (baseData: any, exclusion: any): void => {
        if (!baseData) {
            this.formData[exclusion] = null;
        }
    };

    resetFormData(data: any = null): void {
        this.formData = !!data ? { ...data } : {};
        this.cvs.initFormData(this.formData);
        this.isCaseCategoryDisabled.next(!this.isCaseTypeSelected());
        this.cdRef.markForCheck();
    }

    instructionTypeSelected(flag: boolean): void {
        this.isInstructionTypeSelected.next(flag);
    }

    eventSet(): void {
        if (!this.formData.event) {
            this.formData.eventIncludeDue = false;
            this.formData.eventIncludeOccurred = false;
        }
        this.cdRef.markForCheck();
    }

    private readonly isCaseTypeSelected = (): boolean => {
        if (!!this.formData.caseType && !this.formData.caseTypeExclude) {
            return true;
        }

        return false;
    };

    private characteristicsFor(query: any): any {
        const selectedInstructionType = this.formData.instructionType;
        const extended = _.extend({}, query, {
            instructionTypeCode: selectedInstructionType ? selectedInstructionType.code : null
        });

        return extended;
    }
}