import { BehaviorSubject, of } from 'rxjs';

export class BillingServiceMock {
    getSettings$ = jest.fn().mockReturnValue(of({}));
    getOpenItem$ = jest.fn().mockReturnValue(of({ ItemType: 510 }));
    openItemData$ = new BehaviorSubject({ OpenItemNo: '1', LanguageDescription: 'English', ItemDate: new Date(), ItemEntityId: 123 });
    originalDebtorList$ = new BehaviorSubject(of(null));
    currentAction$ = new BehaviorSubject({});
    reasonList$ = new BehaviorSubject({});
    currentLanguage$ = new BehaviorSubject({ id: 1, description: 'English' });
    revertChanges$ = new BehaviorSubject({ entity: 'Action', value: { key: 1, code: 'RN' }, oldValue: null });
    copiesToCount$ = new BehaviorSubject({ debtorNameId: 1, count: 2 });
    // openItemData$ = { getValue: jest.fn().mockReturnValue(true), next: jest.fn() } as any,
    setValidAction = jest.fn();
    billSettings$ = new BehaviorSubject({
        MinimumWipReasonCode: 'R',
        MinimumWipValues: [{ WipCode: 'CORR' }, { WipCode: 'CER' }]
    });
    getBillSettings$ = jest.fn().mockReturnValue(of({
        MinimumWipReasonCode: 'R',
        MinimumWipValues: [{ WipCode: 'CORR' }, { WipCode: 'CER' }]
    }));
    entityChange$ = new BehaviorSubject(of(null));
}

export class BillingStateServiceMock {
    go = jest.fn();
    $current = { name: jest.spyOn };
    params = { type: 510, openItemNo: '1', entityId: 1 };
    reload = jest.fn();
    current = { name: jest.spyOn };
}

export class ItemDateValidatorMock {
    validateItemDate = jest.fn();
}