
import { IpxUserColumnUrlComponent } from './ipx-user-column-url.component';

describe('IpxHostedUrlComponent', () => {
    let component: IpxUserColumnUrlComponent;
    beforeEach(() => {
        component = new IpxUserColumnUrlComponent();
    });
    it('should initialize IpxUserColumnUrlComponent', () => {
        expect(component).toBeTruthy();
    });

    it('should checkUrl with no display name', () => {
        component.userUrl = 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487';
        component.checkUrl();
        expect(component.isDisplayName).toEqual(false);
    });
    it('should checkUrl with display name', () => {
        component.userUrl = '[Case 1234/A Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487]';
        component.checkUrl();
        expect(component.displayName).toEqual('Case 1234/A Link');
        expect(component.href).toEqual('http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487');
        expect(component.isDisplayName).toEqual(true);
    });
});