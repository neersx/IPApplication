'use strict';
namespace inprotech.portfolio.cases {
  declare let test: any;
  describe('case view classes service', () => {
    let service: ICaseviewClassesService, http;

    beforeEach(() => {
      angular.mock.module(() => {
        http = test.mock('$http', 'httpMock');
      });
      angular.mock.module('inprotech.portfolio.cases');
    });

    beforeEach(() => {
      inject(caseviewClassesService => {
        service = caseviewClassesService;
      });
    });

    it('returns case classes from server', () => {
      service.getClassesSummary(1);
      expect(http.get).toHaveBeenCalledWith('api/case/1/classesSummary');
    });

    it('returns case texts from server', () => {
      service.getClassTexts(1, '01');
      expect(http.get).toHaveBeenCalledWith('api/case/1/01/classTexts');
    });
  });
}
