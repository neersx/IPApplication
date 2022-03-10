import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { LocaleDatePipe } from 'shared/pipes/locale-date.pipe';
import { DateFunctions } from 'shared/utilities/date-functions';
import * as _ from 'underscore';
import { LinkType, PriorArtSaveModel } from './priorart-model';
import { PriorArtSearch, PriorArtSearchResult } from './priorart-search/priorart-search-model';

@Injectable()
export class PriorArtService {

    constructor(private readonly http: HttpClient,
        private readonly localDatePipe: LocaleDatePipe) {
    }

    hasPendingChanges$ = new BehaviorSubject<boolean>(false);
    hasUpdatedAssociations$ = new BehaviorSubject<boolean>(false);

    getPriorArtData$(sourceId: Number, caseKey: Number): Observable<any> {
        return this.http.get('api/priorart/', {
            params: new HttpParams()
                .set('sourceId', JSON.stringify(sourceId))
                .set('caseKey', JSON.stringify(caseKey))
        });
    }

    getSearchedData$(request: PriorArtSearch, queryParams: any = null): Observable<any> {
        return this.http.post('api/priorart/evidenceSearch', request);
    }

    getPriorArtTranslations$(): Observable<any> {
        return this.http.get('api/priorart/priorArtTranslations');
    }

    importCase$(data: PriorArtSaveModel): Observable<any> {
        return this.http.post('api/priorart/import/fromcaseevidencefinder', data);
    }

    importIPOne$(data: PriorArtSaveModel): Observable<any> {
        return this.http.post('api/priorart/import/fromIpOneDataDocumentFinder', data);
    }

    citeInprotechPriorArt$(request: PriorArtSearchResult, caseKey: Number): Observable<any> {
        return this.http.post('api/priorart/includeinsourcedocument', request, {
            params: new HttpParams()
                .set('caseKey', JSON.stringify(caseKey))
        });
    }

    saveInprotechPriorArt$(request: PriorArtSearchResult): Observable<any> {
        return this.http.post('api/priorart/editexisting', request);
    }

    createInprotechPriorArt$(request: PriorArtSearchResult): Observable<any> {
        return this.http.post('api/priorart/create', request);
    }

    existingPriorArt$(countryCode: string, officialNumber: string, kindCode: string): Observable<any> {
        return this.http.get('api/priorart/exists', {
            params: new HttpParams()
                .set('countryCode', countryCode)
                .set('officialNumber', officialNumber)
                .set('kindCode', kindCode)
        });
    }

    existingLiterature$(description: string, name: string, title: string, refDocumentParts: string, publisher: string, city: string, countryCode: string): Observable<any> {
        return this.http.get('api/priorart/literatureexists', {
            params: new HttpParams()
                .set('description', description)
                .set('name', name)
                .set('title', title)
                .set('refDocumentParts', refDocumentParts)
                .set('publisher', publisher)
                .set('city', city)
                .set('countryCode', countryCode)
        });
    }

    maintainPriorArt$(data: any, caseKey: number, selectedPriorArtType: number): Observable<any> {
        // tslint:disable-next-line: strict-boolean-expressions
        return this.http.post(`api/priorart/maintenance/${caseKey || ''}?priorArtType=${selectedPriorArtType}`, data);
    }

    deletePriorArt$(priorArtId: Number): Observable<any> {
        return this.http.request('delete', 'api/priorart/maintenance/delete', {
            params: new HttpParams()
                .set('priorArtId', JSON.stringify(priorArtId))
        });
    }

    deleteCitation$(searchPriorArtId: Number, citedPriorArtId: Number): Observable<any> {
        return this.http.request('delete', 'api/priorart/maintenance/deletecitation', {
            params: new HttpParams()
                .set('searchPriorArtId', JSON.stringify(searchPriorArtId))
                .set('citedPriorArtId', JSON.stringify(citedPriorArtId))
        });
    }

    citeSourceDocument$(sourceId: Number, priorArtId?: Number, caseId?: Number): Observable<any> {
        return this.http.post('api/priorart/report-citation', { sourceId: +sourceId, priorArtId, caseId });
    }

    getCitations$(request: PriorArtSearch, queryParams: any): Observable<any> {
        return this.http.get('api/priorart/citations/search', {
            params: new HttpParams()
                .set('args', JSON.stringify(request))
                .set('params', JSON.stringify(queryParams))
        });
    }

    getLinkedCases$(request: PriorArtSearch, queryParams: any): Observable<any> {
        this._lastCaseListSearch = request;

        return this.http.get('api/priorart/linkedCases/search', {
            params: new HttpParams()
                .set('args', JSON.stringify(request))
                .set('params', JSON.stringify(queryParams))
        });
    }

    getFamilyCaseList$(priorArtId: Number, queryParams: any): Observable<any> {
        return this.http.get('api/priorart/familyCaselist/search/' + priorArtId, {
            params: new HttpParams()
                .set('params', JSON.stringify(queryParams))
        });
    }

    getLinkedNameList$(priorArtId: Number, queryParams: any): Observable<any> {
        return this.http.get('api/priorart/linkedNames/search/'  + priorArtId, {
            params: new HttpParams()
                .set('params', JSON.stringify(queryParams))
        });
    }

    getFamilyCaseListDetails$(searchOptions: any, queryParams: any): Observable<any> {
        return this.http.get('api/priorart/family-case-list-details', {
            params: new HttpParams()
                .set('searchOptions', JSON.stringify(searchOptions))
                .set('params', JSON.stringify(queryParams))
        });
    }

    private _lastCaseListSearch;

    runLinkedCasesFilterMetaSearch$ = (columnField: string): Observable<any> => {
        return this.http.get<Array<any>>(`api/priorart/linkedCases/search/filterData/${columnField}`, {
            params: { q: JSON.stringify(this._lastCaseListSearch) }
        }).pipe(map((res) => {
            switch (columnField) {
                case 'dateUpdated':
                    return _.map(res, (r) => {
                        if (!r.description) {
                            return { description: '', code: 'null' };
                        }
                        const key = new Date(r.description);

                        return { description: this.localDatePipe.transform(key, null), code: DateFunctions.toLocalDate(key, true).toISOString() };
                    });
                default: return res;
            }
        }));
    };

    createLinkedCases$(request: any): Observable<any> {
        return this.http.post('api/priorart/linkedCases/create', request);
    }

    getUpdateFirstLinkedCaseViewData$(request: any): Observable<any> {
        return this.http.post('api/priorart/linkedCases/updateFirstLinkedCaseViewData', request);
    }

    updateFirstLinkedCaseViewData$(request: any): Observable<any> {
        return this.http.post('api/priorart/linkedCases/updateFirstLinkedCase', request);
    }

    updatePriorArtStatus$(request: any, queryParams: GridQueryParameters): Observable<any> {
        return this.http.post('api/priorart/linkedCases/update-status', {request, queryParams});
    }

    removeLinkedCases$(request: any, queryParams: GridQueryParameters): Observable<any> {
        return this.http.post('api/priorart/linkedCases/remove', { request, queryParams });
    }

    removeAssociation$(linkType: LinkType, priorArtId: number, linkId: number): Observable<any> {
        const baseUrl = 'api/priorart/' + priorArtId + '/';
        if (linkType === LinkType.Family) {
            return this.http.delete(baseUrl + 'family/' + linkId);
        } else if (linkType === LinkType.CaseList) {
            return this.http.delete(baseUrl + 'caseList/' + linkId);
        } else if (linkType === LinkType.Name) {
            return this.http.delete(baseUrl + 'name/' + linkId);
        }
    }

    formatDate(dateTime: Date): Date {
        if (dateTime instanceof Date) {
            return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate()));
        }

        return null;
    }
}