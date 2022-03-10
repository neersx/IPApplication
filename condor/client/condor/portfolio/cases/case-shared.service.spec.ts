namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.caseSharedService', () => {
        'use strict';
        let service: ICaseSharedService, httpMock: any

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(($provide) => {
              let $injector: ng.auto.IInjectorService = angular.injector(
                ['inprotech.mocks']
              );

              httpMock = $injector.get('httpMock');
              $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((CaseSharedService: ICaseSharedService) => {
          service = CaseSharedService;
          spyOn(service, 'addToExistingIds').and.callThrough();
        }));

        describe('initialiseDictionary', () => {
            it('sets the ids', () => {
                service.initIds([
                  {key: '-100', value: -100},
                  {key: '100', value: 100},
                  {key: '-101', value: -101},
                  {key: '101', value: 101},
                  {key: '-102', value: -102},
                  {key: '102', value: 102}]);

                expect(service.dict).toEqual([{key: '-100', value: -100},
                        {key: '100', value: 100},
                        {key: '-101', value: -101},
                        {key: '101', value: 101},
                        {key: '-102', value: -102},
                        {key: '102', value: 102}]);
            });
            it('sets the ids only if there are none', () => {
                service.initIds([{key: '-100', value: -100}, {key: '100', value: 100}, {key: '-101', value: -101}, {key: '101', value: 101}, {key: '-102', value: -102}, {key: '102', value: 102}]);

                expect(service.dict).toEqual([{key: '-100', value: -100}, {key: '100', value: 100}, {key: '-101', value: -101}, {key: '101', value: 101}, {key: '-102', value: -102}, {key: '102', value: 102}]);
            });
        });

        describe('addToExistingIds', () => {
          it('appends ids to existing list', () => {
            service.dict = [{key: '-100', value: -100}, {key: '100', value: 100}, {key: '-101', value: -101}, {key: '101', value: 101}, {key: '-102', value: -102}, {key: '102', value: 102}];
            service.addToExistingIds([{key: '-200', value: -200}, {key: '200', value: 200}, {key: '-201', value: -201}, {key: '201', value: 201}, {key: '-202', value: -202}, {key: '202', value: 202}]);
            expect(service.dict).toEqual([{key: '-100', value: -100}, {key: '100', value: 100}, {key: '-101', value: -101}, {key: '101', value: 101}, {key: '-102', value: -102}, {key: '102', value: 102}, {key: '-200', value: -200}, {key: '200', value: 200}, {key: '-201', value: -201}, {key: '201', value: 201}, {key: '-202', value: -202}, {key: '202', value: 202}]);
          });
          it('appends ids only if there are some', () => {
            service.addToExistingIds([{key: '-100', value: -100}, {key: '100', value: 100}, {key: '-101', value: -101}, {key: '101', value: 101}, {key: '-102', value: -102}, {key: '102', value: 102}]);
            expect(service.dict).toEqual([]);
          });
        });

        describe('fetchNext', () => {
            beforeEach(() => {
                let rows = [{ caseKey: 100, rowKey: 1 }, { caseKey: -101, rowKey: 2 }, { caseKey: 200, rowKey: 3 }, { caseKey: -201, rowKey: 4 }];
                let fakeResponse = { rows: rows };

                service.lastSearch = { params: {}, criteria: 'abcd123' };
                httpMock.post.returnValue = fakeResponse;
            });
            it('requests for the next batch of ids', () => {
                service.fetchNext(10);
                expect(service.lastSearch.params).toEqual({skip: 10, take: 200});
                expect(httpMock.post).toHaveBeenCalledWith('api/search/case', {
                    criteria: 'abcd123',
                    params: { skip: 10, take: 200 }
                });
            });
            it('appends returned ids to the list if any', () => {
                service.dict = [{key: '99', value: 99}, {key: '88', value: 88}, {key: '777', value: 777}];
                service.fetchNext(10);
                expect(service.lastSearch.params).toEqual({ skip: 10, take: 200 });
                expect(httpMock.post).toHaveBeenCalledWith('api/search/case', {
                    criteria: 'abcd123',
                    params: { skip: 10, take: 200 }
                });
                expect(service.addToExistingIds).toHaveBeenCalled();
                expect(service.addToExistingIds).toHaveBeenCalledWith([{key: '99', value: 99}, {key: '88', value: 88}, {key: '777', value: 777}, { key: '1', value: 100 }, { key: '2', value: -101 }, { key: '3', value: 200 }, { key: '4', value: -201 }]);
                expect(service.dict).toEqual([{key: '99', value: 99}, {key: '88', value: 88}, {key: '777', value: 777}, { key: '1', value: 100 }, { key: '2', value: -101 }, { key: '3', value: 200 }, { key: '4', value: -201 }]);
            });
        });
    });
}