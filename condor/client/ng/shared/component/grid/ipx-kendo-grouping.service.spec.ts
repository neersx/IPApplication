import { async } from '@angular/core/testing';
import { IpxGroupingService } from './ipx-kendo-grouping.service';

describe('IpxGroupingService', () => {
    let service: IpxGroupingService;
    beforeEach(() => {
        service = new IpxGroupingService();
    });
    it('should create the service', async(() => {
        expect(service).toBeTruthy();
    }));

    it('should call convertRecordForGrouping', async(() => {
        const record = {
            aggregates: {
                countryname__7_: {
                    count: 2
                }
            },
            field: 'countryname__7_',
            items: [
                {
                    casetypedescription__6_: 'Properties',
                    propertytypedescription__8_: 'Trade Mark',
                    propertyTypeKey: 'T',
                    id: '-69_67'
                },
                {
                    casetypedescription__6_: 'Properties',
                    propertytypedescription__8_: 'Trade Mark',
                    propertyTypeKey: 'T',
                    id: '-75_73'
                }
            ],
            value: 'Benelux'
        };
        const result = service.convertRecordForGrouping(record);
        expect(result.items.length).toEqual(2);
        expect(result.count).toEqual(2);
        expect(result.detail).toEqual('Benelux');

    }));
});