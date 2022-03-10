import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { AppContextService } from './app-context.service';
import { WindowRef } from './window-ref';

@Injectable()
export class FeatureDetection {
    private a: any = null;
    private readonly ieData: { loaded: boolean, isIe: boolean } = {
        loaded: false,
        isIe: false
    };

    constructor(private readonly appContextService: AppContextService, private readonly windowRef: WindowRef) { }

    isIe = (): boolean => {
        if (this.ieData.loaded) {
            return this.ieData.isIe;
        }

        const ua = this.windowRef.nativeWindow.navigator.userAgent;
        if ((ua.indexOf('MSIE ') > -1) || (ua.indexOf('Trident/') > -1)) {
            this.ieData.isIe = true;
        }
        this.ieData.loaded = true;

        return this.ieData.isIe;
    };

    hasSpecificRelease$ = (release): Observable<boolean> => {
        return this.appContextService.appContext$
            .pipe(map(ctx => {
                const v = this.formatMajorVersion(ctx.systemInfo.inprotechVersion);
                if (v >= release) {
                    return true;
                }

                return false;
            }))
            .pipe(take(1));
    };

    getAbsoluteUrl = (url): string => {
        this.a = this.a || document.createElement('a');
        this.a.href = url;

        return this.a.href;
    };

    private readonly formatMajorVersion = (version: string): number => {
        if (version) {
            // tslint:disable-next-line: no-parameter-reassignment
            version = version.replace('v', '');
            const tokens = version.split('.');
            let major: number;
            if (!isNaN(major = Number(tokens[0]))) {
                return major;
            }
        }

        return 0;
    };
}