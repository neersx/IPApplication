import { HttpParams } from '@angular/common/http';
import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { LinkType } from './priorart-model';
import { PriorArtSearch } from './priorart-search/priorart-search-model';
import { PriorArtService } from './priorart.service';

describe('priorart service', () => {
    'use strict';

    let service: PriorArtService;
    let httpClientSpy;
    let localeDatePipe;
    beforeEach(() => {
        localeDatePipe = { transform: jest.fn() };
        httpClientSpy = new HttpClientMock();
        service = new PriorArtService(httpClientSpy, localeDatePipe);
    });

    describe('getPriorArtData', () => {
        it('should pass correct encoded parameters', () => {
            service.getPriorArtData$(12345, 111);
            const parameters = {
                params: new HttpParams()
                    .set('sourceId', JSON.stringify(12345))
                    .set('caseKey', JSON.stringify(111))
            };
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/priorart/', parameters);
        });
    });

    describe('getPriorArtTranslations', () => {
        it('should pass correct encoded parameters', () => {
            service.getPriorArtTranslations$();
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/priorart/priorArtTranslations');
        });
    });

    describe('get Searched Data', () => {
        it('calls the correct API passing the parameters', () => {
            const input: PriorArtSearch = { officialNumber: '1234', country: '1', countryName: 'abc', kind: '' } as any;
            service.getSearchedData$(input);
            expect(httpClientSpy.post).toHaveBeenCalledWith('api/priorart/evidenceSearch', input);
        });
    });

    describe('save Prior Art', () => {
        it('calls save API passing the correct data', () => {
            const data = {
                createSource: {
                }
            };
            service.maintainPriorArt$(data, 1, 2);
            expect(httpClientSpy.post).toHaveBeenCalledWith('api/priorart/maintenance/1?priorArtType=2', data);
        });
    });

    describe('deletePriorArt', () => {
        it('calls delete API passing the correct data', () => {
            const priorArtId = 333;
            const parameters = {
                params: new HttpParams()
                    .set('priorArtId', JSON.stringify(priorArtId))
            };
            service.deletePriorArt$(priorArtId);
            expect(httpClientSpy.request).toHaveBeenCalledWith('delete', 'api/priorart/maintenance/delete', parameters);
        });
    });

    describe('getCitations', () => {
        it('calls the citation list api', () => {
            const input: PriorArtSearch = { officialNumber: '1234', country: '1', countryName: 'abc', kind: '' } as any;
            service.getCitations$(input, { skip: 0, take: 0 });
            expect(httpClientSpy.get).toHaveBeenCalled();
            expect(httpClientSpy.get.mock.calls[0][0]).toBe('api/priorart/citations/search');
        });
    });

    describe('getLinkedCases', () => {
        it('calls the linked cases api', () => {
            const input: PriorArtSearch = { officialNumber: '1234', country: '1', countryName: 'abc', kind: '' } as any;
            service.getLinkedCases$(input, { skip: 0, take: 0 });
            expect(httpClientSpy.get).toHaveBeenCalled();
            expect(httpClientSpy.get.mock.calls[0][0]).toBe('api/priorart/linkedCases/search');
        });
    });

    describe('runLinkedCasesFilterMetaSearch', () => {
        it('calls the API method to get the specified field filter data', () => {
            const lastSearch = { test: 'abcd' };
            (service as any)._lastCaseListSearch = lastSearch;
            service.runLinkedCasesFilterMetaSearch$('fieldName1234');
            httpClientSpy.get.mockReturnValue(of([]));
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/priorart/linkedCases/search/filterData/fieldName1234', {
                params: {
                    q: JSON.stringify(lastSearch)
                }
            });
        });
    });

    describe('formatDate', () => {
        it('strips out the time component', () => {
            const enteredDate = new Date();
            const date = service.formatDate(enteredDate);

            expect(date.getDate()).toEqual(enteredDate.getDate());
            expect(date.getMinutes()).toEqual(0);
        });
    });

    describe('createLinkedCases', () => {
        it('calls the create linked cases api', () => {
            const request = { sourceDocumentId: 9876, caseKey: -555 };
            service.createLinkedCases$(request);
            expect(httpClientSpy.post).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.post.mock.calls[0][0]).toBe('api/priorart/linkedCases/create');
            expect(httpClientSpy.post.mock.calls[0][1]).toBe(request);
        });
    });

    describe('getUpdateFirstLinkedCaseViewData', () => {
        it('calls the update first linked cases view data api', () => {
            const request = { sourceDocumentId: 9876, caseKey: -555 };
            service.getUpdateFirstLinkedCaseViewData$(request);
            expect(httpClientSpy.post).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.post.mock.calls[0][0]).toBe('api/priorart/linkedCases/updateFirstLinkedCaseViewData');
            expect(httpClientSpy.post.mock.calls[0][1]).toBe(request);
        });
    });

    describe('updateFirstLinkedCaseViewData', () => {
        it('calls the update first linked cases api', () => {
            const request = { sourceDocumentId: 9876, caseKey: -555 };
            service.updateFirstLinkedCaseViewData$(request);
            expect(httpClientSpy.post).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.post.mock.calls[0][0]).toBe('api/priorart/linkedCases/updateFirstLinkedCase');
            expect(httpClientSpy.post.mock.calls[0][1]).toBe(request);
        });
    });

    describe('removeLinkedCases', () => {
        it('calls the remove linked cases api', () => {
            const queryParams: GridQueryParameters = { skip: 0, take: 20, filters: [{ field: 'familyKey', value: 'Abc-Fam', operator: 'eq'}] };
            const request = { sourceDocumentId: 9876, caseKeys: [-555, 888] };
            service.removeLinkedCases$(request, queryParams);
            expect(httpClientSpy.post).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.post.mock.calls[0][0]).toBe('api/priorart/linkedCases/remove');
            expect(httpClientSpy.post.mock.calls[0][1]).toEqual(expect.objectContaining({ request, queryParams }));
        });
    });

    describe('getFamilyCaseList', () => {
        it('calls the family case list api', () => {
            service.getFamilyCaseList$(11111111, { skip: 0, take: 0 });
            expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.get.mock.calls[0][0]).toBe('api/priorart/familyCaselist/search/11111111');
        });
    });

    describe('getLinkedNameList', () => {
        it('calls the linked name list api', () => {
            service.getLinkedNameList$(22222222, { skip: 0, take: 0 });
            expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.get.mock.calls[0][0]).toBe('api/priorart/linkedNames/search/22222222');
        });
    });

    describe('getFamilyCaseListDetails', () => {
        it('calls the family case list details api', () => {
            const searchOptions = { isFamily: 1, id: 129840, description: 'big family' };
            service.getFamilyCaseListDetails$(searchOptions, { skip: 0, take: 0 });
            expect(httpClientSpy.get).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.get.mock.calls[0][0]).toBe('api/priorart/family-case-list-details');
            expect(JSON.parse(httpClientSpy.get.mock.calls[0][1].params.updates[0].value)).toEqual(searchOptions);
        });
    });

    describe('removing associations', () => {
        const priorArtId = -98765;
        const linkId = 54321;
        it('uses the correct api for family', () => {
            service.removeAssociation$(LinkType.Family, priorArtId, linkId);
            expect(httpClientSpy.delete).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.delete.mock.calls[0][0]).toBe('api/priorart/-98765/family/54321');
        });
        it('uses the correct api for case list', () => {
            service.removeAssociation$(LinkType.CaseList, priorArtId, linkId);
            expect(httpClientSpy.delete).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.delete.mock.calls[0][0]).toBe('api/priorart/-98765/caseList/54321');
        });
        it('uses the correct api for name', () => {
            service.removeAssociation$(LinkType.Name, priorArtId, linkId);
            expect(httpClientSpy.delete).toHaveBeenCalledTimes(1);
            expect(httpClientSpy.delete.mock.calls[0][0]).toBe('api/priorart/-98765/name/54321');
        });
    });
});