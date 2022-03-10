describe('comparisonData', function() {
    'use strict';

    var _comparisonData;
    var _httpBackend;
    var _payload = 'a';

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function($injector, comparisonData) {
        _httpBackend = $injector.get('$httpBackend');
        _comparisonData = comparisonData;
    }));

    describe('get languages method', function() {
        describe('get language', function() {
            it('should return notifications from inbox/notifications api', function() {
                _httpBackend.whenGET('api/picklists/tablecodes?tableType=47')
                    .respond(_payload);

                _comparisonData.getLanguages()
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });
        });

        describe('get GoodsServicesText method', function() {
            it('should return notifications from inbox/notifications api', function() {
                _httpBackend.whenGET('api/case/1/goods-services-text/class/01/language/1')
                    .respond(_payload);

                _comparisonData.getGoodsServicesText('1','01','1')
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });
        });

        describe('get ImportedGoodsServicesText method', function() {
            it('should return notifications from inbox/notifications api', function() {
                _httpBackend.whenGET('api/casecomparison/imported-goods-services-text/n/1/class/01/language/en')
                    .respond(_payload);

                _comparisonData.getImportedGoodsServicesText('1','01','en')
                    .then(function(res) {
                        expect(_payload).toBe(res);
                    });

                _httpBackend.flush();
            });
        });
        
        afterEach(function() {
            _httpBackend.verifyNoOutstandingExpectation();
            _httpBackend.verifyNoOutstandingRequest();
        });
    });
});
