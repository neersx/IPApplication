import { of } from 'rxjs';
import { AccountingService } from '../accounting.service';
import { AgedTotalsComponent } from './aged-totals.component';
import { AgedTotalsService } from './aged-totals.service';

describe('AgedTotalsComponent', () => {
    let c: AgedTotalsComponent;
    let agedTotalsService: AgedTotalsService;
    let accountingService: AccountingService;
    let getCurrencyCodeSpy: any;
    let getWipDataSpy: any;
    let getAgedReceivablesSpy: any;

    beforeEach(() => {
        agedTotalsService = new AgedTotalsService(null);
        accountingService = new AccountingService(null);
        c = new AgedTotalsComponent(agedTotalsService, accountingService);
    });

    describe('loading the data with a caseKey', () => {
        it('calls the service to retrieve aged WIP balances data', () => {
            c.nameKey = 9876;
            c.caseKey = 1234;
            getCurrencyCodeSpy = spyOn(accountingService, 'getCurrencyCode').and.returnValue(of());
            getAgedReceivablesSpy = spyOn(agedTotalsService, 'getAgedReceivables').and.returnValue(of());
            getWipDataSpy = spyOn(agedTotalsService, 'getWipData').and.returnValue(of());
            c.ngOnInit();
            expect(getCurrencyCodeSpy).toHaveBeenCalled();
            expect(getWipDataSpy).toHaveBeenCalledWith(1234);
        });
    });

    describe('loading the data with a nameKey', () => {
        it('calls the service to retrieve aged receivable balances data', () => {
            c.caseKey = null;
            c.nameKey = 1234;
            getCurrencyCodeSpy = spyOn(accountingService, 'getCurrencyCode').and.returnValue(of());
            getAgedReceivablesSpy = spyOn(agedTotalsService, 'getAgedReceivables').and.returnValue(of());
            getWipDataSpy = spyOn(agedTotalsService, 'getWipData').and.returnValue(of());
            c.ngOnInit();
            expect(getCurrencyCodeSpy).toHaveBeenCalled();
            expect(getAgedReceivablesSpy).toHaveBeenCalledWith(1234);
        });
    });
});
