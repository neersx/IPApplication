import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject, Observable } from 'rxjs';
import { SearchResultColumn } from 'search/results/search-results.model';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { AffectedCasesItems, BulkOperationType, CurrentAddress, RecordalStep, RecordalStepElement, RecordalStepElementForm, StepElements } from './affected-cases.model';
import { AddAffetcedRequestModel } from './model/affected-case.model';

@Injectable({
    providedIn: 'root'
})
export class AffectedCasesService {
    rowSelected$ = new BehaviorSubject<StepElements>(null);
    elementFormDataChanged$ = new BehaviorSubject<Array<RecordalStepElementForm>>(null);
    stepElementForm: Array<RecordalStepElementForm>;
    originalStepElements: Array<RecordalStepElement>;
    originalAffectedCases: Array<AffectedCasesItems>;
    updatedAffectedCases: Array<AffectedCasesItems>;
    currentAddressChange$ = new BehaviorSubject<RecordalStepElement>(null);
    constructor(private readonly http: HttpClient) { }

    setOriginalAffectedCases(data: any): void {
        this.originalAffectedCases = [];
        this.originalAffectedCases = data;
    }
    setAffectedcases(dataItem: any): void {
        const index = _.findIndex(this.updatedAffectedCases, (data: any) => {
            return data.rowKey === dataItem.rowKey;
        });

        if (index > -1) {
            this.updatedAffectedCases[index] = dataItem;

        } else {
            if (this.updatedAffectedCases) {
                this.updatedAffectedCases.push(dataItem);
            } else {
                this.updatedAffectedCases = [];
                this.updatedAffectedCases.push(dataItem);
            }
        }
    }

    setStepElementRowFormData(stepId: number, rowId: number, form: NgForm, formData: any): void {
        const existingFormData = _.find(this.stepElementForm, (data: RecordalStepElementForm) => {
            return rowId === data.rowId && data.stepId === stepId;
        });

        if (existingFormData) {
            existingFormData.form = form;
            existingFormData.formData = formData;
        } else {
            if (this.stepElementForm) {
                this.stepElementForm.push({ stepId, rowId, form, formData });
            } else {
                this.stepElementForm = [];
                this.stepElementForm.push({ stepId, rowId, form, formData });
            }
        }

        this.elementFormDataChanged$.next(this.stepElementForm);
    }

    updateOriginalRecordalElements(): Array<RecordalStepElement> {
        this.originalStepElements.forEach(stepElement => {
            const updatedFormData = _.find(this.stepElementForm, (data: RecordalStepElementForm) => {
                return stepElement.elementId === data.rowId && stepElement.id === data.stepId;
            });

            if (updatedFormData) {
                stepElement.status = rowStatus.editing;
                stepElement.namePicklist = Array.isArray(updatedFormData.formData.namePicklist) ?
                    updatedFormData.formData.namePicklist : [updatedFormData.formData.namePicklist];
                stepElement.addressPicklist = updatedFormData.formData.addressPicklist;
            }
        });
        this.elementFormDataChanged$.next(this.stepElementForm);

        return this.originalStepElements;
    }

    getCurrentAddressForName(element: RecordalStepElement, namePicklist: any): void {
        const currentAddressElement = this.originalStepElements.filter(ele =>
            ele.typeText.includes('CURRENT')
            && ele.typeText.includes('ADDRESS'));
        if (currentAddressElement.length > 0 && (element.typeText.includes('NEWNAME'))) {
            if (namePicklist != null
                && namePicklist.length === 1 && namePicklist[0]) {
                this.getCurrentAddress(namePicklist[0].key).subscribe(res => {
                    if (res) {
                        currentAddressElement.forEach(ele => {
                            if (ele.namePicklist === null || ele.namePicklist[0].key !== res.namePicklist.key) {
                                ele.namePicklist = [res.namePicklist];
                                ele.addressPicklist = ele.typeText.includes('STREET') ? res.streetAddressPicklist : ele.addressPicklist = res.postalAddressPicklist;
                                this.currentAddressChange$.next(ele);
                            }
                        });
                    }
                });
            } else {
                currentAddressElement.forEach(ele => {
                    if (ele.namePicklist !== null) {
                        ele.namePicklist = null;
                        ele.addressPicklist = null;
                        this.currentAddressChange$.next(ele);
                    }
                });
            }
        }
    }

    getStepElementRowFormData(stepId: number, rowId: number): RecordalStepElementForm {
        return _.find(this.stepElementForm, (data: any) => {

            return rowId === data.rowId && stepId === data.stepId;
        });
    }

    clearStepElementFormData(): void {
        this.stepElementForm = null;
        this.elementFormDataChanged$.next(null);
    }

    clearStepElementRowFormData(stepId: number, rowId?: number): void {
        if (this.stepElementForm && this.stepElementForm.length > 0) {
            if (rowId) {
                const index = this.stepElementForm.findIndex(x => { return x.rowId === rowId && x.stepId === stepId; });
                this.stepElementForm.splice(index, 1);
            } else {
                _.forEach(this.stepElementForm, (data) => {
                    const index = this.stepElementForm.findIndex(x => { return data && data.stepId === stepId; });
                    if (index > -1) {
                        this.stepElementForm.splice(index, 1);
                    }
                });
            }
            this.elementFormDataChanged$.next(this.stepElementForm);
        } else {
            this.elementFormDataChanged$.next(null);
        }
    }

    getAffectedCases(caseKey: number, queryParams: GridQueryParameters, filter: any = null): Observable<Array<AffectedCasesItems>> {
        return this.http.get<Array<AffectedCasesItems>>(`api/case/${caseKey}/affectedCases`, {
            params: {
                params: JSON.stringify(queryParams),
                filter: JSON.stringify(filter)
            }
        });
    }

    performBulkOperation(caseKey: number, selectedRowKeys: Array<string>, deSelectedRowKeys: Array<string>, isAllSelected: boolean, filterParams: any, operationType: BulkOperationType, clearCaseNameAgent: boolean): Observable<any> {
        const uri = `api/case/${caseKey}/` + operationType;

        return this.http.post(uri, {
            selectedRowKeys,
            deSelectedRowKeys,
            isAllSelected,
            filter: filterParams,
            clearCaseNameAgent
        });
    }

    getColumns$(caseKey: number): Observable<Array<SearchResultColumn>> {
        return this.http.get<Array<SearchResultColumn>>(`api/case/${caseKey}/affectedCasesColumns`);
    }

    getRecordalSteps(caseKey: number): Observable<Array<RecordalStep>> {
        return this.http.get<Array<RecordalStep>>(`api/case/${caseKey}/recordalSteps`);
    }

    getRecordalStepElements(caseKey: number, stepId: number, recordalType: number): Observable<Array<RecordalStepElement>> {
        return this.http.get<Array<RecordalStepElement>>(`api/case/${caseKey}/recordalStep/${stepId}/recordalType/${recordalType}`);
    }

    saveRecordalSteps(recordalSteps: RecordalStep): Observable<any> {
        return this.http.post('api/case/recordalSteps/save', recordalSteps);
    }

    getCurrentAddress(nameKey: number): Observable<CurrentAddress> {
        return this.http.get<CurrentAddress>(`api/case/recordalStep/getCurrentAddress/${nameKey}`);
    }

    validateAddAffectedCase(country: string, officialNo: string): Observable<[]> {
        return this.http.post<[]>('api/case/affectedCaseValidation', {
            country,
            officialNo
        });
    }

    submitAffectedCase(affectedCase: AddAffetcedRequestModel): Observable<any> {
        return this.http.post('api/case/recordalAffectedCase/save', affectedCase);
    }
}