/**
 * @ngdoc directive
 * @name cpa.ui.icon.directive:icon
 * @restrict E
 * @description Outputs an icon. Supports various parameters. Only one of `circle`, `square` or `document` should be defined.
 * @param {string} name Name of the icon, e.g. `question-circle`
 * @param {string} [class] Additional class names to pass into icon `<span />`
 * @param {boolean} [large] Make icon large
 * @param {boolean} [circle] Output circle around icon and invert it
 * @param {boolean} [square] Output square around icon and invert it
 * @param {boolean} [document] Output document around icon and invert it
 * @example
 <example module="cpa.ui.icon">
 <file name="icon.html">
   <icon name="logo" />
   <icon name="bars" large />
   <icon name="cogs" square />
   <icon name="archive" circle />
   <icon name="pencil" document />
 </file>
 </example>
 */
angular.module('cpa.ui.icon', []).directive('icon', function() {
  return {
    replace: true,
    restrict: 'E',
    template: function(tElement, tAttrs) {
      var iconClass = 'cpa-icon cpa-icon-question-circle';
      var additionalClass = '';
      var large = '';

      if(angular.isDefined(tAttrs.name)) {
        if(tAttrs.name.match(/^glyphicon-/)) {
          iconClass = 'glyphicon ' + tAttrs.name;
        } else {
          iconClass = 'cpa-icon cpa-icon-' + tAttrs.name;
        }
      }

      if(angular.isDefined(tAttrs.class)) {
        additionalClass = ' ' + tAttrs.class;
      }

      if(angular.isDefined(tAttrs.large)) {
        large = ' cpa-icon-lg';
      }

      var template = '<span class="' + iconClass + large + additionalClass + '"></span>';

      if(angular.isDefined(tAttrs.circle)) {
        template = '<span class="cpa-icon-stack' + large + '"><i class="fa cpa-icon-circle cpa-icon-stack-2x' + additionalClass + '"></i><i class="' + iconClass + ' cpa-icon-stack-1x cpa-icon-inverse"></i></span>';
      }

      if(angular.isDefined(tAttrs.square)) {
        template = '<span class="cpa-icon-stack' + large + '"><i class="fa cpa-icon-square cpa-icon-stack-2x' + additionalClass + '"></i><i class="' + iconClass + ' cpa-icon-stack-1x cpa-icon-inverse"></i></span>';
      }

      if(angular.isDefined(tAttrs.document)) {
        template = '<span class="cpa-icon-stack' + large + '"><i class="fa cpa-icon-file-o cpa-icon-stack-2x' + additionalClass + '"></i><i class="' + iconClass + ' cpa-icon-stack-1x' + additionalClass + '"></i></span>';
      }

      return template;
    }
  };
});
