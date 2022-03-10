namespace inprotech.core {
    export interface IFeatureDetection {
        isIe(): boolean;
        hasRelease13(): boolean;
        hasRelease16(): boolean;
        getAbsoluteUrl(url: string): string;
    }

    export class FeatureDetection implements IFeatureDetection {
        private a: any = null;
        private ieData: { loaded: boolean, isIe: boolean } = {
            loaded: false,
            isIe: false
        }
        constructor(private $rootScope: any, private $window: ng.IWindowService) {

        }
        isIe(): boolean {
            if (this.ieData.loaded) {
                return this.ieData.isIe;
            }

            let ua = this.$window.navigator.userAgent;
            if ((ua.indexOf('MSIE ') > -1) || (ua.indexOf('Trident/') > -1)) {
                this.ieData.isIe = true;
            }
            this.ieData.loaded = true;
            return this.ieData.isIe;
        }

        hasRelease13(): boolean {

            let v = this.formatMajorVersion(this.$rootScope.appContext.systemInfo.inprotechVersion);
            if (v >= 13 && v < 16) {
                return true;
            }
            return false;
        }

        hasRelease16(): boolean {

            let v = this.formatMajorVersion(this.$rootScope.appContext.systemInfo.inprotechVersion);
            if (v >= 16) {
                return true;
            }
            return false;
        }

        getAbsoluteUrl(url: string): string {
            this.a = this.a || document.createElement('a');
            this.a.href = url;
            return this.a.href;
        }

        private formatMajorVersion(version: string): number {
            if (version) {
                version = version.replace('v', '');
                let tokens = version.split('.');
                let major: number;
                if (!isNaN(major = Number(tokens[0]))) {
                    return major;
                }
            }
            return 0;
        }
    }

    angular.module('inprotech.core').service('featureDetection', ['$rootScope', '$window', FeatureDetection]);
}