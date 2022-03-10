import { MessageBroker } from 'mocks/message-broker.mock';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { TranslateServiceMock } from 'mocks/translate-service.mock';
import { SearchTypeBillingWorksheetProvider } from './search-type-billing-worksheet.provider';
import { SearchTypeBillingWorksheetProvidereServiceMock } from './search-type-billing-worksheet.provider.mock';
import { queryContextKeyEnum } from './search-type-config.provider';
import { SearchTypeMenuProviderServiceMock } from './search-type-menu.provider.mock';

describe('SearchTypeBillingWorksheetProvider', () => {

    const billingServiceMock = new SearchTypeBillingWorksheetProvidereServiceMock();
    const notificationServiceMock = new NotificationServiceMock();
    const translateServiceMock = new TranslateServiceMock();
    const searchTypeMenuProviderServiceMock = new SearchTypeMenuProviderServiceMock();
    const messageBroker = new MessageBroker();
    let service: SearchTypeBillingWorksheetProvider;

    beforeEach(() => {

        service = new SearchTypeBillingWorksheetProvider(billingServiceMock as any,
            notificationServiceMock as any,
            translateServiceMock as any,
            searchTypeMenuProviderServiceMock as any,
            messageBroker as any);
    });

    it('should load action menu configuration service', () => {
        expect(service).toBeTruthy();
    });

    it('validate initializeContext', () => {
        const permissions = {
            canCreateBillingWorksheet: true
        };
        const exportContentTypeMaper = [{ contentId: 1, reportFormat: 'PDF' }];
        service.initializeContext(permissions, queryContextKeyEnum.wipOverview, exportContentTypeMaper);
        expect(service.queryContextKey).toEqual(queryContextKeyEnum.wipOverview);
        expect(service.permissions).toEqual(permissions);
        expect(service.exportContentTypeMapper).toEqual(exportContentTypeMaper);
    });

    it('It should return action menu item for createBillingWorkSheet', () => {

        service.queryContextKey = queryContextKeyEnum.wipOverview;
        service.permissions = {
            canCreateBillingWorksheet: true
        };
        const viewData = {
            reportProviderInfo: {
                exportFormats: [{
                    exportFormatKey: 'pdf',
                    exportFormatDescription: 'pdf'
                },
                {
                    exportFormatKey: 'xml',
                    exportFormatDescription: 'xml'
                }]
            }
        };
        const results = service.getConfigurationActionMenuItems(true, viewData) as any;
        expect(results.length).toEqual(2);
        expect(results[0].id).toEqual('create-billing-worksheet');
        expect(results[0].items.length).toEqual(2);
        expect(results[0].items[0].id).toEqual('pdf');
        expect(results[0].items[1].id).toEqual('xml');
        expect(results[1].id).toEqual('create-billing-worksheet-extended');
        expect(results[1].items.length).toEqual(2);
        expect(results[1].items[0].id).toEqual('pdf');
        expect(results[1].items[1].id).toEqual('xml');
        expect(service.viewData).toEqual(viewData);
    });

    it('It should return none action menu when no permission is granted', () => {

        service.queryContextKey = queryContextKeyEnum.wipOverview;
        service.permissions = {
            canCreateBillingWorksheet: false
        };
        const viewData = {
            reportProviderInfo: {
                exportFormats: [{
                    exportFormatKey: 'pdf',
                    exportFormatDescription: 'pdf'
                },
                {
                    exportFormatKey: 'xml',
                    exportFormatDescription: 'xml'
                }]
            }
        };
        const results = service.getConfigurationActionMenuItems(true, viewData) as any;
        expect(results.length).toEqual(0);
    });

});
