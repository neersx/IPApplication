import { AppContextServiceMock } from './app-context.service.mock';
import { FeatureDetection } from './feature-detection';
import { WindowRefMock } from './window-ref.mock';

describe('feature detection', () => {

    let service: (ctx?, window?) => FeatureDetection;
    let appContext: AppContextServiceMock;
    const getWindowRef = (userAgent?: string): WindowRefMock => {
        const windowRef = new WindowRefMock();
        windowRef.nativeWindow = {
            navigator: {
                userAgent: userAgent || 'MSIE '
            }
        } as any;

        return windowRef;
    };

    beforeEach(() => {
        appContext = new AppContextServiceMock();
        service = (window) => {
            return new FeatureDetection(appContext as any, window || getWindowRef());
        };
    });

    describe('check Browser', () => {
        it('checks for ie', () => {
            let r = service().isIe();
            expect(r).toBeTruthy();

            r = service(getWindowRef('Trident/')).isIe();
            expect(r).toBeTruthy();
        });

        it('Returns false for non ie', () => {
            let r = service(getWindowRef('Chrome ')).isIe();
            expect(r).toBeFalsy();

            r = service(getWindowRef('Firefox ')).isIe();
            expect(r).toBeFalsy();
        });

    });

    describe('check inprotech version', () => {
        const setInprotechVersion: (v?: string) => void = (v) => {
            appContext.appContext = {
                systemInfo: {
                    inprotechVersion: v || 'v13'
                }
            };
        };
        it('checks for Release13', () => {
            setInprotechVersion();
            const s = service();
            const check = () => s.hasSpecificRelease$(13).subscribe(res => {
                expect(res).toBeTruthy();
            });
            check();

            setInprotechVersion('v13.0.5');
            check();

            setInprotechVersion('v14.0.5');
            check();

            setInprotechVersion('v 15.0.5');
            check();
        });

        it('checks if not Release13', () => {
            setInprotechVersion('abcd');
            const s = service();
            const check = () => s.hasSpecificRelease$(13).subscribe(res => {
                expect(res).toBeFalsy();
            });
            check();

            setInprotechVersion('v1.3.5');
            check();

            setInprotechVersion('v4.0.5');
            check();

            setInprotechVersion('v 10.15.5');
            check();
        });

        it('checks versions', () => {
            setInprotechVersion('v10.15.5');
            const s = service();
            s.hasSpecificRelease$(13).subscribe(res => {
                expect(res).toBeFalsy();
            });

            setInprotechVersion('v14.0.5');
            s.hasSpecificRelease$(13).subscribe(res => {
                expect(res).toBeTruthy();
            });
        });
    });

    it('gets the url', () => {
        const s = service();
        const url = window.location;
        const baseUrl = url.protocol + '//' + url.host;
        expect(s.getAbsoluteUrl('/abc')).toEqual(baseUrl + '/abc');
        expect(s.getAbsoluteUrl('../abc')).toEqual(baseUrl + '/abc');
    });

});
