import { FormBuilder } from '@angular/forms';
import { CaseValidCombinationServiceMock, ChangeDetectorRefMock } from 'mocks';
import * as _ from 'underscore';
import { NavigationEnum } from '../ipx-picklist-search-field/ipx-picklist-search-field.component';
import { IpxPicklistCaseSearchPanelComponent } from './ipx-picklist-case-search-panel.component';

describe('IpxPicklistCaseSearchPanelComponent', () => {
    let component: IpxPicklistCaseSearchPanelComponent;
    let cdr: ChangeDetectorRefMock;
    let fb: FormBuilder;
    let vc: CaseValidCombinationServiceMock;
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        vc = new CaseValidCombinationServiceMock();
        fb = new FormBuilder();
        component = new IpxPicklistCaseSearchPanelComponent(cdr as any, fb as any, vc as any);
        component.model = '';
        component.searchForm = {
            setValue: jest.fn(),
            value: {}
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should initialize component correctly', () => {
        spyOn(component, 'createSearchPanelForm');
        spyOn(component, 'toggleSearchFieldAndPanel');
        component.navigation = NavigationEnum.current;
        component.ngOnInit();
        expect(component.createSearchPanelForm).toHaveBeenCalled();
        expect(component.showSearchBar).toBeTruthy();
    });

    it('should search correctly with text field', () => {
        spyOn(component.onSearch, 'emit');
        component.searchText = 'test';
        const value = component.prepareFilter(component.searchForm.value);
        component.search(value);
        expect(component.onSearch.emit).toHaveBeenCalled();
        expect(component.model).not.toBe(null);
    });

    it('should search correctly with search panel form', () => {
        spyOn(component.onSearch, 'emit');
        component.searchForm = {
            value: {
                dead: false,
                pending: true,
                registered: true,
                caseType: [{ key: 123, code: '123' }],
                jurisdiction: [{ key: 'AU' }, { key: 'US' }]
            }
        };

        const result = component.prepareFilter(component.searchForm.value);
        component.search();
        expect(component.onSearch.emit).toHaveBeenCalledWith({ action: '', value: result });
        expect(component.model.isPending).toBeTruthy();
        expect(component.model.isDead).toBeFalsy();
    });

    it('should clear correctly', () => {
        component.searchForm = {
            setValue: jest.fn()
        };
        spyOn(component.onClear, 'emit');
        jest.spyOn(component, 'toggleSearchFieldAndPanel');
        component.navigation = NavigationEnum.current;
        component.clear();
        expect(component.onClear.emit).toHaveBeenCalled();
    });

    it('should correctly toggle controls if text field has value', () => {
        component.navigation = NavigationEnum.current;
        expect(component.showSearchBar).toBeTruthy();
    });

    it('should get correct textsearch value', () => {
        const value = { value: 'search' };
        component.getTextValue(value);
        expect(component.searchText).toBe(value.value);
    });

    it('should allow checkbox check/uncheck on multiple selected checkbox', () => {
        component.searchForm = {
            value: {
                caseType: [{ key: 123, code: '123' }],
                jurisdiction: [{ key: 'AU' }, { key: 'US' }],
                dead: false,
                pending: true,
                registered: true
            }
        };

        const checkBoxes = _.pairs(component.searchForm.value).splice(2, 3);
        component.checkCaseStatus(checkBoxes);
        expect(component.lastCheckBox).toBe(undefined);
    });

    it('should not allow checkbox uncheck on single selected checkbox', () => {
        component.searchForm = {
            value: {
                caseType: [{ key: 123, code: '123' }],
                jurisdiction: [{ key: 'AU' }, { key: 'US' }],
                dead: false,
                pending: true,
                registered: false
            }
        };

        const checkBoxes = _.pairs(component.searchForm.value).splice(2, 3);
        component.checkCaseStatus(checkBoxes);
        expect(component.lastCheckBox).toEqual(['pending', true]);

        component.searchForm = {
            value: {
                caseType: [{ key: 123, code: '123' }],
                jurisdiction: [{ key: 'AU' }, { key: 'US' }],
                dead: false,
                pending: false,
                registered: false
            },
            patchValue: jest.fn()
        };
        const checkBoxess = _.pairs(component.searchForm.value).splice(2, 3);
        component.checkCaseStatus(checkBoxess);
        expect(component.searchForm.patchValue).toHaveBeenCalledWith({ pending: true });
    });
});
