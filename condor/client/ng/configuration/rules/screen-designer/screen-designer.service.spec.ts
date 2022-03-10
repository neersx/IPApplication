import { HttpClientMock } from 'mocks';
import { ScreenDesignerService } from './screen-designer.service';

describe('Service: ScreenDesigner', () => {
  let service: ScreenDesignerService;
  let httpMock: HttpClientMock;

  beforeEach(() => {
    httpMock = new HttpClientMock();
    service = new ScreenDesignerService(httpMock as any);
  });

  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('getCaseViewData$', () => {
    it('should call the correct api to get the view data', () => {
      service.getCriteriaSearchViewData$();
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/viewData');
    });
  });

  describe('getCriteriaDetails$', () => {
    it('should call the correct api to get the criteria details', () => {
      service.getCriteriaDetails$(1);
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/1/characteristics');
    });
  });

  describe('getCriteriaDetails$', () => {
    it('should call the correct api to get the criteria details', () => {
      service.getCriteriaSections$(1);
      expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/screen-designer/case/1/sections');
    });
  });
});
