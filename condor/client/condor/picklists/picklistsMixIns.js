angular.module('inprotech.picklists')
  .factory('mixinsForPicklists', function($http) {
    'use strict';

    var cache = {};

    return function(model, config) {
      return model.mix(['DefaultPacker', 'DuplicateModel', 'ValidationModel', 'dirtyCheck', 'ignoreAttributes'],
        _.extend(config, {
          $extend: {
            Model: {
              init: init
            },
            'Record.withParams': function(_params) {
              // create a decorator that hooks to the before-request event and adds some query parameters.
              var decorator = {
                  'before-request': function(req) {
                    req.params = _params;
                  }
                },
                decorated = this;

              // return proxy object that exposes decorated versions of common  operations.
              return {
                $destroy: function() {
                  return decorated.$decorate(decorator, function() {
                    return this.$destroy();
                  })
                }
              }
            }
          },
          $config: {
            name: 'data',
            plural: 'data',
            jsonMeta: '.',
            urlPrefix: 'api/picklists'
          }
        }));
    };

    function init(cb) {
      var url = this.$url() + '/meta';
      var data = cache[url];

      if (data) {
        cb(angular.copy(data));
        return;
      }

      $http.get(url).then(function(response) {
        data = cache[url] = response.data;
        cb(angular.copy(data));
      });
    }
  });
