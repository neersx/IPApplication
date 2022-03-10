// tslint:disable: no-string-literal
import { LocalSetting, LocalSettings } from './local-settings';
import { StorageMock } from './storage.mock';

export class LocalSettingsMock extends LocalSettings {
    storageMock: StorageMock;
    constructor() {
        const storageMock = new StorageMock();
        super(storageMock as any);

        this.storageMock = storageMock;
        const mockKeys = (obj) => {
            Object.keys(obj).forEach(key => {
                const sub = obj[key];
                if (!(sub instanceof LocalSetting)) {
                    mockKeys(sub);
                } else {
                    sub.setSession = jest.fn((value, suffix = '') => {
                        this['setSession'](value, sub, suffix);
                    });
                    sub.setLocal = jest.fn((value, suffix = '') => {
                        this['setLocal'](value, sub, suffix);
                    });
                }
            });
        };

        // setSession and setLocal functions overriden to remove the re-assigning of 'get..' inside real implementation, this makes it easier to unit test
        mockKeys(this.keys);
    }
}