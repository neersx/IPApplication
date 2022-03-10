'use strict';
namespace inprotech.core {
    export class LocalSetting {
        public name: String;
        public defaultValue: String;
        public getLocal: any;
        public getLocalwithSuffix: any;
        public setLocal: any;
        public getSession: any;
        public getSessionwithSuffix: any;
        public setSession: any;
        public removeLocal: any;
        constructor(defaultValue?: any) {
            this.defaultValue = defaultValue;
        }
    }

    export class LocalSettings {

        // expand the keys for any new store settings
        public Keys = {
            caseImport: {
                status: {
                    pageNumber: new LocalSetting('50')
                },
                batchSummary: {
                    pageNumber: new LocalSetting('50')
                }
            },
            caseView: {
                actions: {
                    eventPageNumber: new LocalSetting('10'),
                    eventsColumnsSelection: new LocalSetting()
                },
                criticalDates: {
                    datesColumnsSelection: new LocalSetting()
                },
                actionPageNumber: new LocalSetting('5'), // Default value
                importanceLevelCacheKey: new LocalSetting('1'),
                names: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting()
                },
                classes: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting()
                },
                events: {
                    due: {
                        pageNumber: new LocalSetting('10'),
                        importanceLevelCacheKey: new LocalSetting('1'),
                        columnsSelection: new LocalSetting()
                    },
                    occurred: {
                        pageNumber: new LocalSetting('10'),
                        importanceLevelCacheKey: new LocalSetting('1'),
                        columnsSelection: new LocalSetting()
                    }
                },
                relatedCases: {
                    columnsSelection: new LocalSetting(),
                    pageNumber: new LocalSetting('10')
                },
                designatedJurisdiction: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting()
                },
                texts: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting()
                },
                eFiling: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting(),
                    historyPageNumber: new LocalSetting('10')
                },
                designElement: {
                    pageNumber: new LocalSetting('10'),
                    columnsSelection: new LocalSetting(),
                }
            },
            exchangeIntegration: {
                exchangeIntegrationQueue: {
                    pageNumber: new LocalSetting('50')
                }
            },
            accounting: {
                vatObligations: {
                    columnsSelection: new LocalSetting()
                },
                vatLogs: {
                    columnsSelection: new LocalSetting()
                },
		        timesheet: {
                    columnsSelection: new LocalSetting()
                }
            },
            policing: {
                savedRequests: {
                    pageNumber: new LocalSetting('20')
                }
            }
        }

        constructor(private store: any) {
            this.flatten(null, this.Keys);
        }

        private flatten = (prefix: string, setting: any) => {
            if (setting instanceof LocalSetting) {
                setting.name = prefix;
                setting.getLocal = this.getLocal(setting);
                setting.getLocalwithSuffix = (suffix = '') => { return this.getLocal(setting, suffix); }
                setting.setLocal = (value, suffix = '') => {
                    this.setLocal(value, setting, suffix);
                    if (!suffix) {
                        setting.getLocal = value; // cached value until been set
                    }
                };
                setting.getSession = this.getSession(setting);
                setting.getSessionwithSuffix = (suffix = '') => { return this.getSession(setting, suffix); }
                setting.setSession = (value, suffix = '') => {
                    this.setSession(value, setting, suffix);
                    if (!suffix) {
                        setting.getSession = value; // cached value until been set
                    }
                };
                setting.removeLocal = (suffix = '') => {
                    this.removeLocal(setting, suffix);
                    setting.getLocal = void 0;
                    setting.defaultValue = void 0;
                };
            } else {
                for (let key in setting) {
                    if (setting.hasOwnProperty(key)) {
                        this.flatten(this.getPrefix(prefix, key), setting[key]);
                    }
                }
            }
        }

        private getPrefix = (prefixKey: string, property = '') => {
            if (!prefixKey) { return property; }
            return prefixKey + '.' + property;
        }

        private getLocal(setting, suffix = ''): String {
            return this.store.local.get(setting.name + suffix) || setting.defaultValue;
        }
        private setLocal(value, setting, suffix = '') {
            this.store.local.set(setting.name + suffix, value);
        }
        private getSession(setting, suffix = ''): String {
            return this.store.session.get(setting.name + suffix) || setting.defaultValue;
        }
        private setSession(value, setting, suffix = '') {
            this.store.session.set(setting.name + suffix, value);
        }
        private removeLocal(setting, suffix = '') {
            this.store.local.remove(setting.name + suffix);
        }
    }

    angular.module('inprotech.core').service('localSettings', ['store', LocalSettings]);
}