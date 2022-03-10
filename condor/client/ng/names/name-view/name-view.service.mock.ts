import { BehaviorSubject, Observable, of } from 'rxjs';

export class NameViewServiceMock {
    maintainName$: (data: any) => Observable<any> = jest.fn().mockReturnValue(of(true));
    getNameViewData$: (nameId: Number) => Observable<any> = jest.fn();
    getSupplierDetails$: (nameId: Number) => Observable<any> = jest.fn();
    getTrustAccounting$ = jest.fn().mockReturnValue(new Observable<boolean>());
    savedSuccessful = new BehaviorSubject(false);
}