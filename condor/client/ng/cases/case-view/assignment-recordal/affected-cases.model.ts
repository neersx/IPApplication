'use strict';
import { NgForm } from '@angular/forms';

export class AffectedCasesItems {
    rowKey: string;
    caseRef: string;
    jurisdiction: any;
    officialNo: string;
    changeOfAddress?: boolean;
    changeOfOwner?: boolean;
    currentOwner?: any;
    foreignAgent?: string;
}

export class RecordalStep {
    caseId: number;
    id: number;
    stepId: number;
    stepName: string;
    recordalType: RecordalType;
    modifiedDate: any;
    isAssigned?: boolean;
    selected?: boolean;
    status?: string;
    caseRecordalStepElements: Array<RecordalStepElement>;
}

export class StepElements {
    stepId: number;
    recordalType?: number;
    recordalStepElement?: Array<RecordalStepElement>;
}

export class RecordalStepElement {
    caseId: number;
    id: number;
    stepId: number;
    elementId: number;
    element: string;
    label: string;
    value?: string;
    otherValue?: string;
    namePicklist: Array<any>;
    addressPicklist?: any;
    status?: string;
    nameType?: string;
    nameTypeValue?: string;
    maxNamesAllowed?: number;
    typeText: string;
}

export class RecordalStepElementForm {
    stepId: number;
    rowId: number;
    form?: NgForm;
    formData: any;
}

export class RecordalType {
    key: number;
    value: string;
}

export class RecordalStepsRequest {
    caseId: number;
    caseRecordalSteps: Array<RecordalStep>;
}

export class CurrentAddress {
    namePicklist: any;
    streetAddressPicklist?: any;
    postalAddressPicklist?: any;
}

export enum ElementTypeEnum {
    Name = 'name',
    PostalAddress = 'postalAddress',
    StreetAddress = 'streetAddress'
}

export enum AffectedCaseStatusEnum {
    Filed = 'Filed',
    Recorded = 'Recorded',
    Rejected = 'Rejected',
    NotFiled = 'Not Yet Filed'
}

export enum BulkOperationType {
    DeleteAffectedCases = 'DeleteAffectedCases',
    ClearAffectedCaseAgent = 'ClearAffectedCaseAgent'
}

export enum EditAttributeEnum {
    Mandatory = 'MAN',
    Display = 'DIS'
}

export enum RecordalRequestType {
    Request = 'Request',
    Apply = 'Apply',
    Reject = 'Reject'
}

export enum StepType {
    NextSteps = 'NextSteps',
    AllSteps = 'AllSteps'
}

export class RecordalRequest {
    caseId: number;
    selectedRowKeys: Array<string>;
    deSelectedRowKeys: Array<string>;
    isAllSelected: boolean;
    requestType: RecordalRequestType;
    filter: any;
}