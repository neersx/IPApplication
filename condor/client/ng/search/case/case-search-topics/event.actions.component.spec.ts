import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock, DateHelperMock } from 'mocks';
import { SearchOperator } from 'search/common/search-operators';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { EventActionsComponent } from './event.actions.component';
describe('EventActionsComponent', () => {
    let c: EventActionsComponent;
    let viewData: any;
    let cdr: ChangeDetectorRefMock;
    const caseHelpermock = new CaseSearchHelperServiceMock();
    beforeEach(() => {
        cdr = new ChangeDetectorRefMock();
        c = new EventActionsComponent(DateHelperMock as any, StepsPersistanceSeviceMock as any,
            caseHelpermock as any, cdr as any);
        c.importanceLevelOptions = [{ key: '0', value: 'important' }];
        c.showEventNoteType = true;
        c.showEventNoteSection = false;
        viewData = {
            isExternal: false,
            importanceOptions: [{ key: '0', value: 'important' }],
            showEventNoteType: true,
            showEventNoteSection: false
        };
        c.topic = {
            params: {
                viewData
            },
            key: 'eventsActions',
            title: 'eventsActions'
        };
    });

    it('should create the component', async(() => {
        expect(c).toBeTruthy();
    }));

    it('initialises defaults', () => {
        expect(c.importanceLevelOptions).toEqual(viewData.importanceOptions);
        expect(c.showEventNoteType).toEqual(viewData.showEventNoteType);
        expect(c.showEventNoteSection).toEqual(viewData.showEventNoteSection);
    });

    it('Should get event operator Correctly', () => {
        c.formData = {
            eventOperator: 'sd',
            eventDatesOperator: '11011'
        };

        const output = c.getEventOperatorKey(c.formData);
        expect(output).toEqual('11011');
    });

    it('should get build event Correctly', () => {
        c.formData = {
            eventOperator: 'L',
            eventWithinValue: { type: 'D', value: '20' },
            eventNotesOperator: '5',
            occurredEvent: true,
            dueEvent: false,
            includeClosedActions: false,
            isRenewals: true,
            isNonRenewals: false,
            actionIsOpen: false,
            event: { key: '11011', value: 'P' }
        };

        jest.spyOn(caseHelpermock, 'getKeysFromTypeahead');
        jest.spyOn(caseHelpermock, 'buildFromToValues');
        jest.spyOn(caseHelpermock, 'buildStringFilter');

        const eventResult = c.buildEvent(c.formData);
        expect(caseHelpermock.getKeysFromTypeahead).toHaveBeenCalledWith(c.formData.event, true);
        expect(caseHelpermock.buildStringFilter).toHaveBeenCalledWith(undefined, '5');
        expect(eventResult.period).toEqual({ type: 'D', quantity: '-20' });
        c.formData = {
            eventOperator: 'N',
            eventWithinValue: { type: 'D', value: '20' },
            eventNotesOperator: '5',
            occurredEvent: true,
            dueEvent: false,
            includeClosedActions: false,
            isRenewals: true,
            isNonRenewals: false,
            actionIsOpen: false,
            event: { key: '11011', value: 'P' }
        };
        const eventResultPositive = c.buildEvent(c.formData);
        expect(eventResultPositive.period).toEqual({ type: 'D', quantity: '20' });
    });

    it('should reset event to compare on event change', () => {
        c.formData = {
            event: []
        };

        c.onEventChange();
        expect(c.formData.eventForCompare).toEqual([]);
    });

    it('should disable event to compare when event picklist is emoty', () => {
        c.formData = {
            event: []
        };

        expect(c.isEventToCompareDisabled()).toBeTruthy();
    });

    it('verify isImportanceLevelDisabled with equalto eventOperator', () => {
        c.formData = { eventOperator: SearchOperator.equalTo };
        const output = c.isImportanceLevelDisabled();
        expect(output).toBeTruthy();
    });

    it('verify isImportanceLevelDisabled with lessThan eventOperator', () => {
        c.formData = { eventOperator: SearchOperator.lessThan };
        const output = c.isImportanceLevelDisabled();
        expect(output).toBeFalsy();
    });

});