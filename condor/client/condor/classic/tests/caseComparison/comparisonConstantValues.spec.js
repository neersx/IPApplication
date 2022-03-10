'use strict';

describe('Inprotech.CaseDataComparison.comparisonConstantValues', function() {
    var _constantValues;

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function(comparisonConstantValues) {
        _constantValues = comparisonConstantValues;
    }));

    it('should return dataSources', function() {
        expect(_constantValues.dataSources.UsptoPrivatePair).toBe('UsptoPrivatePair');
        expect(_constantValues.dataSources.UsptoTsdr).toBe('UsptoTsdr');
        expect(_constantValues.dataSources.Epo).toBe('Epo');
        expect(_constantValues.dataSources.IpOneData).toBe('IPOneData');
    });

    it('should return systemCodes', function() {
        expect(_constantValues.systemCodes.UsptoPrivatePair).toBe('USPTO.PrivatePAIR');
        expect(_constantValues.systemCodes.UsptoTsdr).toBe('USPTO.TSDR');
        expect(_constantValues.systemCodes.Epo).toBe('EPO');
        expect(_constantValues.systemCodes.IpOneData).toBe('IPOneData');
    });
});