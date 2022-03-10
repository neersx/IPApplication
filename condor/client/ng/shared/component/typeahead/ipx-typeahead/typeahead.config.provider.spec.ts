import { LocalSettingsMocks } from 'mocks';
import { TypeaheadFieldType } from '../ipx-autocomplete/autocomplete/template.type';
import { TypeAheadConfigProvider } from './typeahead.config.provider';
describe('TypeAheadConfigProvider', () => {
    let component: TypeAheadConfigProvider;
    const localset = new LocalSettingsMocks();
    beforeEach(() => {
        component = new TypeAheadConfigProvider(localset as any);
    });

    it('should load the type ahead configuration service', () => {
        expect(component).toBeTruthy();
    });

    it('should load the configuarion defined in key', () => {
        const key = 'dataItem';
        const options = {
            label: 'picklist.dataitem.Type',
            keyField: 'key',
            textField: 'code',
            codeField: 'code',
            apiUrl: 'api/picklists/dataItems'
        };
        component.config(key, options);
        expect(component.globalOptions[key]).toEqual({ apiUrl: 'api/picklists/dataItems', codeField: 'code', keyField: 'key', label: 'picklist.dataitem.Type', textField: 'code' });
    });

    it('should resolve the options based on attributes', () => {
        const attrs = {
            config: 'jurisdiction',
            label: 'jurisdiction'
        };

        component.defaultOptions = {
            keyField: 'id',
            codeField: 'code',
            textField: 'text',
            maxResults: 30
        };

        const options = component.resolve(attrs);
        expect(options).toEqual(
            {
                codeField: 'code',
                keyField: 'id',
                label: 'jurisdiction',
                maxResults: 30,
                tagField: 'text',
                textField: 'text'
            });
    });

    it('should load the searchGroup configuarion with picklist and maintenance DisplayName', () => {
        const key = 'searchGroup';
        const options = {
            label: 'picklist.searchGroup.searchMenuGroup',
            keyField: 'key',
            textField: 'value',
            apiUrl: 'api/picklists/searchgroup',
            picklistDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceDisplayName: 'picklist.searchGroup.searchMenuGroup'
        };
        component.config(key, options);
        expect(component.globalOptions[key]).toEqual({
            apiUrl: 'api/picklists/searchgroup', keyField: 'key',
            label: 'picklist.searchGroup.searchMenuGroup',
            textField: 'value',
            picklistDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceDisplayName: 'picklist.searchGroup.searchMenuGroup'
        });
    });

    it('should load the picklist configuarion with DisplayField', () => {
        const key = 'searchGroup';
        const options = {
            label: 'picklist.searchGroup.searchMenuGroup',
            keyField: 'key',
            textField: 'value',
            showDisplayField: true,
            fieldType: TypeaheadFieldType.TextArea,
            apiUrl: 'api/picklists/searchgroup',
            picklistDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceDisplayName: 'picklist.searchGroup.searchMenuGroup'
        };
        component.config(key, options);
        expect(component.globalOptions[key]).toEqual({
            apiUrl: 'api/picklists/searchgroup', keyField: 'key',
            label: 'picklist.searchGroup.searchMenuGroup',
            textField: 'value',
            showDisplayField: true,
            fieldType: TypeaheadFieldType.TextArea,
            picklistDisplayName: 'picklist.searchGroup.searchMenuGroup',
            maintenanceDisplayName: 'picklist.searchGroup.searchMenuGroup'
        });
    });

    it('case picklist should not allow autobind on load', () => {
        const key = 'case';
        const options = {
            autobind: true,
            searchMoreInformation: 'caseSearch.moreInformation'
        };
        component.configuration();
        const config = component.globalOptions[key];
        expect(config.autobind).toBeFalsy();
    });

    it('casewithName picklist should not allow autobind on load', () => {
        const key = 'caseWithName';
        const options = {
            autobind: false,
            searchMoreInformation: 'caseSearch.moreInformation'
        };
        component.configuration();
        const config = component.globalOptions[key];
        expect(config.autobind).toBeFalsy();
    });
});
