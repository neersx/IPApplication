'use strict';

class CollapsiblePanelController {
	public pinned;

	togglePinned = (): void => {
		this.pinned = !this.pinned;
	}
}

class CollapsiblePanel implements ng.IComponentOptions {
	public bindings: any;
	public controller: any;
	public templateUrl: string;
	public restrict: string;
	transclude: boolean;
	controllerAs: string;

	constructor() {
		this.transclude = true;
		this.restrict = 'EA';
		this.templateUrl = 'condor/components/panel/collapsible-panel.html';
		this.controller = CollapsiblePanelController;
		this.controllerAs = 'vm';
		this.bindings = {
			pinned: '=?'
		};
	}
}

angular.module('inprotech.components.panel')
	.component('collapsiblePanel', new CollapsiblePanel());
