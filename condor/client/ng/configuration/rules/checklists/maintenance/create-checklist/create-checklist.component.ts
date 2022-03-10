import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { SearchService } from 'configuration/rules/screen-designer/case/search/search.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service';
import { BehaviorSubject, Subject } from 'rxjs';
import * as _ from 'underscore';
import { ChecklistMaintenanceService } from '../checklist-maintenance.service';

@Component({
    selector: 'ipx-create-checklist',
    templateUrl: './create-checklist.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class CreateChecklistComponent implements OnInit {

    success$ = new Subject<boolean>();
    formGroup: FormGroup;
    hasOffices: boolean;
    canAddProtectedRules: boolean;
    canAddRules: boolean;
    appliesToOptions: Array<any>;
    isCaseCategoryDisabled = new BehaviorSubject(true);
    picklistValidCombination: any;
    extendPicklistQuery: any;
    @ViewChild('checklistCriteriaForm', { static: true }) form: NgForm;
    criteria: any;

    constructor(private readonly bsModalRef: BsModalRef, private readonly translateService: TranslateService, private readonly formBuilder: FormBuilder,
        public cvs: CaseValidCombinationService, private readonly searchService: SearchService, private readonly maintainService: ChecklistMaintenanceService, private readonly notification: NotificationService) {
        this.appliesToOptions = [{
            value: 'local-clients',
            label: 'checklistConfiguration.search.localOrForeignDropdown.localClients'
        }, {
            value: 'foreign-clients',
            label: 'checklistConfiguration.search.localOrForeignDropdown.foreignClients'
        }];
    }

    ngOnInit(): void {
        this.formGroup = this.formBuilder.group({
            office: new FormControl(this.criteria.office),
            checklist: [this.criteria.checklist],
            caseType: new FormControl(this.criteria.caseType),
            jurisdiction: new FormControl(this.criteria.jurisdiction),
            propertyType: new FormControl(this.criteria.propertyType),
            caseCategory: new FormControl(this.criteria.caseCategory),
            subType: new FormControl(this.criteria.subType),
            basis: new FormControl(this.criteria.basis),
            profile: new FormControl(this.criteria.profile),
            applyTo: new FormControl(this.criteria.applyTo),
            criteriaName: [null],
            isProtected: [this.canAddRules ? 'false' : 'true'],
            isInUse: ['false']
        });
        this.cvs.initFormData(this.formGroup.value);
        this.isCaseCategoryDisabled.next(true);
        this.picklistValidCombination = this.cvs.validCombinationDescriptionsMap;
        this.extendPicklistQuery = this.cvs.extendValidCombinationPickList;
    }

    isSaveEnabled(): boolean {

        return this.formGroup.valid;
    }

    onSave(): void {
        if (this.formGroup.value && this.formGroup.valid && this.formGroup.dirty) {
            this.maintainService.createChecklist(this.formGroup.value)
                .subscribe((response: any) => {
                    if (response.status) {
                        this.notification.success();
                        this.success$.next(true);
                        this.bsModalRef.hide();
                    } else {
                        if (response.error) {
                            if (response.error.field) {
                                const message = this.translateService.instant('checklistConfiguration.errors.' + response.error.field, { criteriaId: response.error.message });
                                this.notification.alert({ message });
                            } else {
                                this.notification.alert({ message: response.error.customerValidationMessage });
                            }
                        } else {
                            this.notification.alert(null);
                        }
                    }
                });
        }

        return;
    }

    cancel(): void {
        this.bsModalRef.hide();

        return;
    }

    onCriteriaChange = _.debounce(() => {
        this.searchService.validateCaseCharacteristics$(this.formGroup, 'C').then(() => {
            this.cvs.initFormData(this.formGroup.value);
            this.isCaseCategoryDisabled.next(this.cvs.isCaseCategoryDisabled());
        });
    }, 100);
}
