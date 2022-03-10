'use strict';

class MenuItemController {
	static $inject = ['$window', 'featureDetection', 'modalService', '$state', 'notificationService', '$translate', '$uibModal', 'menuItemService', 'searchPresentationPersistenceService'];
	public iconName;
	public text;
	public expanded;
	public url;
	public type;
	public target = '';
	public showPopover = false;
	public queryContextKey;
	public childCompObj;
	public togglePopOver: boolean;
	public editTogglePopOver: boolean;
	public canEdit: boolean;
	isIEOrEdge: boolean;
	dueDateFormData: any;
	hasDueDateColumn: boolean;
	hasAllDateColumn: boolean;
	importanceLevelOptions: any;

	constructor(public window, private featureDetection: inprotech.core.IFeatureDetection, private modalService, private $state, public notificationService, private translate, private uibModal, private menuItemService, private searchPresentationPersistenceService) {
		this.childCompObj = {};
		this.isIEOrEdge = /msie\s|trident\/|edge\//i.test(this.window.navigator.userAgent);
	}

	$onInit() {
		if (this.type === 'newtab') {
			this.target = '_blank';
		}
	}

	public isIconDisplayed = (): boolean => {
		return this.iconName !== 'null';
	}

	public removeActiveState = (): void => {
		let elements = $('.k-state-active');
		if (!elements || !elements.hasClass('k-state-active')) { return; }
		elements.removeClass('k-state-active');
	}

	public loadUrl = (url: string, queryKey: string, event: Event) => {
		if (url === '../' && (!this.featureDetection.isIe() && !this.featureDetection.hasRelease16)) {
			this.showIeRequired(url);
			return;
		};

		if (queryKey) {
			this.searchPresentationPersistenceService.clear();
			if (!this.IsEditable()) {
				this.doSavedSearch(url, queryKey);
				return;
			}
			this.menuItemService.getDueDatePresentation(queryKey).then((response: any) => {
				if (response.data.hasDueDatePresentationColumn || response.data.hasAllDatePresentationColumn) {
					this.hasAllDateColumn = response.data.hasAllDatePresentationColumn;
					this.hasDueDateColumn = response.data.hasDueDatePresentationColumn;
					this.importanceLevelOptions = response.data.importanceOptions;

					this.menuItemService.getDueDateSavedSearch(queryKey).then((res: any) => {
						this.openDueDateModal(res, queryKey);
					});
					return;
				} else {
					this.doSavedSearch(url, queryKey);
				}
			});
		}
	}

	openDueDateModal = (response: any, queryKey: string) => {
		this.dueDateFormData = response.data.dueDateFormData;
		const state = this.$state;
		const modalState = this.uibModal.open({
			backdrop: 'static',
			size: 'xl',
			templateUrl: 'condor/components/menu/duedate-modal.html',
			controller: ['$scope', ($scope) => {
				$scope.existingFormData = this.dueDateFormData;
				$scope.hasDueDateColumn = this.hasDueDateColumn;
				$scope.hasAllDateColumn = this.hasAllDateColumn;
				$scope.importanceLevelOptions = this.importanceLevelOptions;
				$scope.getSearchRecord = (eventdata) => {
					modalState.close();
					if (!eventdata.isModalClosed && queryKey) {
						const filterCriteria = {
							dueDateFilter: eventdata.filterCriteria
						};
						state.go('search-results', {
							filter: filterCriteria,
							queryKey: queryKey,
							searchQueryKey: true,
							hasDueDatePresentation: true,
							rowKey: null,
							clearSearchPresentation: true,
							queryContext: this.queryContextKey
						}, { reload: true });
					}
				};
			}]
		});
	}

	doSavedSearch = (url: string, queryKey: string) => {
		if (queryKey) {
			this.$state.go(
				'search-results', {
				filter: null,
				queryKey: queryKey,
				searchQueryKey: false,
				canEdit: false,
				rowKey: null,
				q: null,
				clearSearchPresentation: true,
				queryContext: this.queryContextKey
			}, { reload: true });

			this.togglePopOver = false;
			this.showSavedSearchMenu(false, event, false);
		} else {
			if (this.type === 'newtab') {
				let disableNewTab =
					encodeURIComponent(url)
						.replace(/[^a-zA-Z0-9-_]/g, '')
						.replace(/[0-9]/g, '') ===
					encodeURIComponent(this.$state.current.url)
						.replace(/[^a-zA-Z0-9-_]/g, '')
						.replace(/[0-9]/g, '');
				this.target = '';
				if (!disableNewTab) {
					this.target = '_blank';
				}
			}
		}
	};

	showIeRequired = (url) => {
		this.modalService.openModal({
			id: 'ieRequired',
			controllerAs: 'vm',
			url: this.featureDetection.getAbsoluteUrl(url)
		});
	}

	public editSearch = (queryKey: string, event: Event) => {
		if (queryKey && !this.IsEditable()) {
			this.notificationService.alert({
				message: this.translate.instant('savedSearch.protechtedAndClientServerSavedSearchNotEditable')
			})
			return false;
		}
		if (this.queryContextKey) {
			this.searchPresentationPersistenceService.clear();
			let options = (this.$state.current.name === 'casesearch') ? { reload: true } : null;
			this.$state.go('casesearch', {
				queryKey: queryKey,
				canEdit: true,
				returnFromCaseSearchResults: false
			}, options);
			this.editTogglePopOver = false;
			this.showSavedSearchMenu(false, event, false);
		}
	}

	public IsEditable = () => {
		return this.canEdit && this.canEdit.toString() === 'true';
	}
	public menuHover = (queryKey: any) => {
		if (this.queryContextKey) {
			let elem = $('[name = "li-' + queryKey + '"]');
			elem.addClass('sub-menu-hover');
			elem.removeClass('sub-menu');
		}
	}

	public menuHoverOut = (queryKey: any) => {
		if (this.queryContextKey) {
			let elem = $('[name = "li-' + queryKey + '"]');
			elem.removeClass('sub-menu-hover');
			elem.addClass('sub-menu');
		}
	}

	public showSavedSearchMenu = (value: boolean, event: Event, rebuild: boolean): void => {
		if (event) {
			event.stopPropagation();
			event.preventDefault();
		}
		let activeMenu = $('*[id*=' + '_' + this.queryContextKey + ']').parent();
		let savedSearchMenu = $('#search' + this.queryContextKey);
		let savedSearchFilter = $('#fiterSavedSearch');

		if (savedSearchMenu.length > 0) {
			if (value) {
				if (savedSearchMenu.is(':visible')) {
					this.removeActiveState();
					savedSearchMenu.fadeOut();
					return;
				}
				if (_.isFunction(this.childCompObj.childFunc)) {
					this.childCompObj.childFunc(rebuild);
				}

				if (this.isIEOrEdge) {
					savedSearchMenu.css({ left: (this.expanded ? '160px' : '40px'), position: '-ms-device-fixed' });
				} else {
					savedSearchMenu.css({ left: (this.expanded ? '160px' : '40px'), position: 'fixed' });
				}
				activeMenu.addClass('k-state-active');
				savedSearchMenu.fadeIn();
				if (savedSearchFilter.length > 0) {
					savedSearchFilter.focus();
				}
				$(document).mousedown(function (e: any) {
					if (savedSearchMenu.is(':visible') && e.target['id'] !== savedSearchMenu.attr('id') && (!savedSearchMenu.has(e.target).length
						|| (((savedSearchMenu.outerWidth() + savedSearchMenu.offset().left) < e.clientX || savedSearchMenu.offset().left > e.clientX)
							|| ((savedSearchMenu.outerHeight() + savedSearchMenu.offset().top) < e.clientY || savedSearchMenu.offset().top > e.clientY)))
					) {
						savedSearchMenu.fadeOut();
						let elements = $('.k-state-active');
						if (!elements || !elements.hasClass('k-state-active')) { return; }
						elements.removeClass('k-state-active');
					}
				});
			} else {
				this.removeActiveState();
				savedSearchMenu.fadeOut();
			}
		}
	}
}

class MenuItem implements ng.IComponentOptions {
	public bindings: {};
	public controller: any;
	public templateUrl: string;
	public restrict: string;
	public transclude: boolean;
	public replace: boolean;
	public controllerAs: string;
	public queryContextKey: any;
	public tooltip: string;
	public canEdit: boolean;

	constructor() {
		this.transclude = true;
		this.replace = true;
		this.restrict = 'EA';
		this.templateUrl = 'condor/components/menu/menu-item.html';
		this.controller = MenuItemController;
		this.controllerAs = 'vm';
		this.bindings = {
			iconName: '@?',
			text: '@',
			id: '@',
			expanded: '=',
			url: '@',
			type: '@',
			queryContextKey: '@',
			tooltip: '@',
			canEdit: '@',
			queryKey: '@',
			key: '@'
		};
	}
}

angular.module('inprotech.components.menu')
	.component('menuItem', new MenuItem());
