import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { ValidationError } from 'shared/component/forms/validation-error';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { FileLocationsItems } from './file-locations.model';

@Injectable({
    providedIn: 'root'
})
export class FileLocationsService {
    private readonly hasPendingChangesSubject = new BehaviorSubject<boolean>(false);
    private readonly hasErrorsSubject = new BehaviorSubject<boolean>(false);
    isAddAnotherChecked = new BehaviorSubject<boolean>(false);
    hasPendingChanges$ = this.hasPendingChangesSubject.asObservable();
    hasErrors$ = this.hasErrorsSubject.asObservable();

    states = {
        hasPendingChanges: undefined,
        hasErrors: undefined
    };
    constructor(readonly http: HttpClient) {
    }

    getFileLocations = (caseKey: number, queryParams: GridQueryParameters, showHistory?: boolean): Observable<Array<FileLocationsItems>> => {
        queryParams.filterEmpty = true;

        return this.http.get<Array<FileLocationsItems>>(`api/case/${caseKey}/fileLocations/${showHistory}`, {
            params: {
                params: JSON.stringify(queryParams)
            }
        });
    };

    getFileLocationForFilePart = (caseKey: number, queryParams: GridQueryParameters, filePartId?: number): Observable<Array<FileLocationsItems>> => {
        return this.http.get<Array<FileLocationsItems>>(`api/case/${caseKey}/fileLocations`, {
            params: {
                params: JSON.stringify(queryParams),
                filePartId: JSON.stringify(filePartId)
            }
        });
    };

    getCaseReference = (caseKey: number): Observable<string> => {
        return this.http.get<string>(`api/case/getCaseReference/${caseKey}`);
    };

    getColumnFilterData$ = (column, caseKey, otherFilters): Observable<any> => {
        return this.http
            .get(`api/case/${caseKey}/fileLocations/filterData/` + column.field, {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
    };

    getValidationErrors = (caseKey: number, currentRow: FileLocationsItems, changedRows: Array<FileLocationsItems>): Observable<Array<ValidationError>> => {
        return this.http.post<Array<ValidationError>>('api/case/fileLocations/validate', {
            caseKey,
            currentRow,
            changedRows
        });
    };

    formatFileLocation(value: FileLocationsItems): FileLocationsItems {
        if (value) {
            value.fileLocationId = (value.fileLocation && value.fileLocation.key) ? value.fileLocation.key : value.fileLocationId;
            value.fileLocation = (value.fileLocation && value.fileLocation.value) ? value.fileLocation.value : value.fileLocation;
            value.filePartId = !value.filePart ? null : (value.filePart && value.filePart.key) ? value.filePart.key : value.filePartId;
            value.filePart = (value.filePart && value.filePart.value) ? value.filePart.value : value.filePart;
            value.issuedById = !value.issuedBy ? null : (value.issuedBy && value.issuedBy.key) ? value.issuedBy.key : value.issuedById;
            value.issuedBy = (value.issuedBy && value.issuedBy.displayName) ? value.issuedBy.displayName : value.issuedBy;

            return value;
        }

        return null;
    }

    toLocalDate = (dateTime: Date, dateOnly?: boolean): Date => {

        return new Date(Date.UTC(dateTime.getFullYear(), dateTime.getMonth(), dateTime.getDate(), dateOnly ? 0 : dateTime.getHours(), dateOnly ? 0 : dateTime.getMinutes(), dateOnly ? 0 : dateTime.getSeconds()));
    };

    raisePendingChanges = (hasPendingChanges: boolean) => {
        if (hasPendingChanges !== this.states.hasPendingChanges) {
            this.states.hasPendingChanges = hasPendingChanges;
            this.hasPendingChangesSubject.next(hasPendingChanges);
        }
    };

    raiseHasErrors = (hasErrors: boolean) => {
        if (hasErrors !== this.states.hasErrors) {
            this.states.hasErrors = hasErrors;
            this.hasErrorsSubject.next(hasErrors);
        }
    };
}
