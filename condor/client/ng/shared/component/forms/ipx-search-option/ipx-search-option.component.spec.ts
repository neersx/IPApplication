import { SearchOptionComponent } from './ipx-search-option.component';

describe('HeaderComponent', () => {
    let component: SearchOptionComponent;
    let focusService: any;
    beforeEach(() => {
        focusService = {};
        component = new SearchOptionComponent(focusService);
    });
    it('should initialize SearchOptionComponent', () => {
        expect(component).toBeTruthy();
    });

    it('should call onclear method with emit of clear variable', () => {
        component.isResetDisabled = false;
        spyOn(component.clear, 'emit');
        component.onClear();
        expect(component.clear.emit).toHaveBeenCalled();
    });

    it('should call dosearch method with emit of search variable', () => {
        component.isResetDisabled = false;
        spyOn(component.search, 'emit');
        component.doSearch();
        expect(component.search.emit).toHaveBeenCalled();
    });

    it('should call validate method', () => {
        component.onValidate();
        component.isResetDisabled = false;
        spyOn(component.search, 'emit');
        component.doSearch();
        expect(component.search.emit).toHaveBeenCalled();
    });
});