export class LocalSettingsMocks {
    keys = {
        typeahead:
        {
            pageSize: {
                default: jest.spyOn
            },
            columnSelection: {
                questions: jest.spyOn
            }
        },
        homePageState: {
            getLocal: jest.spyOn, setLocal: jest.fn()
        },
        caseSearch: {
            showPreview: {
                getLocal: false
            }
        },
        bulkUpdate: {
            data: {
                getLocal: { caseIds: '12,23' },
                setLocal: jest.fn(),
                getSession: { caseIds: '12,23' },
                setSession: jest.fn()
            }
        },
        accounting: {
            timesheet: {
                posting: {
                    pageSize: {
                        getLocal: jest.fn()
                    }
                }
            },
            billing: {
                wipFilterRenewal: {
                    getSession: 2,
                    setSession: jest.fn()
                },
                showAmountColumn: {
                    getSession: 2,
                    setSession: jest.fn()
                }
            }
        }
    };
    pageSize = { default: jest.spyOn };
}