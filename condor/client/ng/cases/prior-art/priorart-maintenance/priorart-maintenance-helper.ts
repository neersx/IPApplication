import { Injectable } from '@angular/core';
import { PriorArtType } from '../priorart-model';

@Injectable({
    providedIn: 'root'
})
export class PriorartMaintenanceHelper {
    buildDescription(sourceDocumentData: any): string {
        let formattedDesc: string;
        if (!!sourceDocumentData.description) {
            formattedDesc = '(' + sourceDocumentData.description + ')';
            if (sourceDocumentData.description.length > 200) {
                formattedDesc = '(' + sourceDocumentData.description.substr(0, 200) + '...)';
            }
        }

        if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Source || this.getPriorArtType(sourceDocumentData) === PriorArtType.NewSource) {
            return this._buildSourceDescription(sourceDocumentData, formattedDesc);
        } else if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Ipo) {
            return this._buildIpoDescription(sourceDocumentData);
        } else if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Literature) {
            return this._buildLiteratureDescription(sourceDocumentData);
        }
    }

    _buildSourceDescription(sourceDocumentData: any, formattedDesc: string): string {
        return sourceDocumentData.sourceType.name +
            (!!sourceDocumentData.issuingJurisdiction && !!sourceDocumentData.issuingJurisdiction.key ? ' - ' + sourceDocumentData.issuingJurisdiction.key : '') +
            (!!sourceDocumentData.description ? ' - ' + formattedDesc + '' : '');
    }

    _buildIpoDescription(sourceDocumentData: any): string {
        const title = sourceDocumentData.title && sourceDocumentData.title.length > 200 ? sourceDocumentData.title.substr(0, 200) + '...' : sourceDocumentData.title;

        return (sourceDocumentData.country.key ? sourceDocumentData.country.key : '') +
            (!!sourceDocumentData.officialNumber ? (sourceDocumentData.country.key ? ' - ' : '') + sourceDocumentData.officialNumber : '') +
            (!!title ? ' - ' + title : '');
    }

    _buildLiteratureDescription(sourceDocumentData: any): string {
        let formattedDesc = sourceDocumentData.description;
        if (sourceDocumentData.description && sourceDocumentData.description.length > 200) {
            formattedDesc = sourceDocumentData.description.substr(0, 200) + '...';
        }
        const newDescription = !!sourceDocumentData.description ? formattedDesc :
            [sourceDocumentData.inventorName, sourceDocumentData.title, sourceDocumentData.publisher, sourceDocumentData.city, sourceDocumentData.country && sourceDocumentData.country.key].filter(_ => _).join(', ');

        return newDescription.length > 200 ? newDescription.substr(0, 200) + '...' : newDescription;
    }

    buildShortDescription(sourceDocumentData: any): string {
        let shortDescription: string;
        if (!!sourceDocumentData.description) {
            shortDescription = sourceDocumentData.description;
            if (shortDescription.length > 20) {
                shortDescription = shortDescription.substr(0, 20) + '...';
            }
        }
        let prefix: string;
        const title = sourceDocumentData.title && sourceDocumentData.title.length > 200 ? sourceDocumentData.title.substr(0, 200) + '...' : sourceDocumentData.title;
        if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Source || this.getPriorArtType(sourceDocumentData) === PriorArtType.NewSource) {
            prefix = [sourceDocumentData.sourceType && sourceDocumentData.sourceType.name, sourceDocumentData.issuingJurisdiction && sourceDocumentData.issuingJurisdiction.key, shortDescription ? '(' + shortDescription + ')' : ''].filter(_ => _).join(' - ');
        } else if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Ipo) {
            prefix = [sourceDocumentData.officialNumber, sourceDocumentData.country.key, sourceDocumentData.kindCode].filter(_ => _).join(' - ');
        } else if (this.getPriorArtType(sourceDocumentData) === PriorArtType.Literature) {
            prefix = sourceDocumentData.description ? shortDescription : [sourceDocumentData.inventorName, title, sourceDocumentData.publisher, sourceDocumentData.city, sourceDocumentData.country && sourceDocumentData.country.key].filter(_ => _).join(', ');
        }

        return prefix && prefix.length > 50 ? prefix.substr(0, 50) + '...' : prefix;
    }

    getPriorArtType = (sourceDocumentData: any): PriorArtType => {
        if (!sourceDocumentData) {
            return PriorArtType.NewSource;
        }
        if (sourceDocumentData.isSourceDocument && !sourceDocumentData.isIpDocument) {
            return PriorArtType.Source;
        } else if (!sourceDocumentData.isSourceDocument && !!sourceDocumentData.isIpDocument) {
            return PriorArtType.Ipo;
        } else if (!sourceDocumentData.isSourceDocument && !sourceDocumentData.isIpDocument) {
            return PriorArtType.Literature;
        }
    };

    static openMaintenance(dataItem: any, caseKey?: number): void {
        const url = `#/reference-management?priorartId=${dataItem.id}` + (dataItem.isCited && caseKey ? `&caseKey=${caseKey}` : '');
        window.open(url, '_blank');
    }
}
