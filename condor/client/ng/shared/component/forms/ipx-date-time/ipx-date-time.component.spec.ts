import { async } from '@angular/core/testing';

import { IpxDateTimeComponent } from './ipx-date-time.component';

describe('IpxDateComponent', () => {
    let component: IpxDateTimeComponent;
    beforeEach(async(() => {
        component = new IpxDateTimeComponent();
    }));
    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
