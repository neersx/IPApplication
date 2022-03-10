import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { EventInformationComponent } from './event-information.component';

describe('EventInformationComponent', () => {

  let component: EventInformationComponent;
  let commonUtilityServiceMock: CommonUtilityServiceMock;
  const dateServiceSpy = { getParseFormats: jest.fn(), culture: 'en-US', dateFormat: 'testFormat' };

  beforeEach(() => {
    commonUtilityServiceMock = new CommonUtilityServiceMock();
    component = new EventInformationComponent(dateServiceSpy as any, commonUtilityServiceMock as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});