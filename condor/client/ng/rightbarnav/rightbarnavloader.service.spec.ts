import { ComponentFactoryResolverMock } from 'mocks/componentfactoryresolver.mock';
import { RightBarNavLoaderService } from './rightbarnavloader.service';

describe('RightBarNavLoaderService', () => {
    let service: RightBarNavLoaderService;
    const componentFactoryResolverMock = new ComponentFactoryResolverMock();
    beforeEach(() => {
        service = new RightBarNavLoaderService(componentFactoryResolverMock as any);
    });

    it('should create', () => {
        expect(service).toBeTruthy();
    });

    it('should remove', () => {
        service.remove();
        expect(service).toBeTruthy();
    });

    it('Validate load', () => {
        service.load = jest.fn(x => { return x; });
        const quickNavModel = {
            component: {},
            options: {
                id: 'userinfo',
                icon: 'cpa-icon-user',
                title: 'quicknav.userinfo.title',
                tooltip: 'quicknav.userinfo.tooltip'
            }
        };
        service.load(quickNavModel as any);
        expect(service).toBeDefined();
    });

});