import { assert } from 'console';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { EventInformationComponent } from './event-information.component';
import { EventOtherDetailsComponent } from './event-other-details.controller';

describe('EventInformationComponent', () => {
    let component: EventOtherDetailsComponent;

    beforeEach(() => {
        component = new EventOtherDetailsComponent();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should encode data', () => {
        const result = component.encodeLinkData({ nameKey: '1@3#$%^KKK' });
        expect(result).toEqual('%7B%22nameKey%22%3A%221%403%23%24%25%5EKKK%22%7D');
    });
});