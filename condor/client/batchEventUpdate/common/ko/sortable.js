var utils = function(my) {
    my.sortable = function(items) {
        var _items = ko.isObservable(items) ? items : ko.observable(items);
        var _sortColumn = ko.observable(null);
        var _sortInDescendingOrder = ko.observable(false);

        var applySort = function() {
            var copyOfItems = _items().slice(0);
            if (!_sortColumn())
                return _items();

            var c = function(a, b) {
                return ko.utils.unwrapObservable(a[_sortColumn()]) > ko.utils.unwrapObservable(b[_sortColumn()]) ? 1 : -1;
            };

            return _sortInDescendingOrder() ? copyOfItems.sort(c).reverse() : copyOfItems.sort(c);
        };

        var o = ko.computed({
            read: function() {
                var sorted = applySort();

                sorted.sort = function(sortColumn) {
                    if (sortColumn === _sortColumn()) {
                        if (_sortInDescendingOrder()) {
                            _sortColumn(null);
                            return;
                        }
                        _sortInDescendingOrder(true);
                        return;
                    }

                    _sortColumn(sortColumn);
                    _sortInDescendingOrder(false);
                };

                sorted.sortColumn = _sortColumn;
                sorted.sortInDescendingOrder = _sortInDescendingOrder;

                return sorted;

            },
            write: function(newValue) {
                _items(newValue);
            }
        });

        return o;
    };
    return my;
}(utils || {});