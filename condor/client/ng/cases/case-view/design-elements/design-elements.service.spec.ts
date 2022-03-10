import { HttpClientMock } from 'mocks';
import { DesignElementsService } from './design-elements.service';

describe('Service: designElements', () => {
  let http: HttpClientMock;
  let service: DesignElementsService;
  beforeEach(() => {
    http = new HttpClientMock();
    service = new DesignElementsService(http as any);
    service.states = {
      hasPendingChanges: false,
      hasErrors: false
    };
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });
  describe('getdesignElements', () => {
    it('should call get for the related cases API', () => {
      const params = { skip: 0, take: 10 };
      service.getDesignElements(1, params);

      expect(http.get).toHaveBeenCalledWith(`api/case/${1}/designElements`, { params: { params: JSON.stringify(params) } });
    });

    it('should call raisePendingChanges', () => {
      service.states.hasPendingChanges = false;
      service.raisePendingChanges(true);
      expect(service.states.hasPendingChanges).toBe(true);
    });

    it('should call raiseHasErrors', () => {
      service.states.hasErrors = false;
      service.raiseHasErrors(true);
      expect(service.states.hasErrors).toBe(true);
    });

    it('should call getValidationErrors', () => {
      const currentRow = {
        firmElementCaseRef: '1234',
        clientElementCaseRef: '123',
        elementOfficialNo: '123',
        registrationNo: '123',
        noOfViews: 1,
        elementDescription: '567',
        renew: true,
        sequence: 1,
        status: null,
        rowKey: '1'
      };
      service.getValidationErrors(123, currentRow, []);
      const body = {
        caseKey: 123,
        currentRow,
        changedRows: []
      };
      expect(http.post).toHaveBeenCalledWith('api/case/designElements/validate', body);
    });
  });
});
