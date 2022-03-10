import { fakeAsync, tick } from '@angular/core/testing';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, GridNavigationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { CurrenciesServiceMock } from '../currencies.service.mock';
import { ExchangeRateHistoryComponent } from './exchange-rate-history.component';

describe('Inprotech.Configuration.exchangeRateHistory', () => {
    let component: ExchangeRateHistoryComponent;
    let service: CurrenciesServiceMock;
    let localSettings: LocalSettingsMock;
    let gridNavigationService: GridNavigationServiceMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    let modelRef: BsModalRefMock;
    beforeEach(() => {
        service = new CurrenciesServiceMock();
        localSettings = new LocalSettingsMock();
        modelRef = new BsModalRefMock();
        gridNavigationService = new GridNavigationServiceMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new ExchangeRateHistoryComponent(service as any, modelRef as any, localSettings as any, gridNavigationService as any, destroy$, shortcutsService as any);
        component.navData = {
            keys: [{ key: '1', value: 'AUS' }, { key: '2', value: 'IND' }, { key: '3', value: 'USD' }, { key: '4', value: 'BBD' }],
            totalRows: 4,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
        component.currencyId = 'IND';
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
    });

    it('should initialise', () => {
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(6);
        expect(component.gridOptions.columns[0].title).toBe('currencies.history.columns.effectiveDate');
        expect(component.gridOptions.columns[1].field).toBe('bankRate');

        expect(component.canNavigate).toBe(true);
        expect(component.navData.keys.length).toEqual(4);
        expect(component.currentKey).toEqual('2');
    });

    it('should call service GetCurrencyDesc', () => {
        component.ngOnInit();
        expect(service.getCurrencyDesc).toHaveBeenCalledWith('IND');
    });

    it('should call modal close on cancel', () => {
        component.cancel();
        expect(modelRef.hide).toHaveBeenCalled();
    });

    it('should call revert if shortcut is given', fakeAsync(() => {
        component.cancel = jest.fn();
        shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
        component.ngOnInit();
        tick(shortcutsService.interval);
        expect(component.cancel).toHaveBeenCalled();
    }));
});