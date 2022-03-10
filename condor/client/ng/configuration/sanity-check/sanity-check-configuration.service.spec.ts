import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { SanityCheckConfigurationService } from './sanity-check-configuration.service';

describe('Service: SanityCheckConfiguration', () => {
  let service: SanityCheckConfigurationService;
  let httpMock: HttpClientMock;
  let navService: GridNavigationServiceMock;

  beforeEach(() => {
    httpMock = new HttpClientMock();
    navService = new GridNavigationServiceMock();
    service = new SanityCheckConfigurationService(httpMock as any, navService as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('getViewData', () => {
    service.getViewData$('case');
    expect(httpMock.get).toHaveBeenCalledWith('api/configuration/sanity-check/view-data/case');
  });

  it('search', done => {
    const model = { a: 'z', b: 'y' };
    const queryParams = { k: 1, l: 3 };
    // tslint:disable-next-line: no-empty
    httpMock.get.mockReturnValue({ pipe: (args: any) => { return { subscribe: (arg: any) => { arg(); } }; } });
    service.search$('case', model, queryParams)
      .subscribe(() => {
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/sanity-check/case/search', {
          params: { criteria: JSON.stringify(model), params: JSON.stringify(queryParams) }
        });
        expect(navService.setNavigationData).toHaveBeenCalled();
        expect(navService.setNavigationData.mock.calls[0][0].matchType).toEqual('case');
        expect(navService.setNavigationData.mock.calls[0][0].model).toEqual(model);
        expect(navService.setNavigationData.mock.calls[0][1]).toEqual(queryParams);
        done();
      });
  });

  it('delete', () => {
    const ids = [1, 2, 3];
    service.deleteSanityCheck$('case', ids);
    expect(httpMock.delete).toHaveBeenCalledWith('api/configuration/sanity-check/maintenance/case', {
      params: { ids: JSON.stringify(ids) }
    });
  });
});
