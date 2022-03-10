'use strict';

class HmrcSettingsModel {
    constructor(public hmrcApplicationName: string = null, public clientId: string = null, public redirectUri: string = null, public clientSecret: string = null, public isProduction = false) {
    };
}