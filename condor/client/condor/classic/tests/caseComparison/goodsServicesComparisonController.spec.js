'use strict';

describe('Inprotech.CaseDataComparison.goodsServicesComparisonController', function() {

    beforeEach(module('Inprotech.CaseDataComparison'));

    var fixture = {};

    var buildItem = function() {
        return {
            'class': {
                updated: false
            },
            firstUsedDate: {
                updateable: false,
                updated: false
            },
            firstUsedDateInCommerce: {
                updateable: false,
                updated: false
            },
            text: {
                updateable: false,
                updated: false
            }
        };
    };

    beforeEach(
        inject(
            function($controller, $rootScope) {
                fixture = {
                    controller: function() {
                        fixture.scope = $rootScope.$new();
                        return $controller('goodsServicesComparisonController', {
                            $scope: fixture.scope
                        });
                    }
                };
            }
        )
    );


    it('should set all goods and services attributes', function() {

        var item = buildItem();

        item.firstUsedDate.updateable = true;
        item.firstUsedDateInCommerce.updateable = true;
        item.text.updateable = true;
        item.class.updated = true;
        
        fixture.controller();
        fixture.scope.toggleGoodsServicesSelection(item);

        expect(item.firstUsedDate.updated).toBe(true);
        expect(item.firstUsedDateInCommerce.updated).toBe(true);
        expect(item.text.updated).toBe(true);
    });

    it('should not set any non-updateable goods and services attributes', function() {

        var item = buildItem();

        fixture.controller();
        fixture.scope.toggleGoodsServicesSelection(item);

        expect(item.firstUsedDate.updated).toBe(false);
        expect(item.firstUsedDateInCommerce.updated).toBe(false);
        expect(item.text.updated).toBe(false);
    });
});
