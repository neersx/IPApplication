import { Observable } from 'rxjs';

export class CaseSearchHelperServiceMock {
    getKeysFromTypeahead = jest.fn();
    buildStringFilterFromTypeahead = jest.fn();
    buildStringFilter = jest.fn();
    buildFromToValues = jest.fn();
    isFilterApplicable = jest.fn();
    getPeriodTypes = jest.fn();
    computeColumnsWidth = jest.fn();
    onActionComplete$ = new Observable();
}