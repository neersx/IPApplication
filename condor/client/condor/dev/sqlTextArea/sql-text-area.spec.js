// describe('Directive inprotech.components.sqlTextArea', function() {
//     'use strict';

//     beforeEach(module('inprotech.components'));

//     var scope, compile, element, compileDirective;

//     beforeEach(inject(function($rootScope, $compile) {
//         scope = $rootScope.$new();
//         compile = $compile;
//         scope.textValue = "SELECT * FROM TableOne";
//         compileDirective = function(testText) {
//             scope.textValue = testText;
//             var defaultMarkup = '<ip-text-field multiline rows="8" ip-sql-highlight ng-model="textValue"></ip-text-field><div id="output" ng-bind-html="textValue"></html>';
//             element = compile(defaultMarkup)(scope);
//             scope.$digest();
//         };
//     }));

//     it('should not change the value for valid SQL', function() {
//         var testText = "SELECT * FROM TableOne";
//         compileDirective(testText);

//         expect(element[1].innerHTML).toBe(testText);
//     });

//     it('should not change the value for invalid SQL', function() {
//         var testText = "SELECT * TableOne";
//         compileDirective(testText);

//         expect(element[1].innerHTML).toBe(testText);
//     });


//     it('should not change the value for SQL with new lines', function() {
//         var testText = "SELECT * FROM\n\n\nTableOne";       
//         compileDirective(testText);

//         expect(element[1].innerHTML).toBe(testText);
//     });
// });
