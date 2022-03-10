import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { InheritanceService } from './inheritance.service';

describe('Service: Inheritance', () => {
  let service: InheritanceService;
  let httpClient: HttpClientMock;
  beforeEach(() => {
    httpClient = new HttpClientMock();
    httpClient.get.mockReturnValue(of({}));
    service = new InheritanceService(httpClient as any);
  });

  it('should create', () => {
    expect(service).toBeTruthy();
  });

  describe('getInheritance', () => {
    it('should call the expected api with the correct params', () => {
      service.getInheritance([1, 2, 3]);

      expect(httpClient.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/inheritance', expect.objectContaining({
        params: {
          criteriaIds: '1,2,3'
        }
      }));
    });

  });
});
