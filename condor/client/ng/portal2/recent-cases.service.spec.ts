import { HttpParams } from '@angular/common/http';
import { CaseNavigationServiceMock } from 'cases/core/case-navigation.service.mock';
import { RecentCasesService } from './recent-cases.service';

let httpClientSpy = { get: jest.fn(), post: jest.fn() };
let caseNavSpy: CaseNavigationServiceMock;

let service: RecentCasesService;
describe('RecentCasesService', () => {
  beforeEach(() => {
    // tslint:disable-next-line: no-empty
    httpClientSpy = { get: jest.fn().mockReturnValue({pipe: (args: any) => {
    }}), post: jest.fn() };
    caseNavSpy = new CaseNavigationServiceMock();

    service = new RecentCasesService(caseNavSpy as any, httpClientSpy as any);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should set navigation data on successful get', () => {
    service.get(null);

    expect(caseNavSpy.clearLoadedData).toHaveBeenCalled();
    expect(caseNavSpy.setNavigationData).toHaveBeenCalled();
  });

  it('should pass the query params in the get request', () => {
    const queryParams = { skip: 10, take: 20};
    service.get(queryParams);
    expect(httpClientSpy.get).toHaveBeenCalledWith('api/recentCases', {
      params: new HttpParams().set('params', JSON.stringify(queryParams))
    });
  });
  it('should get http request for getDefaultProgram', () => {
    service.getDefaultProgram();
    expect(httpClientSpy.get).toHaveBeenCalledWith('api/recentCases/defaultProgram');
  });
});