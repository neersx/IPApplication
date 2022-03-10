var application = (function (my) {
    my.countryViewModel = function(id, name) {
        return {
            id: ko.observable(id),
            name: ko.observable(name)
        };
    };
    return my;
}(application || { }));