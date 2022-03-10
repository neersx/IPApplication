import { HttpClient } from '@angular/common/http';
import { ChangeDetectorRefMock } from 'mocks';
import { Observable, of } from 'rxjs';
import { NamesSummaryPaneComponent } from './names-summary-pane.component';

describe('NamesSummaryPaneComponent', () => {
  let component: NamesSummaryPaneComponent;
  let changeDetectorMock: ChangeDetectorRefMock;
  let serviceMock: any;

  beforeEach(() => {
    serviceMock = { getName: jest.fn().mockReturnValue(of().toPromise()) };
    changeDetectorMock = new ChangeDetectorRefMock();
    component = new NamesSummaryPaneComponent(serviceMock, changeDetectorMock as any);
  });

  it('should create with no detail data', () => {
    expect(component).toBeTruthy();
    expect(component.nameDetailData).toBeFalsy();
  });

  it('should load name detail data on name being changed', () => {
    const expectedValue = { test: 'test'};
    serviceMock.getName.mockReturnValue(of(expectedValue).toPromise());

    component.nameId = 1;

    expect(serviceMock.getName).toBeCalled();
    serviceMock.getName().then(() => {
      expect(component.nameDetailData).toEqual(expectedValue);
      expect(changeDetectorMock.markForCheck).toHaveBeenCalled();
    });
  });

  it('should load not name detail data on name being changed to null', () => {
    const expectedValue = { test: 'test'};
    serviceMock.getName.mockReturnValue(of(expectedValue).toPromise());

    component.nameId = null;

    expect(serviceMock.getName).not.toBeCalled();
    expect(component.nameDetailData).toBeNull();
  });
});
