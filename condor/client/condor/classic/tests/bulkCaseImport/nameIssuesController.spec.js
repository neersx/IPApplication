describe('Inprotech.BulkCaseImport.nameIssuesController', function() {
    'use strict';

    var _scope, _controller, _initView, _http;

    var _fixture;

    beforeEach(module('Inprotech.BulkCaseImport'));

    beforeEach(inject(function($rootScope, $controller, $httpBackend) {

        _scope = $rootScope.$new();
        _initView = {
            'viewData': {
                'batchIdentifier': '1234',
                'nameIssues': []
            }
        };

        _http = $httpBackend;

        _fixture = {
            'name1': {
                'a': 'a'
            },
            'name2': {
                'b': 'b'
            }
        };

        _controller = function() {
            return $controller('nameIssuesController', {
                '$scope': _scope,
                'viewInitialiser': _initView
            });
        };
    }));

    describe('when there are no name issues', function() {
        it('should indicate there are no name issues', function() {
            _controller();
            expect(_scope.hasNameIssues()).toBe(false);
        });

        it('should not have any unresolved names selected', function() {
            _controller();
            expect(_scope.selectedUnresolved).not.toBe(_fixture.name1);
        });
    });

    describe('when there are name issues', function() {

        beforeEach(function() {
            _initView.viewData.nameIssues = [_fixture.name1, _fixture.name2];
        });

        it('should indicate there are name issues', function() {
            _controller();
            expect(_scope.hasNameIssues()).toBe(true);
        });

        it('should select the first unresolved name', function() {
            _controller();
            expect(_scope.selectedUnresolved).toBe(_fixture.name1);
        });

        it('should select the first candidate if available', function() {
            var candidate1 = 'candidate';

            _fixture.name1 = _.extend(_fixture.name1, {
                mapCandidates: [candidate1]
            });

            _controller();

            expect(_scope.selectedCandidate).toBe(candidate1);
        });

        describe('user selects a candidate', function() {

            it('should select the candidate', function() {

                var candidate1 = 'candidate1';
                var candidate2 = 'candidate2';

                _fixture.name1 = _.extend(_fixture.name1, {
                    mapCandidates: [candidate1, candidate2]
                });

                _controller();

                _scope.onCandidateSelected(candidate2);

                expect(_scope.selectedCandidate).toBe(candidate2);
            });
        });

        describe('user selects a different unresolved name', function() {

            it('should select new unresolved name and its first candidate', function() {

                var candidate1 = 'candidate1';
                var candidate2 = 'candidate2';

                _fixture.name1 = _.extend(_fixture.name1, {
                    mapCandidates: [candidate1]
                });
                _fixture.name2 = _.extend(_fixture.name2, {
                    mapCandidates: [candidate2]
                });

                _controller();

                _scope.onUnresolvedNameSelected(_fixture.name2);

                expect(_scope.selectedUnresolved).toBe(_fixture.name2);
                expect(_scope.selectedCandidate).toBe(candidate2);
            });

            it('should retrieve candidates and select its first candidate', function() {
                var unresolvedNameId = 999;

                _http.whenGET('api/bulkcaseimport/unresolvedname/candidates?id=999').respond(function() {
                    return [200, {
                        'mapCandidates': ['a', 'b', 'c']
                    }, {}];
                });

                _fixture.name2 = _.extend(_fixture.name2, {
                    id: unresolvedNameId
                });

                _controller();

                _scope.onUnresolvedNameSelected(_fixture.name2);

                _http.flush();

                expect(_scope.selectedUnresolved.mapCandidates.length).toBe(3);
                expect(_scope.selectedCandidate).toBe('a');
            });

            it('should retrieve candidates and clear candidate selection if none returned', function() {
                var unresolvedNameId = 999;

                _http.whenGET('api/bulkcaseimport/unresolvedname/candidates?id=999').respond(function() {
                    return [200, {
                        'mapCandidates': []
                    }, {}];
                });

                _fixture.name2 = _.extend(_fixture.name2, {
                    id: unresolvedNameId
                });

                _controller();

                _scope.onUnresolvedNameSelected(_fixture.name2);

                _http.flush();

                expect(_scope.selectedUnresolved.mapCandidates.length).toBe(0);
                expect(_scope.selectedCandidate).toBe(null);
            });

            afterEach(function() {
                _http.verifyNoOutstandingExpectation();
                _http.verifyNoOutstandingRequest();
            });
        });

        describe('user maps a name', function() {
            beforeEach(function() {
                _fixture = {
                    'name1': {
                        'id': 123,
                        'a': 'a',
                        'mapCandidates': [{
                            'id': 987
                        }]
                    },
                    'name2': {
                        'id': 245,
                        'b': 'b',
                        'mapCandidates': [{
                            'id': 876
                        }]
                    }
                };

                _initView.viewData.batchId = 888;
            });

            it('should post the users selections', function() {

                _initView.viewData.nameIssues = [_fixture.name1];

                var postedData;
                _http.whenPOST('api/bulkcaseimport/unresolvedname/mapname').respond(function() {
                    postedData = JSON.parse(arguments[2]);
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }, {}];
                });

                _controller();

                _scope.mapName();

                _http.flush();

                expect(postedData.batchId).toBe(888);
                expect(postedData.unresolvedNameId).toBe(123);
                expect(postedData.mapNameId).toBe(987);
            });

            it('should remove the name from unresolved names', function() {

                _initView.viewData.nameIssues = [_fixture.name1, _fixture.name2];

                
                _http.whenPOST('api/bulkcaseimport/unresolvedname/mapname').respond(function() {
                    JSON.parse(arguments[2]);
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }, {}];
                });

                _controller();

                _scope.mapName();

                _http.flush();

                expect(_scope.viewData.nameIssues.length).toBe(1);
                expect(_scope.status).toBe('idle');
            });

            it('should set the status to complete if there are no more names', function() {

                _initView.viewData.nameIssues = [_fixture.name1];
                
                _http.whenPOST('api/bulkcaseimport/unresolvedname/mapname').respond(function() {
                    JSON.parse(arguments[2]);
                    return [200, {
                        result: {
                            result: 'success'
                        }
                    }, {}];
                });

                _controller();

                _scope.mapName();

                _http.flush();

                expect(_scope.viewData.nameIssues.length).toBe(0);
                expect(_scope.status).toBe('complete');
            });

            it('should do nothing if there is no candidate name', function() {

                _controller();
                _scope.mapName();

                _http.verifyNoOutstandingRequest();
                expect(_scope.status).toBe('idle');
            });

            afterEach(function() {
                _http.verifyNoOutstandingExpectation();
                _http.verifyNoOutstandingRequest();
            });
        });
    });
});
