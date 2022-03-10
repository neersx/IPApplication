
import { IpxHostedUrlComponent } from './ipx-hosted-url.component';

describe('IpxHostedUrlComponent', () => {
    let component: IpxHostedUrlComponent;
    let rootScopeService: any;
    let windowParentMessagingService: any;
    beforeEach(() => {
        rootScopeService = { isHosted: false, rootScope: { hostedProgramId: null } };
        windowParentMessagingService = {};
        component = new IpxHostedUrlComponent(rootScopeService, windowParentMessagingService);
    });
    it('should initialize IpxHostedUrlComponent', () => {
        expect(component).toBeTruthy();
    });
});