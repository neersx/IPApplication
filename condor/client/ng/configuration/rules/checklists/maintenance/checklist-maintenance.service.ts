import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
    providedIn: 'root'
})
export class ChecklistMaintenanceService {

    baseUrl = 'api/configuration/rules/checklist-configuration/';
    constructor(private readonly http: HttpClient) { }

    createChecklist(data: any): Observable<any> {

        return this.http.put(`${this.baseUrl}add`, this.buildCriteria(data));
    }

    private readonly buildCriteria = (criteria: any) => {
        if (criteria == null) {
            return undefined;
        }

        return {
            criteriaName: criteria.criteriaName,
            caseType: this.getKey(criteria, 'caseType', 'code'),
            caseCategory: this.getKey(criteria, 'caseCategory', 'code'),
            caseProgram: this.getKey(criteria, 'program', 'key'),
            jurisdiction: this.getKey(criteria, 'jurisdiction', 'code'),
            propertyType: this.getKey(criteria, 'propertyType', 'code'),
            subType: this.getKey(criteria, 'subType', 'code'),
            basis: this.getKey(criteria, 'basis', 'code'),
            office: this.getKey(criteria, 'office', 'key'),
            profile: this.getKey(criteria, 'profile', 'code'),
            checklist: this.getKey(criteria, 'checklist', 'key'),
            isProtected: criteria.isProtected,
            inUse: criteria.isInUse
        };
    };

    private readonly getKey = (searchCriteria: any, propertyName: string, key: string) => {
        return searchCriteria[propertyName] && searchCriteria[propertyName][key];
    };

}
