import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { skip } from 'rxjs/operators';
import { SanityCheckMaintenanceService } from './sanity-check-maintenance.service';

describe('Service: SanityCheckConfiguration', () => {
  let service: SanityCheckMaintenanceService;
  let httpMock: HttpClientMock;

  beforeEach(() => {
    httpMock = new HttpClientMock();
    service = new SanityCheckMaintenanceService(httpMock as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  it('calls server to get view data', () => {
    service.getViewData$('car', 1);

    expect(httpMock.get).toHaveBeenCalled();
    expect(httpMock.get.mock.calls[0][0]).toEqual('api/configuration/sanity-check/maintenance/car/1');
  });

  it('calls server to save data', () => {
    const data = { a: 'x' };
    service.save$('car', data);

    expect(httpMock.post).toHaveBeenCalled();
    expect(httpMock.post.mock.calls[0][0]).toEqual('api/configuration/sanity-check/maintenance/car');
    expect(httpMock.post.mock.calls[0][1]).toEqual(data);
  });

  it('calls server to update data', () => {
    const data = { a: 'x' };
    service.update$('car', data);

    expect(httpMock.put).toHaveBeenCalled();
    expect(httpMock.put.mock.calls[0][0]).toEqual('api/configuration/sanity-check/maintenance/car');
    expect(httpMock.put.mock.calls[0][1]).toEqual(data);
  });

  it('raises pending status ', done => {
    service.hasPendingChanges$.pipe(skip(1))
      .subscribe((x: any) => {
        expect(x).toBeTruthy();
        done();
      });

    service.raiseStatus('a', true, true, false);
  });

  it('raises has errors', done => {
    service.hasErrors$.pipe(skip(1))
      .subscribe((x: any) => {
        expect(x).toBeTruthy();
        done();
      });

    service.raiseStatus('a', true, true, false);
  });
});
