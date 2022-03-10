import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/angular';
import * as _ from 'underscore';
import { PriorArtType } from './priorart-model';

@Component({
    selector: 'ipx-priorart',
    templateUrl: 'priorart.component.html',
    styleUrls: ['./priorart.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class PriorArtComponent implements OnInit {
    caseKey: number;
    sourceId: number;
    sourceDocumentData: any;
    caseName: String;
    priorArtSourceTableCodes: any;
    sourceName: String;
    isLoaded: boolean | false;
    isIpDocument: boolean | false;
    isSourceDocument: boolean | false;
    showCloseButton: boolean | false;
    @Input() translationsList: any = {};

    @Input() priorArtData: any;
    @Input() stateParams: any;
    constructor(private readonly cdRef: ChangeDetectorRef, private readonly stateService: StateService) {
    }

    isSourceType = (): boolean => {
        if (this.getPriorArtType() === PriorArtType.Source || this.getPriorArtType() === PriorArtType.NewSource) {
            return true;
        }

        return false;
    };

    ngOnInit(): void {
        this.sourceId = this.stateParams.sourceId;
        this.caseKey = this.stateParams.caseKey;
        this.showCloseButton = this.stateParams.showCloseButton;
        if (this.priorArtData) {
            this.isLoaded = true;
            this.sourceDocumentData = this.priorArtData.sourceDocumentData;
            if (this.sourceDocumentData) {
                this.setDescription();

                this.isIpDocument = this.sourceDocumentData.isIpDocument;
                this.isSourceDocument = this.sourceDocumentData.isSourceDocument;
            }
            this.caseName = this.priorArtData.caseIrn;
            this.priorArtSourceTableCodes = this.priorArtData.priorArtSourceTableCodes;

            this.cdRef.detectChanges();
        }
    }

    setDescription = (): void => {
        let formattedDesc: string;
        formattedDesc = '(' + this.sourceDocumentData.description + ')';
        if (this.sourceDocumentData.description && this.sourceDocumentData.description.length > 200) {
            formattedDesc = '(' + this.sourceDocumentData.description.substr(0, 200) + '...)';
        }
        const title = this.sourceDocumentData.title && this.sourceDocumentData.title.length > 100 ? this.sourceDocumentData.title.substr(0, 100) + '...' : this.sourceDocumentData.title;
        if (this.getPriorArtType() === PriorArtType.Source || this.getPriorArtType() === PriorArtType.NewSource) {
            this.sourceName = this.priorArtData.sourceDocumentData ? this.priorArtData.sourceDocumentData.sourceType.name + ' - ' + this.priorArtData.sourceDocumentData.searchDescription : '';
        } else if (this.getPriorArtType() === PriorArtType.Ipo) {
            this.sourceName = (this.sourceDocumentData.country.key ? this.sourceDocumentData.country.key : '') +
                (!!this.sourceDocumentData.officialNumber ? (this.sourceDocumentData.country.key ? ' - ' : '') + this.sourceDocumentData.officialNumber : '') +
                (!!title ? ' - ' + title : '');
        } else if (this.getPriorArtType() === PriorArtType.Literature) {
            formattedDesc = this.sourceDocumentData.description;
            if (this.sourceDocumentData.description && this.sourceDocumentData.description.length > 200) {
                formattedDesc = this.sourceDocumentData.description.substr(0, 200) + '...';
            }
            this.sourceName = !!this.sourceDocumentData.description ? formattedDesc :
                [this.sourceDocumentData.inventorName, this.sourceDocumentData.title, this.sourceDocumentData.publisher, this.sourceDocumentData.city, this.sourceDocumentData.country && this.sourceDocumentData.country.key].filter(val => val).join(', ');

            if (this.sourceName.length > 200) {
                this.sourceName = this.sourceName.substr(0, 200) + '...';
            }
        }
    };

    getPriorArtType = (): PriorArtType => {
        if (!this.priorArtData.sourceDocumentData) {
            return PriorArtType.NewSource;
        }
        if (this.priorArtData.sourceDocumentData.isSourceDocument && !this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Source;
        } else if (!this.priorArtData.sourceDocumentData.isSourceDocument && !!this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Ipo;
        } else if (!this.priorArtData.sourceDocumentData.isSourceDocument && !this.priorArtData.sourceDocumentData.isIpDocument) {
            return PriorArtType.Literature;
        }
    };

    close = (): void => {
        this.stateService.go('referenceManagement', {
            caseKey: this.stateParams.caseKey,
            priorartId: this.stateParams.priorartId || this.stateParams.sourceId,
            goToStep: 2
        });
    };
}