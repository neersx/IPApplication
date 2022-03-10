'use strict';

class SavedSearchPanelController implements ng.IController {
	static $inject = ['savedSearchMenuService'];
	public iconName: string;
	public text: string;
	public items: any;
	public loadUrl: any;
	public url: string;
	public queryContextKey: number;
	public filter: string;
	public menuDetails: SavedSearchMenuItemDetail[];
	public childCompObj: any;

	constructor(private savedSearchMenuService: SavedSearchMenuService) {
		this.childCompObj = {};
		this.childCompObj.childFunc = this.refreshData;
	}

	public isIconDisplayed = (iconName: string): boolean => {
		return iconName !== 'null';
	}

	public $onInit = (): void => {
		this.build();
	}

	public refreshData = (rebuild: boolean): void => {
		if (rebuild) {
			this.build();
		} else {
			this.filter = '';
			this.getFilteredData();
		}
	}

	public build = (): void => {
		// let context = this;
		this.savedSearchMenuService.build(this.queryContextKey).then((dataSource) => {
			this.menuDetails = dataSource;
		});
	}

	public getFilteredData = (): void => {
		let data = this.savedSearchMenuService.filterMenu(this.filter);
		if (!data) { return; }
		this.menuDetails = data;
	}

	public runSearch = (event: Event): void => {
		if (this.menuDetails.length === 1) {
			let savedSearchUrl = this.menuDetails[0].url;
			if (savedSearchUrl) {
				this.loadUrl({ url: savedSearchUrl, event: event });
			} else if (this.menuDetails[0].items.length === 1) {
				this.loadUrl({ url: this.menuDetails[0].items[0].url, event: event });
			}
		}
		event.stopPropagation();
	}
}

class SavedSearchPanel implements ng.IComponentOptions {
	public bindings: any;
	public controller: any;
	public templateUrl: string;
	public restrict: string;
	public transclude: boolean;
	public replace: boolean;
	public controllerAs: string;
	public queryContextKey: number;

	constructor() {
		this.transclude = true;
		this.replace = true;
		this.restrict = 'EA';
		this.templateUrl = 'condor/components/savedSearchPanel/saved-search-panel.html';
		this.controller = SavedSearchPanelController;
		this.controllerAs = 'vm';
		this.bindings = {
			iconName: '@?',
			text: '@',
			url: '@',
			items: '@',
			filter: '@',
			queryContextKey: '@',
			childCompObj: '=?',
			loadUrl: '&',
			key: '@'
		};
	}
}

angular.module('inprotech.components.menu')
	.component('savedSearchPanel', new SavedSearchPanel());
