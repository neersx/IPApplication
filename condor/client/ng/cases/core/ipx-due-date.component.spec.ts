import { async } from '@angular/core/testing';
import { IpxDueDateComponent } from './ipx-due-date.component';

describe('IpxDueDateComponent', () => {
    let component: IpxDueDateComponent;
    beforeEach(async(() => {
        component = new IpxDueDateComponent();
    }));
    it('should create', () => {
        expect(component).toBeTruthy();
    });

});