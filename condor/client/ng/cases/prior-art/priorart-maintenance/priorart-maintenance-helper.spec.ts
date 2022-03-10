import { PriorArtType } from '../priorart-model';
import { PriorartMaintenanceHelper } from './priorart-maintenance-helper';

describe('PriorArtMaintenanceHelper', () => {
    let component: PriorartMaintenanceHelper;
    beforeEach(() => {
        component = new PriorartMaintenanceHelper();
    });

    describe('buildSourceDescription', () => {
        it('should build the prior art description correctly for source type', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
            const sourceDocumentData = {
                sourceType: {
                    name: 'type source'
                },
                issuingJurisdiction: {
                    key: 'meh',
                    value: 'mehico'
                },
                description: 'source description'
            };
            expect(component.buildDescription(sourceDocumentData)).toEqual('type source - meh - (source description)');
        });
        it('should set the tab label appropriately for Source types', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
            const sourceDocumentData = {
                sourceType: {
                    name: 'type source'
                },
                issuingJurisdiction: {
                    key: 'meh',
                    value: 'mehico'
                },
                description: 'source description'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('type source - meh - (source description)');
        });
        it('should set the tab label with no jurisdiction if none', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
            const sourceDocumentData = {
                sourceType: {
                    name: 'type source'
                },
                description: 'source description'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('type source - (source description)');
        });
        it('should set the tab label with no source type if none', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
            const sourceDocumentData = {
                issuingJurisdiction: {
                    key: 'meh',
                    value: 'mehico'
                },
                sourceType: {
                    name: ''
                },
                description: 'source description'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('meh - (source description)');
        });
        it('should set the tab label with no description if none', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Source);
            const sourceDocumentData = {
                sourceType: {
                    name: 'type source'
                },
                issuingJurisdiction: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('type source - meh');
        });
        it('should set the tab label appropriately for Ipo types', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Ipo);
            const sourceDocumentData = {
                officialNumber: '1234',
                country: {
                    key: 'meh',
                    value: 'mehico'
                },
                description: 'source description',
                kindCode: 'kindCode'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('1234 - meh - kindCode');
        });
        it('should set the tab label appropriately for Ipo types with no kindCode', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Ipo);
            const sourceDocumentData = {
                officialNumber: '1234',
                country: {
                    key: 'meh',
                    value: 'mehico'
                },
                description: 'source description',
                kindCode: ''
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('1234 - meh');
        });
        it('should set the tab label appropriately for Ipo types with no country', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Ipo);
            const sourceDocumentData = {
                officialNumber: '1234',
                country: {
                    key: ''
                },
                description: 'source description',
                kindCode: 'kindCode'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('1234 - kindCode');
        });
        it('should set the tab label appropriately for Ipo types with no official number', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Ipo);
            const sourceDocumentData = {
                officialNumber: '',
                country: {
                    key: 'meh',
                    value: 'mehico'
                },
                description: 'source description',
                kindCode: 'kindCode'
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('meh - kindCode');
        });

        it('should set the tab label appropriately for Literature types with a description', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                description: 'source description',
                inventorName: 'inventorName',
                title: 'title',
                publisher: 'publisher',
                city: 'city',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('source description');
        });

        it('should set the tab label appropriately for Literature types without description', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                inventorName: 'inventorName',
                title: 'title',
                publisher: 'publisher',
                city: 'city',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('inventorName, title, publisher, city, meh');
        });

        it('should set the tab label appropriately for Literature types without inventorName or description', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                title: 'title',
                publisher: 'publisher',
                city: 'city',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('title, publisher, city, meh');
        });

        it('should set the tab label appropriately for Literature types without description or title', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                inventorName: 'inventorName',
                publisher: 'publisher',
                city: 'city',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('inventorName, publisher, city, meh');
        });

        it('should set the tab label appropriately for Literature types without description or publisher', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                inventorName: 'inventorName',
                title: 'title',
                city: 'city',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('inventorName, title, city, meh');
        });

        it('should set the tab label appropriately for Literature types without description or city', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                inventorName: 'inventorName',
                title: 'title',
                publisher: 'publisher',
                country: {
                    key: 'meh',
                    value: 'mehico'
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('inventorName, title, publisher, meh');
        });

        it('should set the tab label appropriately for Literature types without description or country', () => {
            component.getPriorArtType = jest.fn().mockReturnValue(PriorArtType.Literature);
            const sourceDocumentData = {
                inventorName: 'inventorName',
                title: 'title',
                publisher: 'publisher',
                city: 'city',
                country: {
                    key: ''
                }
            };
            component.buildDescription(sourceDocumentData);
            expect(component.buildShortDescription(sourceDocumentData)).toBe('inventorName, title, publisher, city');
        });
    });

    describe('openMaintenance', () => {
        it('sets the correct url when not cited', () => {
            const windowOpen = spyOn(window, 'open');
            const dataItem = {id: 1234, isCited: false};
            PriorartMaintenanceHelper.openMaintenance(dataItem, 9900);
            expect(windowOpen).toHaveBeenLastCalledWith('#/reference-management?priorartId=1234', '_blank');
        });
        it('sets the correct url when cited and no caseKey', () => {
            const windowOpen = spyOn(window, 'open');
            const dataItem = { id: 5678, isCited: true };
            PriorartMaintenanceHelper.openMaintenance(dataItem);
            expect(windowOpen).toHaveBeenLastCalledWith('#/reference-management?priorartId=5678', '_blank');
        });
        it('sets the correct url when cited and has caseKey', () => {
            const windowOpen = spyOn(window, 'open');
            const dataItem = { id: 5678, isCited: true };
            PriorartMaintenanceHelper.openMaintenance(dataItem, 9901);
            expect(windowOpen).toHaveBeenLastCalledWith('#/reference-management?priorartId=5678&caseKey=9901', '_blank');
        });
    });
});
