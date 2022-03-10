import { async } from '@angular/core/testing';

import { IpxDateComponent } from './ipx-date.component';

describe('IpxDateComponent', () => {
    let component: IpxDateComponent;
    beforeEach(async(() => {
        component = new IpxDateComponent();
    }));
    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
