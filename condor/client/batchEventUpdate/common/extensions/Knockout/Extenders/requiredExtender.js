ko.extenders.required = function (target, overrideMessage) {
    target.hasError = ko.observable();
    target.validationMessage = ko.observable();

    var setError = function (value) {

        var e = false;

        if (!value) {
            e = true;
        }
        else if ($.trim(value).length == 0) {
            e = true;
        }

        target.hasError(e);
        target.validationMessage(e ? overrideMessage || localise.getString('validationFieldRequired') : '');
        return e;
    };

    target.validate = function () {
        return setError(target());
    };

    target.subscribe(function (newValue) {
        return setError(newValue);
    });

    return target;
};
