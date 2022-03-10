describe('inprotech.processing.policing.PolicingQueueService', function() {
    'use strict';

    var service, httpMock, filterService, queryParams, otherFilters;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing']);

            httpMock = $injector.get('httpMock');
            httpMock.get.returnValue = {};

            filterService = $injector.get('PolicingQueueFilterServiceMock');
            $provide.value('policingQueueFilterService', filterService);

            $provide.value('$http', httpMock);
        });

        queryParams = {
            sortBy: 'any',
            sortDir: 'asc',
            skip: 1,
            take: 2
        };

        otherFilters = [{
            field: 'user',
            operator: 'in',
            value: '34'
        }];
    });

    beforeEach(inject(function(policingQueueService) {
        service = policingQueueService;
    }));

    describe('policing queue', function() {
        it('should return filter list', function() {
            service.getColumnFilterData({
                field: 'user'
            }, 'all', null, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/filterData/user/all', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });

        it('should return all queue items', function() {
            service.get('all', queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/all', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should return only progressing items', function() {
            service.get('progressing', queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/progressing', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should return only requires-attention items', function() {
            service.get('requires-attention', queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/requires-attention', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should return only on-hold items', function() {
            service.get('on-hold', queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/on-hold', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should return default to all if unidentified param is set', function() {
            service.get('any invalid value', queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/all', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should call server to fetch error data related to case id', function() {
            service.getErrors(100, queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/errors/100', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should call release api for selected items', function() {
            service.releaseSelected([{
                requestId: 1
            }]);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/queue/admin/release', [1]);
        });

        it('should call hold api for selected items', function() {
            service.holdSelected([{
                requestId: 1
            }]);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/queue/admin/hold', [1]);
        });

        it('delete should make http post backend call with ids', function() {
            var selectedItems = [{
                requestId: 1
            }, {
                requestId: 2
            }];
            service.deleteSelected(selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/queue/admin/delete', [1, 2]);
        });

        it('should call release api for all items', function() {
            service.releaseAll('all', queryParams);
            expect(httpMock.put).toHaveBeenCalledWith('api/policing/queue/admin/release/all', JSON.stringify(queryParams));
        });

        it('should call hold api for all items', function() {
            service.holdAll('all', queryParams);
            expect(httpMock.put).toHaveBeenCalledWith('api/policing/queue/admin/hold/all', JSON.stringify(queryParams));
        });

        it('should call delete api for all items', function() {
            service.deleteAll('all', queryParams);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/queue/admin/delete/all', JSON.stringify(queryParams));
        });

        it('should edit next run time for selected items', function() {
            var nextRunTime = '2016-02-16T12:34:00Z';
            var selectedItems = [{
                requestId: 1
            }, {
                requestId: 2
            }];
            service.editNextRunTime(nextRunTime, selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/queue/admin/editNextRuntTime/' + nextRunTime, [1, 2]);
        });
    });

    describe('policing queue filter', function() {
        it('should return available filters for users', function() {
            var userColumnDef = {
                field: 'user'
            };
            service.getColumnFilterData(userColumnDef, 'all', null, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/filterData/user/all', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });

        it('should return available filters for caseReference', function() {
            var caseRefColumnDef = {
                field: 'caseReference'
            };
            service.getColumnFilterData(caseRefColumnDef, 'all', null, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/filterData/caseReference/all', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });

        it('should return available filters for status', function() {
            var statusColumnDef = {
                field: 'status'
            };
            service.getColumnFilterData(statusColumnDef, 'all', null, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/filterData/status/all', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });

        it('should call policing queue filter service to get new filters', function() {
            httpMock.get.returnValue = {};
            var caseRefColumnDef = {
                field: 'caseReference'
            };
            service.getColumnFilterData(caseRefColumnDef, 'all', {
                field: 'caseReference',
                value: 'abcd'
            }, []);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/queue/filterData/caseReference/all', {
                params: {
                    columnFilters: JSON.stringify([])
                }
            });
            expect(filterService.getFilters).toHaveBeenCalled();
        });
    });
});
