ko.protectedObservable = function(initialValue, onValueChanging) {
    var _actualValue = ko.observable(initialValue);
    return ko.computed({
        read: function () {
            return _actualValue();
        },
        write: function (newValue) {
            var change = {
                accept: function() {
                    _actualValue(newValue);
                },
                reject: function() {
                    _actualValue.valueHasMutated();
                }
            };
            if(_actualValue() != newValue)
                onValueChanging(change);
        },
        deferEvaluation: true
    });
}