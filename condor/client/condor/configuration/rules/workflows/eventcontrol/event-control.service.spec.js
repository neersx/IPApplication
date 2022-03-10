describe('inprotech.configuration.rules.workflows.workflowsEventControlService', function() {
    'use strict';

    var service, httpMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            httpMock = test.mock('$http', 'httpMock');
        });
        inject(function(workflowsEventControlService) {
            service = workflowsEventControlService;
        });
    });

    it('getMatchingNameTypes should pass correct parameters', function() {
        service.getMatchingNameTypes(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventcontrol/-2/nametypemaps');
    });

    it('getDateComparisons should pass correct parameters', function() {
        service.getDateComparisons(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventcontrol/-2/datecomparisons');
    });

    it('getSatisfyingEvents should pass correct parameters', function() {
        service.getSatisfyingEvents(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventcontrol/-2/satisfyingevents');
    });

    it('getEventsToUpdate should pass correct parameters', function() {
        service.getEventsToUpdate(-1, -2);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventcontrol/-2/eventstoupdate');
    });

    describe('update event control', function() {
        it('http puts to the correct url and returns the result', function() {
            var formData = {
                data: 'a'
            };
            httpMock.put.returnValue = 'b';

            var result = service.updateEventControl(-1, -2, formData);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/-1/eventcontrol/-2', formData);
            expect(result).toBe('b');
        });
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

        it('checks duplicates for value and type', function() {
            var item1 = {
                a: null,
                b: {
                    value: 1,
                    type: 'D'
                },
                c: {
                    value: 1,
                    type: 'D'
                },
                d: 'd'
            };

            var item2 = {
                a: '',
                b: {
                    value: 1,
                    type: 'D'
                },
                c: {
                    value: 1,
                    type: 'M'
                },
                d: 'd'
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b', 'd']);

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

        it('matches zeros', function() {
            var item1 = {
                a: 'cycle',
                b: 0,
                d: 'd'
            };

            var item2 = {
                a: 'cycle',
                b: 0,
                d: 'd'
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b', 'd']);
            expect(r).toBe(true);
        });

        it('matches dates', function() {
            var dateString = '2016-01-01T00:00:00';
            var item = {
                d: dateString
            };
            var dateItem = {
                d: new Date(dateString)
            }

            var r = service.isDuplicated([item], dateItem, ['d']);

            expect(r).toBe(true);
        });

        it('returns false if any fields are different', function() {
            var item1 = {
                a: 'cycle',
                b: null,
                c: null,
                d: 'd'
            };
            var item2 = {
                a: 'cycle1',
                b: null,
                c: null,
                d: 'd'
            };

            var r = service.isDuplicated([item1], item2, ['a', 'b', 'c', 'd']);

            expect(r).toBe(false);
        });


        it('ignores fields outside list', function() {
            var item1 = {
                a: 'cycle1',
                b: 'a'
            };
            var item2 = {
                a: 'cycle1',
                b: 'b'
            };

            var r = service.isDuplicated([item1], item2, ['a']);
            expect(r).toBe(true);

            r = service.isDuplicated([item1], item2, ['b']);
            expect(r).toBe(false);
        });
    });

    describe('has duplicate check', function() {
        it('marks last duplicate and returns result', function() {
            var item1 = {
                a: 'a',
                b: '1'
            };
            var item2 = {
                a: 'a',
                b: '2'
            };
            var item3 = {
                a: 'a',
                b: '3'
            };
            var r = service.hasDuplicate([item1, item2, item3], ['a']);
            expect(item1.isDuplicatedRecord).not.toBeDefined();
            expect(item2.isDuplicatedRecord).not.toBeDefined();
            expect(item3.isDuplicatedRecord).toBe(true);
            expect(r).toBe(true);
        });

        it('ignores deleted records', function() {
            var item1 = {
                a: 'a',
                b: '1',
                deleted: true
            };
            var item2 = {
                a: 'a',
                b: '2'
            };
            var r = service.hasDuplicate([item1, item2], ['a']);
            expect(item1.isDuplicatedRecord).not.toBeDefined();
            expect(item2.isDuplicatedRecord).not.toBeDefined();
            expect(r).toBe(false);
        });
    });

    describe('isApplyEnabled', function() {
        it('returns false if form is not dirty', function() {
            var form = {
                $pristine: true,
                $invalid: false
            };

            expect(service.isApplyEnabled(form)).toBe(false);
        });

        it('returns false if form is not valid', function() {
            var form = {
                $pristine: false,
                $invalid: true
            };

            expect(service.isApplyEnabled(form)).toBe(false);
        });

        it('returns true if form is valid and dirty', function() {
            var form = {
                $pristine: false,
                $invalid: false
            };

            expect(service.isApplyEnabled(form)).toBe(true);
        });
    });

    describe('mapGridDelta', function() {
        var mapFuncSpy, mappedResult;
        beforeEach(function() {
            mappedResult = {};
            mapFuncSpy = jasmine.createSpy().and.returnValue(mappedResult);
        });

        it('should get added rows in data', function() {
            var data = [{
                id: 1,
                added: true
            }, {
                id: 2,
                added: true
            }, {
                id: 3,
                added: true,
                deleted: true
            }, {
                id: 4,
                isEdited: true
            }];
            var result = service.mapGridDelta(data, mapFuncSpy);

            expect(result.added.length).toBe(2);
            expect(result.added[0]).toBe(mappedResult);
            expect(result.added[1]).toBe(mappedResult);

            expect(mapFuncSpy.calls.argsFor(0)[0]).toBe(data[0]);
            expect(mapFuncSpy.calls.argsFor(1)[0]).toBe(data[1]);
        });

        it('should get edited rows in data', function() {
            var data = [{
                id: 1,
                isEdited: true
            }, {
                id: 2,
                isEdited: false
            }, {
                id: 3,
                isEdited: true,
                deleted: true
            }, {
                id: 4,
                isEdited: true,
                added: true
            }];
            var result = service.mapGridDelta(data, mapFuncSpy);

            expect(result.updated.length).toBe(1);
            expect(result.updated[0]).toBe(mappedResult);

            expect(mapFuncSpy.calls.argsFor(2)[0]).toBe(data[0]);
        });

        it('should get deleted rows in data', function() {
            var data = [{
                id: 1,
                deleted: true
            }, {
                id: 2,
                deleted: false
            }];
            var result = service.mapGridDelta(data, mapFuncSpy);

            expect(result.deleted.length).toBe(1);
            expect(result.deleted[0]).toBe(mappedResult);

            expect(mapFuncSpy.calls.argsFor(0)[0]).toBe(data[0]);
        });
    });

    describe('initEventPicklistScope', function() {
        it('should extend query for event picklist', function() {
            var r = service.initEventPicklistScope({
                filterByCriteria: true,
                criteriaId: 'criteriaId',
                picklistSearch: 'abc'
            });

            expect(r).toEqual(jasmine.objectContaining({
                criteriaId: 'criteriaId',
                picklistSearch: 'abc'
            }));
        });
    });

    describe('formatPicklistColumn', function() {
        it('returns empty string if not object', function() {
            var r = service.formatPicklistColumn();
            expect(r).toBe('');
        });

        it('returns picklist formatted for display', function() {
            var r = service.formatPicklistColumn({
                key: -1,
                value: 'apple'
            });

            expect(r).toBe('apple (-1)');
        });
    });

    describe('reset event', function() {
        it('makes a call to the api with the correct parameters', function() {
            httpMock.put.returnValue = {data: 'Hi'};
            var result = service.resetEvent(1, 2, true);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/1/eventcontrol/2/reset?applyToDescendants=true');
            expect(result.data).toEqual('Hi');
        });

        it ('makes a call to the api with the optional updateRespNameOnCases param', function() {
            httpMock.put.returnValue = {data: 'Hi'};
            var result = service.resetEvent(1, 2, false, true);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/1/eventcontrol/2/reset?applyToDescendants=false&updateRespNameOnCases=true');
            expect(result.data).toEqual('Hi');
        });
    });

    describe('break event inheritance', function() {
        it('makes a call to the api with the correct parameters', function() {
            httpMock.put.returnValue = {data: 'Bye'};
            var result = service.breakEventInheritance(1, 2);
            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/rules/workflows/1/eventcontrol/2/break');
            expect(result.data).toEqual('Bye');
        });
    });
});
