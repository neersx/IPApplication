import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable()
export class KeepOnTopNotesViewService {

    constructor(private readonly http: HttpClient) { }

    getKotForCaseView(id: string, program: KotViewProgramEnum, apiFor: KotViewForEnum = KotViewForEnum.Case): Observable<any> {
        if (apiFor === KotViewForEnum.Name) {
            return this.http.get('api/keepontopnotes/name/' + id + '/' + program);
        }

        return this.http.get('api/keepontopnotes/' + id + '/' + program);
    }
}

export enum KotViewForEnum {
    Case = 'Case',
    Name = 'Name'
}

export enum KotViewProgramEnum {
    Case = 'Case',
    Name = 'Name',
    Time = 'Time',
    TaskPlanner = 'TaskPlanner'
}