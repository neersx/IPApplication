angular.module("inprotech.mocks").factory("menuItemServiceMock", function() {
  "use strict";
 
  var response = {
    data: {
      hasDueDatePresentationColumn: true,
      hasAllDatePresentationColumn: undefined
    }
  };
  var r = {
    getDueDatePresentation: function() {
        return {
            then: function() {
                return response;
            }
        };
    },
    getDueDateSavedSearch: function() {
        return {
            then: function() {
                return response;
            }
        };
    }
  };
 
  Object.keys(r).forEach(function(key) {
    if (angular.isFunction(r[key])) {
      spyOn(r, key).and.callThrough();
    }
  });
 
  return r;
});