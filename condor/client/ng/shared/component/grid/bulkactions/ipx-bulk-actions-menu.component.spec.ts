// tslint:disable: no-unbound-method
import { ChangeDetectorRefMock, ElementRefMock, Renderer2Mock } from 'mocks';
import { IpxKendoGridComponentMock } from '../ipx-kendo-grid.component.mock';
import { BulkActionsMenuComponent } from './ipx-bulk-actions-menu.component';

describe('Grid Bulk Action Menu', () => {
    let component: BulkActionsMenuComponent;
    let renderer: any;
    let event;
    let grid: IpxKendoGridComponentMock;
    let cdr: ChangeDetectorRefMock;
    beforeEach(() => {
        event = { stopPropagation: jest.fn() };
        renderer = new Renderer2Mock();
        grid = new IpxKendoGridComponentMock();
        cdr = new ChangeDetectorRefMock();
        grid.getCurrentData.mockReturnValue([{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }]);
        component = new BulkActionsMenuComponent(new ElementRefMock(), renderer, grid as any, cdr as any);
        component.actionItems = [];
    });

    describe('initialization and default ui buttons', () => {
        it('should be initialized', () => {
            component.ngOnInit();

            expect(component.isOpen).toBe(false);
            expect(component.items.selected).toEqual(0);
            expect(component.items.totalCount).toEqual(0);
            expect(renderer.setStyle.mock.calls.length).toEqual(2);
        });

        it('should show hide control on click', () => {
            component.ddMenu = new ElementRefMock();
            expect(component.isOpen).toBe(false);
            component.onClick();
            expect(component.isOpen).toBe(true);
            component.onClick();
            expect(component.isOpen).toBe(false);
        });

        it('hides the control on hide', () => {
            component.isOpen = true;
            component.hide();
            expect(component.isOpen).toBe(false);
        });

        it('clears the selected records', () => {
            component.items = { selected: 10, totalCount: 10 };
            component.doClear(event);

            expect(event.stopPropagation).toHaveBeenCalled();
            expect(grid.clearSelection).toHaveBeenCalled();
            expect(component.isSelectPage).toBe(false);
        });

        it('Enabled/disable based on selection', () => {
            expect(component.isClearDisabled()).toBe(true);
            expect(component.hasItemsSelected()).toBe(false);
            component.items.selected = 1;
            expect(component.isClearDisabled()).toBe(false);
            expect(component.hasItemsSelected()).toBe(true);
        });
    });

    describe('grid selection subscription', () => {
        it('subscribes to grid selection event', () => {
            grid.rowSelectionChanged.subscribe = jest.fn((inputFn) => inputFn({
                dataItem: {
                    casereference__77_: {
                        value: '1234/F',
                        link: {
                            caseKey: -469,
                            caseReference__77_: '1234/F'
                        }
                    },
                    billedtotal__74_: {
                        value: 625,
                        link: {
                            caseKey: -469,
                            caseReference__77_: '1234/F'
                        }
                    },
                    shorttitle__15_: 'RONDON and shoe device',
                    usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-469',
                    usercolumnurl_272_: '[Case 1234/F Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-469]',
                    nameaddress_a___95_: '\r\n',
                    rowKey: '4',
                    billedCurrencyCode: 'AUD',
                    caseKey: -469,
                    isEditable: true,
                    id: '-469_4',
                    selected: false
                },
                rowSelection: [
                    {
                        casereference__77_: {
                            value: '1234/A',
                            link: {
                                caseKey: -487,
                                caseReference__77_: '1234/A'
                            }
                        },
                        billedtotal__74_: {
                            value: 27747.04,
                            link: {
                                caseKey: -487,
                                caseReference__77_: '1234/A'
                            }
                        },
                        shorttitle__15_: 'RONDON and shoe device',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487',
                        usercolumnurl_272_: '[Case 1234/A Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-487]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '1',
                        billedCurrencyCode: 'AUD',
                        caseKey: -487,
                        isEditable: true,
                        id: '-487_1',
                        selected: true
                    },
                    {
                        casereference__77_: {
                            value: '1234/B',
                            link: {
                                caseKey: -486,
                                caseReference__77_: '1234/B'
                            }
                        },
                        billedtotal__74_: {
                            value: 3640,
                            link: {
                                caseKey: -486,
                                caseReference__77_: '1234/B'
                            }
                        },
                        shorttitle__15_: 'RONDON & shoe device',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-486',
                        usercolumnurl_272_: '[Case 1234/B Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-486]',
                        namecode_a___93_: {
                            value: '057100',
                            link: {
                                nameKey_A_: -5710000,
                                displayName_A_: 'Ladas & Parry',
                                nameCode_A___93_: '057100'
                            }
                        },
                        nameaddress_a___95_: 'Ladas & Parry\r\n26 West 61st Street\r\nNew York 10023\r\nUnited States of America',
                        namereference_a___96_: '002345/11111-US',
                        rowKey: '2',
                        billedCurrencyCode: 'AUD',
                        caseKey: -486,
                        displayName_A_: 'Ladas & Parry',
                        isEditable: true,
                        nameKey_A_: -5710000,
                        id: '-486_2',
                        selected: true
                    },
                    {
                        casereference__77_: {
                            value: '1234/C',
                            link: {
                                caseKey: -485,
                                caseReference__77_: '1234/C'
                            }
                        },
                        billedtotal__74_: {
                            value: 2813.92,
                            link: {
                                caseKey: -485,
                                caseReference__77_: '1234/C'
                            }
                        },
                        shorttitle__15_: 'Device of shoe',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-485',
                        usercolumnurl_272_: '[Case 1234/C Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-485]',
                        namecode_a___93_: {
                            value: '050960',
                            link: {
                                nameKey_A_: -5096000,
                                displayName_A_: 'Baines & Casey',
                                nameCode_A___93_: '050960'
                            }
                        },
                        nameaddress_a___95_: 'Baines & Casey\r\nPO Box 852\r\nWellington C1\r\nNew Zealand',
                        rowKey: '3',
                        billedCurrencyCode: 'AUD',
                        caseKey: -485,
                        displayName_A_: 'Baines & Casey',
                        isEditable: true,
                        nameKey_A_: -5096000,
                        id: '-485_3',
                        selected: true
                    }
                ],
                selectedRows: [],
                deselectedRows: [
                    {
                        casereference__77_: {
                            value: '1234/F',
                            link: {
                                caseKey: -469,
                                caseReference__77_: '1234/F'
                            }
                        },
                        billedtotal__74_: {
                            value: 625,
                            link: {
                                caseKey: -469,
                                caseReference__77_: '1234/F'
                            }
                        },
                        shorttitle__15_: 'RONDON and shoe device',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-469',
                        usercolumnurl_272_: '[Case 1234/F Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-469]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '4',
                        billedCurrencyCode: 'AUD',
                        caseKey: -469,
                        isEditable: true,
                        id: '-469_4',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '1234/G',
                            link: {
                                caseKey: -457,
                                caseReference__77_: '1234/G'
                            }
                        },
                        shorttitle__15_: 'RONDON and shoe device',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-457',
                        usercolumnurl_272_: '[Case 1234/G Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-457]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '5',
                        billedCurrencyCode: 'AUD',
                        caseKey: -457,
                        isEditable: true,
                        id: '-457_5',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '1234/U',
                            link: {
                                caseKey: -470,
                                caseReference__77_: '1234/U'
                            }
                        },
                        shorttitle__15_: 'RONDON',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-470',
                        usercolumnurl_272_: '[Case 1234/U Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-470]',
                        namecode_a___93_: {
                            value: '000123',
                            link: {
                                nameKey_A_: -496,
                                displayName_A_: 'Origami & Beech',
                                nameCode_A___93_: '000123'
                            }
                        },
                        nameaddress_a___95_: 'Origami & Beech\r\n12-32 Akasaka 1-Chome\r\nMinato-ku\r\nTokyo 107\r\nJapan',
                        namereference_a___96_: 'AU214',
                        rowKey: '6',
                        billedCurrencyCode: 'AUD',
                        caseKey: -470,
                        displayName_A_: 'Origami & Beech',
                        isEditable: true,
                        nameKey_A_: -496,
                        id: '-470_6',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '1234/X',
                            link: {
                                caseKey: -367,
                                caseReference__77_: '1234/X'
                            }
                        },
                        billedtotal__74_: {
                            value: 550,
                            link: {
                                caseKey: -367,
                                caseReference__77_: '1234/X'
                            }
                        },
                        shorttitle__15_: 'RONDON and shoe device',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-367',
                        usercolumnurl_272_: '[Case 1234/X Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-367]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '7',
                        billedCurrencyCode: 'AUD',
                        caseKey: -367,
                        isEditable: true,
                        id: '-367_7',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '12345/AB',
                            link: {
                                caseKey: -424,
                                caseReference__77_: '12345/AB'
                            }
                        },
                        shorttitle__15_: 'HARVEST HOME',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-424',
                        usercolumnurl_272_: '[Case 12345/AB Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-424]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '8',
                        billedCurrencyCode: 'AUD',
                        caseKey: -424,
                        isEditable: true,
                        id: '-424_8',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '12345/DE',
                            link: {
                                caseKey: -402,
                                caseReference__77_: '12345/DE'
                            }
                        },
                        billedtotal__74_: {
                            value: 32209.98,
                            link: {
                                caseKey: -402,
                                caseReference__77_: '12345/DE'
                            }
                        },
                        shorttitle__15_: 'HARVEST HOME',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-402',
                        usercolumnurl_272_: '[Case 12345/DE Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-402]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '9',
                        billedCurrencyCode: 'AUD',
                        caseKey: -402,
                        isEditable: true,
                        id: '-402_9',
                        selected: false
                    },
                    {
                        casereference__77_: {
                            value: '123456/A',
                            link: {
                                caseKey: -374,
                                caseReference__77_: '123456/A'
                            }
                        },
                        shorttitle__15_: 'CALL DIRECT in special script',
                        usercolumnurl_271_: 'http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-374',
                        usercolumnurl_272_: '[Case 123456/A Link|http://vnext.inprotech.cpaglobal.com/cpainpro/apps/#/portal2/caseview/-374]',
                        nameaddress_a___95_: '\r\n',
                        rowKey: '10',
                        billedCurrencyCode: 'AUD',
                        caseKey: -374,
                        isEditable: true,
                        id: '-374_10',
                        selected: false
                    }
                ],
                totalRecord: 10,
                allDeSelectIds: [
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '10'
                ]
            }));
            component.ngAfterViewInit();
            expect(component.items.selected).toEqual(3);
            expect(component.isSelectPage).toBe(false);
            expect(cdr.markForCheck).toHaveBeenCalled();
        });

        it('subscribes to grid data Bound event', () => {
            grid.dataBound.subscribe = jest.fn((inputFn) => inputFn());
            component.ngAfterViewInit();
            expect(component.isSelectPage).toBe(false);
            expect(cdr.markForCheck).toHaveBeenCalled();
        });

        it('Set selectAll method indivisual check', () => {
            const selectrow = [
                {
                    dataItemId: 31,
                    contextId: 2,
                    displayName: 'Renewals Agents',
                    columnNameDescription: 'The Renewals Agent associated with the case',
                    columnId: 9,
                    selected: true
                },
                {
                    dataItemId: 33,
                    contextId: 2,
                    displayName: 'Renewals Agent Name Codes',
                    columnNameDescription: 'The Name Code of the renewals agent associated with the case',
                    columnId: 10,
                    selected: true
                },
                {
                    dataItemId: 38,
                    contextId: 2,
                    displayName: 'Agents Reference',
                    columnNameDescription: 'The Agents identifying reference for the case.',
                    columnId: - 96,
                    selected: true
                },
                {
                    dataItemId: 31,
                    contextId: 2,
                    displayName: 'Agents',
                    columnNameDescription: 'The name of the Agent.x',
                    columnId: -92,
                    selected: true
                },
                {
                    dataItemId: 32,
                    contextId: 2,
                    displayName: 'Agent Details for mkre',
                    columnNameDescription: 'The name and address of the Agent for the case.',
                    columnId: -95,
                    selected: true
                },
                {
                    dataItemId: 33,
                    contextId: 2,
                    displayName: 'Agent Code',
                    columnNameDescription: 'The identifying name code for the Agent of the case.',
                    columnId: -93,
                    selected: true
                }
            ];
            component.setSelectAll(selectrow, 6, []);
            expect(component.isSelectPage).toEqual(true);
        });

        it('Set DeselectAll method indivisual click', () => {
            component.setDeSelectAll(6, []);
            expect(component.isSelectPage).toEqual(false);
        });

        it('Set DeselectAll method with one click', () => {
            component.setDeSelectAll(6, [
                -93,
                -95,
                -92,
                -96,
                10,
                9
            ]);
            expect(component.isSelectPage).toEqual(false);
        });

        it('Set selectAll method with one click deselect all', () => {
            component.setSelectAll([], 6, [
                -93,
                -95,
                -92,
                -96,
                10,
                9
            ]);
            expect(component.isSelectPage).toEqual(false);
        });
    });

    describe('selectAllPage', () => {
        it('should not do anything if isSelectAllEnable is true', () => {
            component.isSelectAllEnable = true;
            component.selectAllPage(event);
            expect(grid.clearSelection).not.toBeCalled();
        });

        it('deselects the page if already selected', () => {
            component.isSelectAllEnable = false;
            component.isSelectPage = true;
            component.selectAllPage(event);
            expect(component.isSelectPage).toBe(false);
            expect(grid.clearSelection).toBeCalled();
        });

        it('selects all page', () => {
            component.isSelectAllEnable = false;
            component.isSelectPage = false;
            grid.wrapper.data = [{ id: 1, text: 'abc' }, { id: 2, text: 'def' }, { id: 3, text: 'ghi' }];
            component.selectAllPage(event);
            expect(component.isSelectPage).toBe(true);
            expect(grid.selectAllPage).toBeCalled();
        });
    });
});