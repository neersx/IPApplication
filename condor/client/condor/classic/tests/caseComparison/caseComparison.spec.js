describe('Inprotech.CaseDataComparison.caseComparison', function() {

    beforeEach(module('Inprotech.CaseDataComparison'));

    var _fixture = {};

    beforeEach(
        inject(
            function($rootScope, $location, $injector, comparisonData) {

                var httpBackend = $injector.get('$httpBackend');

                _fixture = {
                    scope: $rootScope.$new(),
                    location: $location,
                    httpBackend: httpBackend,
                    comparisonData: comparisonData
                };
            })
    );

    it('should correctly return updateable flag', function() {
        var viewData = {
            updateable: false
        };
        _fixture.comparisonData.initData(viewData, null);
        expect(_fixture.comparisonData.updateable()).toBe(false);
    });

    it('should correctly return rejectable flag', function() {
        var viewData = {
            rejectable: true
        };
        _fixture.comparisonData.initData(viewData, null);
        expect(_fixture.comparisonData.rejectable()).toBe(true);
    });

    it('should correctly set view data', function() {
        var viewData = {
            updateable: false
        };
        _fixture.comparisonData.initData(viewData, null);
        expect(_fixture.comparisonData.getData()).toBe(viewData);
    });

    it('comparison data should be saveable', function() {
        var viewData = {
            case: {
                title: {
                    updated: true
                }
            }
        };
        _fixture.comparisonData.initData(viewData, null);
        expect(_fixture.comparisonData.saveable()).toBe(true);
    });

    it('should prepare data before send to server to save changes', function() {
        var viewData = {
            case: {
                caseId: 123,
                title: {
                    updateable: true,
                    updated: true
                }
            },
            officialNumbers: [{
                id: 123,
                number: {
                    updateable: true,
                    updated: true
                },
                eventDate: {
                    updateable: true,
                    updated: true
                }
            }],
            events: [{
                eventNo: -4,
                cycle: 1,
                eventDate: {
                    updateable: true,
                    updated: true
                }
            }],
            goodsServices: [{
                textType: 'G',
                textNo: 1,
                class: {
                    updateable: true,
                        updated: true
                },
                firstUsedDate: {
                    updateable: true,
                    updated: true
                },
                firstUsedDateInCommerce: {
                    updateable: true,
                    updated: true
                },
                text: {
                    updated: false,
                    updateable: true
                }
            }]
        };
        var notification = {
            notificationId: 1,
            caseId: 20
        };
        var source = 'sourceSet';

        _fixture.comparisonData.initData(viewData, source);
        _fixture.comparisonData.setNotification(notification);

        _fixture.httpBackend.whenPOST('api/casecomparison/saveChanges')
            .respond(function() {
                var data = JSON.parse(arguments[2]);
                expect(data.source).toBe(source);
                expect(data.case.title.updated).toBe(true);
                expect(data.case.caseId).toBe(123);
                expect(data.officialNumbers[0].id).toBe(123);
                expect(data.officialNumbers[0].number.updated).toBe(true);
                expect(data.officialNumbers[0].eventDate.updated).toBe(true);
                expect(data.events[0].eventNo).toBe(-4);
                expect(data.events[0].cycle).toBe(1);
                expect(data.events[0].eventDate.updated).toBe(true);
                expect(data.goodsServices[0].textType).toBe('G');
                expect(data.goodsServices[0].textNo).toBe(1);
                expect(data.goodsServices[0]['class'].updated).toBe(true);
                expect(data.goodsServices[0].firstUsedDate.updated).toBe(true);
                expect(data.goodsServices[0].firstUsedDateInCommerce.updated).toBe(true);
                var returnData = {
                    viewData: data,
                    success: true
                };
                return [200, returnData];
            });

        _fixture.comparisonData.saveChanges(_fixture.scope);
        expect(_fixture.scope.saveState).toBe('saving');

        _fixture.httpBackend.expectPOST('api/casecomparison/saveChanges');
        _fixture.httpBackend.flush();

        expect(_fixture.scope.saveState).toBe(null);
        expect(_fixture.comparisonData.areAllDifferencesSelected()).toBe(false);
    });
});