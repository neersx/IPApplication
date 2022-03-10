describe('Jurisdiction Maintenance Service', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });

        inject(function(jurisdictionMaintenanceService) {
            service = jurisdictionMaintenanceService;
        });
    });

    it('should pass correct parameters for updating', function() {
        service.save('AU', 'a');
        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/AU', 'a');
    });

    it('should pass correct parameters for creation', function() {
        service.create('abc');
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/', 'abc');
    });

    it('should pass correct parameters for deletes', function() {
        service.delete('abc, xyz');
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/delete/', 'abc, xyz');
    });

    describe('is duplicate check', function() {
        it('checks duplicates', function() {
            var item1 = {
                a: null,
                b: {
                    key: 'a'
                },
                c: {
                    key: 'b'
                },
                d: 'd'
            };

            var item2 = {
                a: '',
                b: {
                    key: 'a'
                },
                c: {
                    key: 'b'
                },
                d: 'd'
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b', 'c', 'd']);

            expect(r).toBe(true);
        });

        it('matches nulls', function() {
            var item1 = {
                a: 'cycle',
                b: null,
                c: null,
                d: 'd'
            };

            var item2 = {
                a: 'cycle',
                b: null,
                c: null,
                d: 'd'
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b', 'c', 'd']);

            expect(r).toBe(true);
        });

        it('returns false if any fields are different', function() {
            var item1 = {
                a: 2,
                b: null
            };
            var item2 = {
                a: 3,
                b: null
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b']);

            expect(r).toBe(false);
        });

        it('ignores fields outside list', function() {
            var item1 = {
                a: 1,
                b: 'a'
            };
            var item2 = {
                a: 1,
                b: 'b'
            };

            var r = service.isDuplicated([item1], item2, ['a']);
            expect(r).toBe(true);

            r = service.isDuplicated([item1], item2, ['b']);
            expect(r).toBe(false);
        });
    });

    describe('setInUse ', function() {
        it('getInUseItems should return the inuse items matching the topic', function() {
            service.saveResponse = [{
                    topicName: "states",
                    inUseItems: [{
                            id: 1
                        },
                        {
                            id: 2
                        }
                    ]
                },
                {
                    topicName: "overview",
                    inUseItems: [{
                            id: 3
                        },
                        {
                            id: 4
                        }
                    ]
                }
            ];
            var inUseItems = service.getInUseItems("states");
            expect(inUseItems[0].id).toBe(1);
            expect(inUseItems[1].id).toBe(2);
        });
        it('getInUseItems should return null when saveResponse is null', function() {
            service.saveResponse = null;
            var result = service.getInUseItems("states");
            expect(result).toBe(null);
        });

        it('getInUseItems should return null when saveResponse does not exist for that topic', function() {
            service.saveResponse = [{
                topicName: "states",
                inUseItems: [{
                        id: 1
                    },
                    {
                        id: 2
                    }
                ]
            }];
            var result = service.getInUseItems("na");
            expect(result).toBe(null);
        });
    });
});