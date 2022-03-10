import 'jest-preset-angular';
import './jestGlobalMocks';
import '@angular/localize/init';

let error = console.error

console.error = function (message) {
  error.apply(console, arguments) // keep default behaviour
  throw (message instanceof Error ? message : new Error(message))
}