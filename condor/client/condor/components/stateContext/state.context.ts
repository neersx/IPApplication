class StateContext {
    static $inject = ['$state'];

    constructor(private $state) {
    }

    public getCurrentStateUrl = (): String => {
        return this.$state.href(this.$state.current.name, this.$state.params);
    }

    public getCurrentStateInfo = (): any => {
        return  {
            name: this.$state.current.name,
            params: angular.merge({}, this.$state.params)
        };
    }
}

angular.module('inprotech.components.stateContext')
    .service('stateContext', StateContext);
