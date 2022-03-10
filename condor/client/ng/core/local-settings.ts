import { Injectable } from '@angular/core';
import { Storage } from './storage';

export class LocalSetting {
    name: string;
    defaultValue: string;
    /**
     * Calls the "getLocalValue" function to get the value, this helps in deffering the resolve of properties untill needed
     */
    get getLocal(): any {
        return this.getLocalValue();
    }
    /**
     * Calls the "getSessionValue" function to get the value, this helps in deffering the resolve of properties untill needed
     */
    get getSession(): any {
        return this.getSessionValue();
    }
    getLocalValue: () => any;
    getLocalwithSuffix: (suffix?: string) => any;
    setLocal: (value: any, suffix?: string) => void;
    getSessionValue: () => any;
    getSessionwithSuffix: (suffix?: string) => any;
    setSession: (value: any, suffix?: string) => void;
    removeLocal: (suffix?: string) => any;
    constructor(defaultValue?: any) {
        this.defaultValue = defaultValue;
    }
}

@Injectable()
export class LocalSettings {

    // expand the keys for any new store settings
    keys = {
        currencies: {
            pageSize: new LocalSetting(20),
            columnsSelection: new LocalSetting()
        },
        exchangeRateSchedule: {
            pageSize: new LocalSetting(20),
            columnsSelection: new LocalSetting()
        },
        exchangeRateHistory: {
            pageSize: new LocalSetting(10),
            columnsSelection: new LocalSetting()
        },
        recentCases: {
            expanded: new LocalSetting(false)
        },
        attachment: {
            columnsSelection: new LocalSetting()
        },
        caseView: {
            importanceLevelCacheKey: new LocalSetting('1'),
            actionOptions: {
                includeOpenActions: new LocalSetting(true),
                includeClosedActions: new LocalSetting(false),
                includePotentialActions: new LocalSetting(false)
            },
            eventOptions: {
                isAllEvents: new LocalSetting(false),
                isAllEventDetails: new LocalSetting(false),
                isAllCycles: new LocalSetting(false)
            },
            actions: {
                pageNumber: new LocalSetting(5),
                eventPageNumber: new LocalSetting(10),
                eventsColumnsSelection: new LocalSetting()
            },
            events: {
                due: {
                    pageSize: new LocalSetting(20),
                    columnsSelection: new LocalSetting(),
                    importanceLevelCacheKey: new LocalSetting('1')
                },
                occurred: {
                    pageSize: new LocalSetting(20),
                    columnsSelection: new LocalSetting(),
                    importanceLevelCacheKey: new LocalSetting('1')
                }
            },
            relatedCases: {
                columnsSelection: new LocalSetting(),
                pageNumber: new LocalSetting(10)
            },
            criticalDates: {
                datesColumnsSelection: new LocalSetting()
            },
            checklist: {
                pageSize: new LocalSetting(20),
                columnsSelection: new LocalSetting()
            },
            designElement: {
                pageSize: new LocalSetting(5)
            },
            affectedCases: {
                pageSize: new LocalSetting(20),
                setStepStatus: new LocalSetting(false)
            },
            documentManagement: {
                pageSize: new LocalSetting(10)
            },
            fileLocations: {
                pageSize: new LocalSetting(10)
            },
            attachmentsModal: {
                columnsSelection: new LocalSetting(),
                pageNumber: new LocalSetting(10)
            }
        },
        accounting: {
            timesheet: {
                columnsSelection: new LocalSetting(),
                hidePreview: new LocalSetting(false),
                hideFutureYearWarning: new LocalSetting(),
                posting: {
                    pageSize: new LocalSetting(10)
                },
                gapsTimeRange: new LocalSetting()
            },
            timeSearch: {
                columnsSelection: new LocalSetting(),
                pageSize: new LocalSetting(10),
                periodSelection: new LocalSetting()
            },
            billing: {
                wipFilterRenewal: new LocalSetting(2),
                showAmountColumn: new LocalSetting(2)
            }
        },
        userConfiguration: {
            roles: {
                showDescription: new LocalSetting(false)
            }
        },
        configuration: {
            taxcodes: {
                sourceJurisdiction: new LocalSetting(false)
            }
        },

        priorart: {
            search: {
                sourcePageSize: new LocalSetting(20),
                literaturePageSize: new LocalSetting(20),
                notFoundPageSize: new LocalSetting(10),
                caseResultSize: new LocalSetting(10)
            },
            citationsListPageSize: new LocalSetting(20),
            linkedCasesPageSize: new LocalSetting(20),
            linkedFamilyCaseListGrid: new LocalSetting(10),
            linkedNameGrid: new LocalSetting(10),
            linkedFamilyCaseDetailsGrid: new LocalSetting(10)
        },
        typeahead: {
            pageSize: {
                default: new LocalSetting(20),
                names: new LocalSetting(20),
                documents: new LocalSetting(20)
            },
            picklist: {
                previewActive: new LocalSetting(false)
            },
            columnSelection: {
                questions: new LocalSetting()
            }
        },
        caseSearch: {
            pageSize: {
                default: new LocalSetting(50)
            },
            showPreview: new LocalSetting(false)
        },
        taskPlanner: {
            showPreview: new LocalSetting(false),
            summary: {
                caseSummary: new LocalSetting(true),
                caseNames: new LocalSetting(true),
                criticalDates: new LocalSetting(true),
                taskDetails: new LocalSetting(false),
                delegationDetails: new LocalSetting(false)
            },
            showReminderComments: new LocalSetting(true),
            showEventNotes: new LocalSetting(true),
            showFilterArea: new LocalSetting(true),
            showStaff: new LocalSetting(true),
            showSignatory: new LocalSetting(true),
            showCriticalList: new LocalSetting(false),
            showEmailReminder: new LocalSetting(false)
        },
        screenDesigner: {
            search: {
                columnsSelection: new LocalSetting()
            },
            inheritance: {
                showSummary: new LocalSetting()
            }
        },
        checklistSearch: {
            search: {
                columnsSelection: new LocalSetting()
            }
        },
        homePageState: new LocalSetting(),
        bulkUpdate: {
            data: new LocalSetting()
        },
        wipOverview: {
            singleBillData: new LocalSetting()
        },
        exchangeRateVariation: {
            data: new LocalSetting()
        },
        nameView: {
            trustAccounting: {
                pageNumber: new LocalSetting(10),
                columnsSelection: new LocalSetting()
            },
            trustAccountingDetails: {
                pageNumber: new LocalSetting(10),
                columnsSelection: new LocalSetting()
            }
        },
        keywords: {
            pageSize: new LocalSetting(10)
        },
        navigation: {
            ids: new LocalSetting([]),
            searchCriteria: new LocalSetting(),
            queryParams: new LocalSetting()
        }
    };

    constructor(private readonly store: Storage) {
        this.flatten('', this.keys);
    }

    private readonly flatten = (prefix: string, setting: any) => {
        if (setting instanceof LocalSetting) {
            setting.name = prefix;
            setting.getLocalValue = () => this.getLocal(setting);
            setting.getLocalwithSuffix = (suffix = '') => this.getLocal(setting, suffix);
            setting.setLocal = (value, suffix = '') => {
                this.setLocal(value, setting, suffix);
                if (!suffix) {
                    setting.getLocalValue = () => value; // cached value until been set
                }
            };
            setting.getSessionValue = () => this.getSession(setting);
            setting.getSessionwithSuffix = (suffix = '') => this.getSession(setting, suffix);
            setting.setSession = (value, suffix = '') => {
                this.setSession(value, setting, suffix);
                if (!suffix) {
                    setting.getSessionValue = () => value; // cached value until been set
                }
            };
            setting.removeLocal = (suffix = '') => {
                this.removeLocal(setting, suffix);
                setting.getLocalValue = () => void 0;
                setting.defaultValue = void 0;
            };
        } else {
            for (const key in setting) {
                if (setting.hasOwnProperty(key)) {
                    this.flatten(this.getPrefix(prefix, key), setting[key]);
                }
            }
        }
    };

    private readonly getPrefix = (prefixKey: string, property = '') => {
        if (!prefixKey) { return property; }

        return prefixKey + '.' + property;
    };

    private readonly getLocal = (setting: LocalSetting, suffix = ''): string =>
        this.store.local.get(setting.name + suffix) != null ? this.store.local.get(setting.name + suffix) : setting.defaultValue;

    private readonly setLocal = (value: any, setting: LocalSetting, suffix = '') =>
        this.store.local.set(setting.name + suffix, value);

    private readonly getSession = (setting: LocalSetting, suffix = ''): string =>
        this.store.session.get(setting.name + suffix) != null ? this.store.session.get(setting.name + suffix) : setting.defaultValue;

    private readonly setSession = (value: any, setting: LocalSetting, suffix = '') =>
        this.store.session.set(setting.name + suffix, value);

    private readonly removeLocal = (setting: LocalSetting, suffix = '') =>
        this.store.local.remove(setting.name + suffix);

}
