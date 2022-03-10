import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SearchHelperService } from './search-helper.service';

describe('SearchHelperService', () => {
    let service: SearchHelperService;
    beforeEach(() => {
        SearchTypeConfigProvider.savedConfig = {
            baseApiRoute: 'api/search/case/'
        } as any;

        service = new SearchHelperService();
    });
    describe('get keys from typeahead', () => {
        it('should return csv list from multi select typeaheads', () => {
            const value = [{ code: 'a' }, { code: 'b' }, { key: 'c' }];
            let result = service.getKeysFromTypeahead(value);
            expect(result).toEqual('a,b,c');
            result = service.getKeysFromTypeahead(value, true);
            expect(result).toEqual('a,b,c');
        });

        it('should return code or key from single select typeaheads', () => {
            const value = { code: 'a', key: 'b' };
            let result = service.getKeysFromTypeahead(value);
            expect(result).toEqual('a');

            result = service.getKeysFromTypeahead(value, true);
            expect(result).toEqual('b');

            delete value.code;
            result = service.getKeysFromTypeahead(value);
            expect(result).toEqual('b');
        });
    });
    describe('build String filter from typeahead', () => {
        it('should generate from single value without extend property', () => {
            const values = { code: '1500', value: 'value1' };
            const operator = 2;

            const output = service.buildStringFilterFromTypeahead(values, operator);

            expect(output).toEqual({ value: '1500', operator: 2 });
        });

        it('should generate from single value with extend property', () => {
            const values = { code: '1500', value: 'value1' };
            const operator = 2;
            const otherProperties = { isLocal: true };

            const output = service.buildStringFilterFromTypeahead(values, operator, otherProperties);
            expect(output).toEqual({ value: '1500', operator: 2, isLocal: true });
        });

        it('should generate from mutiple values with extend properties', () => {
            const values = [{ code: '1500', value: 'value1' }, { key: '1501', value: 'value2' }];
            const operator = 0;
            const otherProperties = { isLocal: 1, isInternational: 0 };

            const output = service.buildStringFilterFromTypeahead(values, operator, otherProperties);
            expect(output).toEqual({ value: '1500,1501', operator: 0, isLocal: 1, isInternational: 0 });
        });

    });

    describe('build String filter from value', () => {
        it('should generate from value without extend property', () => {
            const values = '1500';
            const operator = 2;

            const output = service.buildStringFilter(values, operator);
            expect(output).toEqual({ value: '1500', operator: 2 });
        });

        it('should generate from value with extend property', () => {
            const values = '1500';
            const operator = 2;
            const otherProperties = { isLocal: true };

            const output = service.buildStringFilter(values, operator, otherProperties);
            expect(output).toEqual({ value: '1500', operator: 2, isLocal: true });
        });
    });

    describe('isFilterApplicable method', () => {
        it('should return true for exists and not exists', () => {
            let output = service.isFilterApplicable('5', null);
            expect(output).toEqual(true);

            output = service.isFilterApplicable('6', null);
            expect(output).toEqual(true);

            output = service.isFilterApplicable('2', null);
            expect(output).toEqual(false);
        });

        it('should return true if data exists', () => {
            let output = service.isFilterApplicable('0', 'value');
            expect(output).toEqual(true);

            output = service.isFilterApplicable('0', null);
            expect(output).toEqual(false);
        });
    });

    describe('buildFromToValues method', () => {
        it('should return correct object', () => {
            let output = service.buildFromToValues('5', null);
            expect(output).toEqual({ from: '5' });

            output = service.buildFromToValues(null, '6');
            expect(output).toEqual({ to: '6' });

            output = service.buildFromToValues('5', '6');
            expect(output).toEqual({ from: '5', to: '6' });

            output = service.buildFromToValues('2', '1');
            expect(output).toEqual({ from: '1', to: '2' });
        });
    });

    describe('periodType', () => {
        it('should return correct period types', () => {
            const output = service.getPeriodTypes();
            const expected = [{
                key: 'D',
                value: 'periodTypes.days'
            }, {
                key: 'W',
                value: 'periodTypes.weeks'
            }, {
                key: 'M',
                value: 'periodTypes.months'
            }, {
                key: 'Y',
                value: 'periodTypes.years'
            }];

            expect(output).toEqual(expected);
        });
    });
});
