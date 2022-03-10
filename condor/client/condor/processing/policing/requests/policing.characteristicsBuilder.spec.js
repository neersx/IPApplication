describe('inprotech.processing.policing.policingCharacteristicsBuilder', function() {
    'use strict';

    var builder;

    beforeEach(function() {
        module('inprotech.processing.policing');
        inject(function(policingCharacteristicsBuilder) {
            builder = policingCharacteristicsBuilder;
        });
    });

    it('should build characteristics i.e. picklists values', function() {
        var input = {
            caseType: {
                code: 1
            },
            caseCategory: {
                code: 2
            },
            jurisdiction: {
                code: 3
            },
            subType: {
                code: 4
            },
            propertyType: {
                code: 5
            },
            action: {
                code: 6
            },
            office: {
                key: 7
            },
            dateOfLaw: {
                code: 8
            },
            caseTypeModel: { key: 1 },
            propertyTypeModel: { key: 5 },
            jurisdictionModel: { key: 3 },
            caseCategoryModel: { code: 2 }
        };

        var output = builder.build(input);

        expect(output).toEqual({
            caseType: 1,
            caseCategory: 2,
            jurisdiction: 3,
            subType: 4,
            propertyType: 5,
            action: 6,
            office: 7,
            dateOfLaw: 8,
            caseTypeModel: { code: 1 },
            propertyTypeModel: { code: 5 },
            jurisdictionModel: { code: 3 },
            caseCategoryModel: { code: 2 }
        });
    });
});