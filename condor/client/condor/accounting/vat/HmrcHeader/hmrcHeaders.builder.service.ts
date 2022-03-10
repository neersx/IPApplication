namespace inprotech.accounting.vat {
    export interface IHmrcHeadersBuilderService {
        initialise(data: string): ng.IPromise<any>;
        getCurrentTimeZone(): string;
        getClientScreens(): string;
        getClientWindowSize(): string;
        getClientPublicIp(): ng.IPromise<any>;
        getclientDeviceId(): string;
        getclientBrowserDoNoTrack(): string;
        calculateCurrentTimeZone(): string;
        resolve();
    }

    export class HmrcHeadersBuilderService implements IHmrcHeadersBuilderService {
        static $inject: string[] = ['$http', '$window', '$sce', 'store', '$q'];
        private clientPublicIp: string;
        private deviceId: string;

        constructor(private $http: ng.IHttpService, private $window, private $sce: ng.ISCEService, private store, private $q: ng.IQService) {
        };

        initialise = (deviceId: string): ng.IPromise<any> => {
            this.deviceId = deviceId || this.deviceId;
            let deferred = this.$q.defer();
            if (this.clientPublicIp) {
                deferred.resolve(true);
                return deferred.promise;
            }
            return this.getClientPublicIp()
                .then(x => {
                    deferred.resolve(true);
                    return deferred.promise;
                });
        };

        getCurrentTimeZone = (): string => {
            return this.calculateCurrentTimeZone();
        };

        getClientScreens = (): string => {
            let scalingFactor = 1;
            scalingFactor = this.$window.devicePixelRatio;
            return 'width=' + this.$window.screen.availWidth + '&height=' + this.$window.screen.availHeight + '&colour-depth=' + this.$window.screen.colorDepth + '&scaling-factor=' + scalingFactor;
        };

        getClientWindowSize = (): string => {
            return 'width=' + this.$window.screen.width + '&height=' + this.$window.screen.height
        };

        getclientDeviceId = (): string => {
            if (this.store.local.get('clientDeviceId') === undefined) {
                this.store.local.set('clientDeviceId', this.deviceId);
            }
            return this.store.local.get('clientDeviceId');
        };

        getClientPublicIp = (): ng.IPromise<any> => {
            return this.$http.jsonp(this.$sce.trustAsResourceUrl('https://api.ipify.org?format=jsonp'), {
                jsonpCallbackParam: 'callback'
            })
            .then((resp: any) => {
                this.clientPublicIp = resp.data.ip;
                return;
            });
        };

        getclientBrowserDoNoTrack = (): string => {
            if (this.$window.doNotTrack || this.$window.navigator.doNotTrack || this.$window.navigator.msDoNotTrack || 'msTrackingProtectionEnabled' in this.$window.external) {
                if (this.$window.doNotTrack === '1' || this.$window.navigator.doNotTrack === 'yes' || this.$window.navigator.doNotTrack === '1' || this.$window.navigator.msDoNotTrack === '1' || this.$window.external.msTrackingProtectionEnabled()) {
                    return 'true';
                } else {
                    return 'false';
                }
            } else {
                return 'false';
            }
        };

        calculateCurrentTimeZone = (): string => {
            let currentTime = new Date();
            let currentTimezone = currentTime.getTimezoneOffset();
            currentTimezone = (currentTimezone / 60) * -1;
            let utc = 'UTC';
            if (currentTimezone !== 0) {
                utc += (currentTimezone > 0) ? '+' : '';
                if (String(currentTimezone).length === 1) {
                    utc += '0' + currentTimezone;
                } else {
                    utc += currentTimezone;
                }
                utc += ':00';
            }
            return utc;
        };

        resolve = () => {
            return {
                'x-inprotech-current-timezone': this.getCurrentTimeZone(),
                'x-inprotech-client-public-ip': this.clientPublicIp,
                'x-inprotech-client-screens': this.getClientScreens(),
                'x-inprotech-client-window-size': this.getClientWindowSize(),
                'x-inprotech-client-device-id': this.getclientDeviceId(),
                'x-inprotech-client-browser-do-not-track': this.getclientBrowserDoNoTrack()
            };
        };
    }

    angular.module('inprotech.accounting.vat')
        .service('HmrcHeadersBuilderService', HmrcHeadersBuilderService);
}