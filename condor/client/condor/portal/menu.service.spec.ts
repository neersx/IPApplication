describe('inprotech.portal.menuService', () => {
    'use strict';

    let service: MenuService, httpMock: any, rootScope: ng.IRootScopeService, q: ng.IQService;

    beforeEach(() => {
        angular.mock.module('inprotech.portal');
        angular.mock.module(($provide) => {
            let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject((menuService: MenuService, $rootScope: ng.IRootScopeService, $q: ng.IQService) => {
        service = menuService;
        rootScope = $rootScope;
        q = $q;
    }));

    describe('menu service should', () => {
        it('returns formatted dataSource on build', () => {
            httpMock.get.returnValue = q.when(
                [{
                    icon: 'cpa-icon-home',
                    url: '#/dashboard',
                    text: 'Dashboard',
                    id: 'Dashboard_',
                    type: 'type1',
                    queryContextKey: null,
                    description: 'dashboard'
                },
                {
                    icon: 'cpa-icon-bell',
                    url: null,
                    text: 'First',
                    id: 'First_',
                    type: 'type2',
                    queryContextKey: null,
                    description: null,
                    items: [{
                        icon: 'cpa-icon-arrow-circle-left',
                        url: '#/subitem1',
                        text: 'SubItem 1',
                        id: 'SubItem 1_2',
                        type: 'type3',
                        queryContextKey: 2,
                        description: 'subitem1'
                    },
                    {
                        icon: 'cpa-icon-align-center',
                        url: '#/subitem2',
                        text: 'SubItem 2',
                        id: 'SubItem 2_2',
                        type: 'type4',
                        queryContextKey: 2,
                        description: 'subitem2'
                    }]
                }]);

            let dataSourceExpected = [{
                text: '<menu-item url="#/home" icon-name="cpa-icon-home" text="Home" id="Home" expanded="vm.leftBarExpanded"></menu-item>',
                encoded: false,
                items: []
            },
            {
                text: '<menu-item url="#/dashboard" type="type1" icon-name="cpa-icon-home" id="Dashboard_" text="Dashboard" query-context-key="" expanded="vm.leftBarExpanded" tooltip="dashboard"></menu-item>',
                encoded: false,
                items: [],
            },
            {
                text: '<menu-item url="" type="type2" icon-name="cpa-icon-bell" id="First_" text="First" query-context-key="" expanded="vm.leftBarExpanded" tooltip=""></menu-item>',
                encoded: false,
                items: [{
                    text: '<menu-item url="#/subitem1" type="type3" icon-name="cpa-icon-arrow-circle-left" id="SubItem 1_2" text="SubItem 1" query-context-key="2" expanded="true" tooltip="subitem1"></menu-item>',
                    encoded: false
                },
                {
                    text: '<menu-item url="#/subitem2" type="type4" icon-name="cpa-icon-align-center" id="SubItem 2_2" text="SubItem 2" query-context-key="2" expanded="true" tooltip="subitem2"></menu-item>',
                    encoded: false
                }]
            }];

            service.build().then(function (dataSource) {
                expect(httpMock.get).toHaveBeenCalledWith('api/portal/menu');
                expect(dataSource[0].text).toEqual(dataSourceExpected[0].text);
                expect(dataSource[0].encoded).toEqual(dataSourceExpected[0].encoded);

                expect(dataSource[1].text).toEqual(dataSourceExpected[1].text);
                expect(dataSource[1].encoded).toEqual(dataSourceExpected[1].encoded);

                expect(dataSource[2].text).toEqual(dataSourceExpected[2].text);
                expect(dataSource[2].encoded).toEqual(dataSourceExpected[2].encoded);

                expect(dataSource[2].items[0].text).toEqual(dataSourceExpected[2].items[0].text);
                expect(dataSource[2].items[0].encoded).toEqual(dataSourceExpected[2].items[0].encoded);

                expect(dataSource[2].items[1].text).toEqual(dataSourceExpected[2].items[1].text);
                expect(dataSource[2].items[1].encoded).toEqual(dataSourceExpected[2].items[1].encoded);
            });

            rootScope.$apply();
        });
    });
});
