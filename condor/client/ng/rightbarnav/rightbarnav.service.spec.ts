import { RightBarNavService } from './rightbarnav.service';

describe('RightBarNavService', () => {
    let service: RightBarNavService;
    beforeEach(() => {
        service = new RightBarNavService();
    });

    it('Validate RegisterDefault', () => {
        const model = {
            options: {
                icon: 'cpa-icon-user'
            }
        };
        const data = service.registerDefault('userinfo', model as any);
        expect(data).toBeDefined();
    });

    it('notifyNewNavComponent Validate', () => {
        const option = {
            component: 'userinfo',
            options: {
                id: 'userinfo',
                icon: 'cpa-icon-user',
                title: 'quicknav.userinfo.title',
                tooltip: 'quicknav.userinfo.tooltip'
            }
        };
        service.notifyNewNavComponent('userinfo', option as any);
        expect(service).toBeDefined();
    });

    it('Validate getDefault', () => {
        const response = service.getDefault();
        expect(response).toBeDefined();
    });
});