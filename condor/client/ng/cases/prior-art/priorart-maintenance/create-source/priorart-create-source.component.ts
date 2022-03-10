import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { StateService } from '@uirouter/angular';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { PriorArtType } from 'cases/prior-art/priorart-model';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';

@Component({
    selector: 'ipx-priorart-create-source',
    templateUrl: './priorart-create-source.component.html',
    styleUrls: ['./priorart-create-source.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorartCreateSourceComponent implements OnInit {
    formGroup: FormGroup;
    @Input() priorArtSourceTableCodes: any;
    @Input() sourceData: any;
    @Input() hasUpdatePermission: boolean;
    @Input() priorArtType: PriorArtType;
    @Input() translationsList: any = {};
    @Input() asNew?: boolean | false;
    selectedPriorArtType: PriorArtType;
    get PriorArtTypeEnum(): typeof PriorArtType {
        return PriorArtType;
    }
    constructor(private readonly formBuilder: FormBuilder,
        private readonly dateHelper: DateHelper,
        readonly stateService: StateService,
        readonly localDatePipe: LocaleDatePipe,
        readonly cdRef: ChangeDetectorRef) { }

    // tslint:disable-next-line: cyclomatic-complexity
    ngOnInit(): void {
        this.formGroup = this.formBuilder.group({
            sourceId: new FormControl(!!this.sourceData ? this.sourceData.sourceId : null),
            publisher: new FormControl(!!this.sourceData ? this.sourceData.publisher : null),
            city: new FormControl(!!this.sourceData ? this.sourceData.city : null),
            issuingJurisdiction: new FormControl(!!this.sourceData ? this.sourceData.issuingJurisdiction : null),
            country: new FormControl(!!this.sourceData ? this.sourceData.country : null),
            kindCode: new FormControl(!!this.sourceData ? this.sourceData.kindCode : null),
            title: new FormControl(!!this.sourceData ? this.sourceData.title : null),
            publication: new FormControl(!!this.sourceData ? this.sourceData.publication : null),
            classes: new FormControl(!!this.sourceData ? this.sourceData.classes : null),
            subClasses: new FormControl(!!this.sourceData ? this.sourceData.subClasses : null),
            reportIssued: new FormControl(!!this.sourceData && !!this.sourceData.reportIssued ? new Date(this.sourceData.reportIssued) : null),
            reportReceived: new FormControl(!!this.sourceData && !!this.sourceData.reportReceived ? new Date(this.sourceData.reportReceived) : null),
            description: new FormControl(!!this.sourceData ? this.sourceData.description : null),
            comments: new FormControl(!!this.sourceData ? this.sourceData.comments : null),
            officialNumber: new FormControl(!!this.sourceData ? this.sourceData.officialNumber : null),
            citation: new FormControl(!!this.sourceData ? this.sourceData.citation : null),
            applicationFiledDate: new FormControl(!!this.sourceData && !!this.sourceData.applicationFiledDate ? new Date(this.sourceData.applicationFiledDate) : null),
            publishedDate: new FormControl(!!this.sourceData && !!this.sourceData.publishedDate ? new Date(this.sourceData.publishedDate) : null),
            grantedDate: new FormControl(!!this.sourceData && !!this.sourceData.grantedDate ? new Date(this.sourceData.grantedDate) : null),
            priorityDate: new FormControl(!!this.sourceData && !!this.sourceData.priorityDate ? new Date(this.sourceData.priorityDate) : null),
            ptoCitedDate: new FormControl(!!this.sourceData && !!this.sourceData.ptoCitedDate ? new Date(this.sourceData.ptoCitedDate) : null),
            inventorName: new FormControl(!!this.sourceData ? this.sourceData.inventorName : null),
            abstract: new FormControl(!!this.sourceData ? this.sourceData.abstract : null),
            translationType: new FormControl(!!this.sourceData ? this.sourceData.translationType.key : null),
            referenceParts: new FormControl(!!this.sourceData ? this.sourceData.referenceParts : null),
            sourceType: new FormControl(!!this.sourceData ? this.sourceData.sourceType : null, [Validators.required])
        });
        if (!this.hasUpdatePermission && this.sourceData && this.sourceData.sourceId) {
            this.formGroup.disable();
        }
        this.selectedPriorArtType = this.priorArtType;
    }

    markAsPristine(): void {
        this.formGroup.markAsPristine();
    }

    getData(): any {
        return {
            sourceId: this.formGroup.value.sourceId,
            publisher: this.formGroup.value.publisher,
            city: this.formGroup.value.city,
            issuingJurisdiction: this.formGroup.value.issuingJurisdiction ? this.formGroup.value.issuingJurisdiction : null,
            country: this.formGroup.value.country ? this.formGroup.value.country : null,
            kindCode: this.formGroup.value.kindCode,
            title: this.formGroup.value.title,
            publication: this.formGroup.value.publication,
            classes: this.formGroup.value.classes,
            subClasses: this.formGroup.value.subClasses,
            reportIssued: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.reportIssued)),
            reportReceived: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.reportReceived)),
            description: this.formGroup.value.description,
            comments: this.formGroup.value.comments,
            officialNumber: this.formGroup.value.officialNumber,
            citation: this.formGroup.value.citation,
            applicationFiledDate: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.applicationFiledDate)),
            publishedDate: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.publishedDate)),
            grantedDate: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.grantedDate)),
            priorityDate: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.priorityDate)),
            ptoCitedDate: this.dateHelper.toLocal(this._toLocalDate(this.formGroup.value.ptoCitedDate)),
            inventorName: this.formGroup.value.inventorName,
            abstract: this.formGroup.value.abstract,
            translationType: this.formGroup.value.translationType,
            referenceParts: this.formGroup.value.referenceParts,
            sourceType: this.formGroup.value.sourceType ? this.formGroup.value.sourceType : null
        };
    }

    toggleSourceType(sourceType: PriorArtType): void {
        this.selectedPriorArtType = sourceType;
        if (this.selectedPriorArtType === PriorArtType.Ipo) {
            this.formGroup.controls.officialNumber.setValidators(Validators.required);
        } else {
            this.formGroup.controls.officialNumber.clearValidators();
        }
        if (this.selectedPriorArtType === PriorArtType.Literature) {
            this.formGroup.controls.title.setValidators(Validators.required);
        } else {
            this.formGroup.controls.title.clearValidators();
        }
        this.formGroup.controls.title.updateValueAndValidity();
        this.formGroup.controls.officialNumber.updateValueAndValidity();
    }

    launchSearch = (): void => {
        this.stateService.go('priorArt', {
            caseKey: this.stateService.params.caseKey,
            sourceId: this.stateService.params.sourceId || this.stateService.params.priorartId,
            showCloseButton: true
        });
    };

    generateDescription = (): void => {
        const description = ['', this.formGroup.value.inventorName, this.formGroup.value.title,
            this.formGroup.value.publishedDate ? this.localDatePipe.transform(this.formGroup.value.publishedDate, null) : null,
            this.formGroup.value.referenceParts, this.formGroup.value.publisher, this.formGroup.value.city, this.formGroup.value.country.value]
            .filter(_ => _ && _.trim() !== '')
            .join(', ');
        if (description !== this.formGroup.value.description) {
            this.formGroup.controls.description.setValue(description);
            this.formGroup.controls.description.markAsDirty();
        }
    };

    _toLocalDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), 0, 0, 0);
        }

        return null;
    }
}
