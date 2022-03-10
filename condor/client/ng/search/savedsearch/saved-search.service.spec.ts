import { async } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { SaveOperationType } from './saved-search.model';
import { SavedSearchService } from './saved-search.service';

describe('due date case search modal', () => {
    let service: SavedSearchService;
    let httpMock: any;

    beforeEach(() => {
        httpMock = new HttpClientMock();
        service = new SavedSearchService(httpMock);
    });

    it('should create the service instance', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should save new search', async(() => {
        const response = {
            success: true
        };
        const saveSearchEntity = {
            searchName: 'c.formData.searchName',
            description: 'c.formData.description',
            groupKey: null,
            isPublic: false,
            searchFilter: null,
            selectedColumns: [],
            updatePresentation: false
        };
        httpMock.post.mockReturnValue(of(response));

        service.saveSearch(saveSearchEntity, SaveOperationType.Add, 2, { baseApiRoute: 'api/search/case/' } as any);
        expect(httpMock.post).toHaveBeenCalledWith('api/search/case/add/', saveSearchEntity);
        spyOn(httpMock, 'post').and.returnValue({
            subscribe: (res: any) => {
                expect(res).toBeDefined();
            }
        });
    }));

    it('should update search', async(() => {
        const response = {
            success: true
        };
        const saveSearchEntity = {
            searchName: 'c.formData.searchName',
            description: 'c.formData.description',
            groupKey: null,
            isPublic: false,
            searchFilter: null,
            selectedColumns: [],
            updatePresentation: false
        };
        httpMock.put.mockReturnValue(of(response));

        service.saveSearch(saveSearchEntity, SaveOperationType.Update, 2, { baseApiRoute: 'api/search/case/' } as any);
        expect(httpMock.put).toHaveBeenCalledWith('api/search/case/update/' + '2', saveSearchEntity);
        spyOn(httpMock, 'put').and.returnValue({
            subscribe: (res: any) => {
                expect(res).toBeDefined();
            }
        });
    }));

    it('should get saved search details', async(() => {
        const response = {
            success: true
        };
        httpMock.get.mockReturnValue(of(response));

        service.getDetails$(2, { baseApiRoute: 'api/search/case/' } as any);
        expect(httpMock.get).toHaveBeenCalledWith('api/search/case/get/' + '2');
        spyOn(httpMock, 'get').and.returnValue({
            subscribe: (res: any) => {
                expect(res).toBeDefined();
            }
        });
    }));

});