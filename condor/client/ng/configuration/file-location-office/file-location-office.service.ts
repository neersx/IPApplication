import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { FileLocationOfficeItems } from './file-location-office.model';
@Injectable()
export class FileLocationOfficeService {
    constructor(private readonly http: HttpClient) {
    }
    url = 'api/configuration/file-location-office';
    navigationOptions: any;

    getFileLocationOffices = (queryParams: GridQueryParameters): Observable<Array<FileLocationOfficeItems>> => {

        return this.http.get<Array<FileLocationOfficeItems>>(this.url, {
            params: {
                params: JSON.stringify(queryParams)
            }
        });
    };

    saveFileLocationOffice = (items: Array<FileLocationOfficeItems>): Observable<any> => {

        return this.http.post(this.url, { rows: items });
    };
}
