import { NgControl } from '@angular/forms';
import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, ElementRefMock } from 'mocks';
import { IpxNumericComponent } from './ipx-numeric.component';

describe('IpxNumericComponent', () => {
    let component: IpxNumericComponent;
    const element = new ElementRefMock();
    beforeEach(() => {
        component = new IpxNumericComponent(AppContextServiceMock as any, element as any, NgControl as any, ChangeDetectorRefMock as any);
    });
    it('should initialize ipx numeric field', () => {
        expect(component).toBeTruthy();
    });
});