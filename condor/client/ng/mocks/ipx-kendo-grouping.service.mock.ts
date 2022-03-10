export class IpxKendoGroupingServiceMock {
    groupedDataSet$ = {
        next: jest.fn(),
        getValue: jest.fn().mockReturnValue([{
            aggregates: {
                propertytypedescription__8_: {
                    count: 2
                }
            },
            field: 'propertytypedescription__8_',
            items: [
                {
                    casetypedescription__6_: 'Properties',
                    propertytypedescription__8_: 'Trademark',
                    propertyTypeKey: 'T',
                    id: '-486_3'
                },
                {
                    casetypedescription__6_: 'Properties',
                    propertytypedescription__8_: 'Trademark',
                    propertyTypeKey: 'T',
                    id: '-470_7'
                }
            ],
            value: 'Trademark'
        }])
    };
    isProcessCompleted$ = {
        next: jest.fn(),
        subscribe: jest.fn()
    };
    convertRecordForGrouping = jest.fn();
}