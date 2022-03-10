
angular.module('inprotech.components.form')
.filter('html', function () {
    return function (input) {
        var carriageToReplace = new RegExp('(\r\n|\n\r|\n|\r)', 'g'); // eslint-disable-line no-control-regex
        if (input && input.match(carriageToReplace)) {
            input = input.replace(carriageToReplace, '<br>');
        }
        return input;
    }
});