import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { KnownNameTypes } from 'names/knownnametypes';
import { NameFilteredPicklistScope } from 'search/case/case-search-topics/name-filtered-picklist-scope';
import * as _ from 'underscore';
import { EditAttributeEnum, ElementTypeEnum } from '../affected-cases.model';
import { AffectedCasesService } from '../affected-cases.service';

@Component({
    selector: 'ipx-recordal-step-elements-controls',
    templateUrl: './recordal-step-elements-controls.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class RecordalStepElementControlsComponent implements OnInit {

    @Input() dataItem: any;
    @Input() rowId: number;
    @Input() recordalType: number;
    @Input() isAssignedStep: boolean;
    @Input() isHosted: boolean;
    @ViewChild('ngForm', { static: true }) form: NgForm;
    sendToNameExtendQuery: any;
    namePickListExternalScope: NameFilteredPicklistScope;
    ownerPickListExternalScope: NameFilteredPicklistScope;
    initFormData: any = {
        namePicklist: {},
        addressPicklist: {}
    };
    isRevertDisabled = true;
    get ElementTypeEnum(): typeof ElementTypeEnum {
        return ElementTypeEnum;
    }
    get EditAttributeEnum(): typeof EditAttributeEnum {
        return EditAttributeEnum;
    }

    constructor(private readonly service: AffectedCasesService,
        private readonly cdref: ChangeDetectorRef,
        private readonly knownNameTypes: KnownNameTypes,
        private readonly translate: TranslateService) {
        this.sendToNameExtendQuery = this.sendToName.bind(this);
    }

    formData: any = { ...this.initFormData };

    ngOnInit(): void {
        this.prepareFormData();
        this.namePickListExternalScope = new NameFilteredPicklistScope(
            this.dataItem.nameType,
            this.dataItem.nameTypeValue,
            false
        );
        this.ownerPickListExternalScope = new NameFilteredPicklistScope(
            this.knownNameTypes.Owner,
            this.translate.instant('picklist.owner'),
            false
        );
    }

    onModelChange = (value, rowId, type): any => {
        if (type === 'NAME') {
            this.formData.addressPicklist = null;
        }
        this.service.setStepElementRowFormData(this.dataItem.id, rowId, this.form, this.formData);
        this.sendToName.bind(this);
        this.isRevertDisabled = false;
        this.service.getCurrentAddressForName(this.dataItem, value);
    };

    private readonly prepareFormData = (isRevert = false): void => {
        const form = this.service.getStepElementRowFormData(this.dataItem.id, this.rowId);
        if (form && !isRevert) {
            this.formData = form.formData;
            this.isRevertDisabled = false;

            return;
        }
        if (this.dataItem.namePicklist) {
            this.formData.namePicklist = this.dataItem.nameType === this.knownNameTypes.Owner && this.dataItem.type === ElementTypeEnum.Name
                ? this.dataItem.namePicklist
                : this.dataItem.namePicklist[0];
        }
        this.formData.addressPicklist = this.dataItem.addressPicklist;
        this.isRevertDisabled = true;
    };

    disableAddress = (): boolean => {
        return this.isAssignedStep || (this.dataItem.typeText.includes('CURRENT') && this.dataItem.typeText.includes('ADDRESS'));
    };

    revert = (event: any, rowId: number): void => {
        this.markFormPristine(this.form);
        this.service.clearStepElementRowFormData(this.dataItem.id, rowId);
        this.service.getRecordalStepElements(this.dataItem.caseId, this.dataItem.id, this.recordalType).subscribe(res => {
            if (res && res.length > 0) {
                const form = _.filter(res, (data: any) => {
                    return rowId === data.elementId && data.id === this.dataItem.id;
                });
                if (form[0].namePicklist) {
                    this.formData.namePicklist = this.dataItem.nameType === this.knownNameTypes.Owner && this.dataItem.type === ElementTypeEnum.Name
                        ? form[0].namePicklist
                        : form[0].namePicklist[0];
                } else {
                    this.formData.namePicklist = form[0].namePicklist;
                }
                this.formData.addressPicklist = form[0].addressPicklist;
                this.isRevertDisabled = true;
                this.service.getCurrentAddressForName(this.dataItem, this.formData.namePicklist);
                this.cdref.detectChanges();
            }
        });
    };

    private readonly markFormPristine = (form: NgForm): void => {
        Object.keys(form.controls).forEach(control => {
            form.controls[control].markAsPristine();
        });
    };

    private sendToName(query: any): void {
        const extended = _.extend({}, query, {
            associatedNameId: this.formData.namePicklist ? this.formData.namePicklist.key : null
        });

        return extended;
    }
}