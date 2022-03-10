describe('comparisonDataSourceMap', function() {
    'use strict';

    var _dataSourceMap, _translate;

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function(comparisonDataSourceMap, $translate) {
        _translate = $translate;
        _dataSourceMap = comparisonDataSourceMap;
    }));

    describe('systemCode method', function() {
        it('should return systemCode based on dataSource', function() {
            expect(_dataSourceMap.systemCode('UsptoPrivatePair')).toBe('USPTO.PrivatePAIR');
            expect(_dataSourceMap.systemCode('UsptoTsdr')).toBe('USPTO.TSDR');
        });
    });

    describe('name method', function() {
        it('should return name based on dataSource', function() {
            spyOn(_translate, 'instant').and.returnValue('hello');
            var r = _dataSourceMap.name('UsptoPrivatePair');
            expect(r).toBe('hello');
            expect(_translate.instant).toHaveBeenCalledWith('caseComparison.gLblDSUsptoPrivatePair');
        });
    });
});