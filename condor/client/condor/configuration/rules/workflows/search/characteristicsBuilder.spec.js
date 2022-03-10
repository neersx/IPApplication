describe('inprotech.configuration.rules.workflows.characteristicsBuilder', function() {
    'use strict';

    var builder;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        inject(function(characteristicsBuilder) {
            builder = characteristicsBuilder;
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
            basis: {
                code: 6
            },
            action: {
                code: 7
            },
            office: {
                key: 8
            },
            dateOfLaw: {
                code: 9
            },
            applyTo: 10,
            matchType: 11,
            includeProtectedCriteria: 12,
            includeCriteriaNotInUse: 13,
            event: {
                key: 14
            },
            eventSearchType: 15,
            examinationType: {key: 4},
            renewalType: {key: 5 }
        };

        var output = builder.build(input);

        expect(output).toEqual({
            caseType: 1,
            caseCategory: 2,
            jurisdiction: 3,
            subType: 4,
            propertyType: 5,
            basis: 6,
            action: 7,
            office: 8,
            dateOfLaw: 9,
            applyTo: 10,
            matchType: 11,
            includeProtectedCriteria: 12,
            includeCriteriaNotInUse: 13,
            event: 14,
            eventSearchType: 15,
            examinationType: 4,
            renewalType: 5
        });
    });
});