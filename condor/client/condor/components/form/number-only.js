angular.module('inprotech.components.form').directive('numbersOnly', function() {
    'use strict';

    return {
        restrict: 'A',
        link: function(scope, elm) {
            elm.on('keydown blur', function(event) {
                var $input = $(this);  
                var value = $input.val();  
                value = value.replace(/[^0-9]/g, '')  
                $input.val(value);  
                
                if(event.shiftKey) {
                    return false;
                }
                else if(event.which == 9) {
                    // to allow tab
                    return true;
                }
               else if (event.which == 64 || event.which == 16) {
                    // to allow numbers  
                    return false;
                } else if (event.which >= 48 && event.which <= 57) {
                    // to allow numbers  
                    return true;
                } else if (event.which >= 96 && event.which <= 105) {
                    // to allow numpad number  
                    return true;
                } else if ([8, 13, 27, 37, 38, 39, 40].indexOf(event.which) > -1) {
                    // to allow backspace, enter, escape, arrows  
                    return true;
                }
                else if((event.which > 64 && event.which < 91) || (event.which > 96 && event.which < 123) || event.which == 8 || event.which == 32 || (event.which >= 48 && event.which <= 57)){
                    return false;
                }
                 else {
                    event.preventDefault();
                    // to stop others  
                    return false;
                }
            });
        }
    }
});