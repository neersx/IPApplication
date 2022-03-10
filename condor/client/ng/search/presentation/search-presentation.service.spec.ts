import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { SearchPresentationService } from './search-presentation.service';

describe('due date case search modal', () => {
    let service: SearchPresentationService;
    let httpMock: any;
    const availableColumns = [
        { id: '9_C', parentId: null, columnKey: null, columnDescription: 'Column9', groupKey: 23, groupDescription: 'Group 23', displayName: 'Column9', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '10_C', parentId: null, columnKey: 2, columnDescription: 'Column 10', groupKey: null, groupDescription: null, displayName: 'Column10', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '11_C', parentId: null, columnKey: 3, columnDescription: 'Column 5', groupKey: null, groupDescription: null, displayName: 'Column5', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '6_C', parentId: null, columnKey: 3, columnDescription: 'Column 6', groupKey: null, groupDescription: null, displayName: 'Column6', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '7_C', parentId: null, columnKey: 3, columnDescription: 'Column 7', groupKey: null, groupDescription: null, displayName: 'Column7', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '8_C', parentId: null, columnKey: 3, columnDescription: 'Column 8', groupKey: null, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false },
        { id: '-13_G', parentId: null, columnKey: 0, columnDescription: null, groupKey: -13, groupDescription: null, displayName: 'Column8', isGroup: false, sortDirection: '', hidden: false, freezeColumn: false, isDefault: false, procedureItemId: '', isFreezeColumnDisabled: false }
    ];

    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new SearchPresentationService(httpMock);
    });

    it('should create the service instance', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call the getAvailableColumns method', async(() => {
        httpMock.get.mockReturnValue(of(availableColumns));
        service.getAvailableColumns(1);
        expect(httpMock.get).toHaveBeenCalled();
        spyOn(httpMock, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the getSelectedColumns method', async(() => {
        httpMock.get.mockReturnValue(of(availableColumns));
        service.getSelectedColumns('1', 1);
        expect(httpMock.get).toHaveBeenCalledWith('api/search/presentation/selected/1/1');
        spyOn(httpMock, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));

    it('should call the getDueDateSavedSearch method', async(() => {
        service.getDueDateSavedSearch(1);
        expect(httpMock.get).toHaveBeenCalledWith('api/search/case/casesearch/builder/1');
        spyOn(httpMock, 'get').and.returnValue({
            subscribe: (response: any) => {
                expect(response).toBeDefined();
            }
        });
    }));
});