namespace inprotech.portfolio.cases {
	describe('inprotech.portfolio.cases.caseimage', () => {
		'use strict';

		// todo: convert mock class to ts and move this interface there.
		interface ICaseImageServiceMock extends ICaseImageService {
			setReturnValue(val): any;
		}

		let c: CaseImageController;
		let controller: (viewData?: any) => CaseImageController, scope: any, window: any, imageService: ICaseImageServiceMock, modalService: any;

		beforeEach(() => {
			angular.mock.module('inprotech.portfolio.cases');
			angular.mock.module(($provide) => {
				let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

				imageService = $injector.get<ICaseImageServiceMock>('CaseImageServiceMock');
				window = {
					innerWidth: 140,
					innerHeight: 240
				};
				$provide.value('$window', window);
				modalService = $injector.get('modalServiceMock');
			});
		});

		beforeEach(inject(($rootScope: ng.IRootScopeService) => {
			scope = $rootScope.$new();
			controller = function(viewData?) {
				viewData = angular.extend({
					imageKey: 456,
					caseKey: 789,
					imageTitle: 'abcd123',
					imageDesc: 'abcd123 Description'
				}, viewData);

				let cont = new CaseImageController(scope, window, imageService, modalService);
				angular.extend(cont, viewData);
				return cont;
			};
		}));

		describe('initialise view', () => {
			it('should setup a watch on imageKey', () => {
				spyOn(scope, '$watch');
				c = controller();
				c.$onInit();
				expect(scope.$watch).toHaveBeenCalledWith('vm.imageKey', jasmine.any(Function));
			});
		});

		describe('load image', () => {
			it('should load the case image', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: false });
				c.$onInit();
				let loadImage = scope.$watch.calls.first().args[1];
				expect(loadImage).toBeDefined();
				expect(c.maxWidth).not.toBeDefined();
				expect(c.maxHeight).not.toBeDefined();

				loadImage();
				expect(imageService.getImage).toHaveBeenCalledWith(456, jasmine.any(Number), jasmine.any(Number), jasmine.any(Number));
				expect(c.maxWidth).toBeDefined();
				expect(c.maxHeight).toBeDefined();
				expect(c.imageDesc).toBeDefined();
			});

			it('should set the case image data', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: false });
				c.$onInit();
				let returnValue = {
					image: '¯\_(ツ)_/¯'
				}
				imageService.setReturnValue(returnValue)
				let loadImage = scope.$watch.calls.first().args[1];
				loadImage();

				expect(c.image).toEqual(returnValue.image);
			});

			it('should configure tooltip for thumbnails', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: true });
				c.$onInit();
				window.innerHeight = 999;
				window.innerWidth = 999;
				let returnValue = {
					image: '¯\_(ツ)_/¯',
					originalHeight: 11,
					originalWidth: 99
				}
				imageService.setReturnValue(returnValue)
				let loadImage = scope.$watch.calls.first().args[1];
				loadImage();

				expect(c.image).toEqual(returnValue.image);
				expect(c.tooltipOptions).toBeDefined();
				expect(c.tooltipOptions.height).toEqual(21); // 11 + 10px
				expect(c.tooltipOptions.width).toEqual(109); // 99 + 10px
			});

			it('should scale tall images to the window height', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: true });
				c.$onInit();
				window.innerHeight = 130;
				window.innerWidth = 999;
				let returnValue = {
					image: '¯\_(ツ)_/¯',
					originalHeight: 190,
					originalWidth: 90
				}
				imageService.setReturnValue(returnValue)
				let loadImage = scope.$watch.calls.first().args[1];
				loadImage();

				expect(c.image).toEqual(returnValue.image);
				// window height - 30px
				expect(c.tooltipOptions.height).toEqual(100);
				// proportional calculation
				expect(c.tooltipOptions.width).toEqual(90 * 100 / 190);
			});

			it('should scale wide images to the window width', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: true });
				c.$onInit();
				window.innerHeight = 999;
				window.innerWidth = 130;
				let returnValue = {
					image: '¯\_(ツ)_/¯',
					originalHeight: 90,
					originalWidth: 190
				}
				imageService.setReturnValue(returnValue)
				let loadImage = scope.$watch.calls.first().args[1];
				loadImage();

				expect(c.image).toEqual(returnValue.image);
				// window height - 30px
				expect(c.tooltipOptions.width).toEqual(100);
				// proportional calculation
				expect(c.tooltipOptions.height).toEqual(90 * 100 / 190);
			});

			it('should scale tall and wide images to the window size', () => {
				scope.$watch = jasmine.createSpy('watchSpy');
				c = controller({ isThumbnail: true });
				c.$onInit();
				window.innerHeight = 768;
				window.innerWidth = 1024;
				let returnValue = {
					image: '¯\_(ツ)_/¯',
					originalHeight: 800,
					originalWidth: 2000
				}
				imageService.setReturnValue(returnValue)
				let loadImage = scope.$watch.calls.first().args[1];
				loadImage();

				expect(c.image).toEqual(returnValue.image);

				expect(c.tooltipOptions.width).toEqual(1024 - 30);
				expect(c.tooltipOptions.height).toEqual(800 * (1024 - 30) / 2000);
			});
		});

		describe('mouse click on image', () => {
			it('should open the modal with correct parameters', () => {
				c = controller();
				c.$onInit();
				c.mouseClick();
				expect(modalService.openModal).toHaveBeenCalledWith({
					id: 'CaseImageFull',
					controllerAs: 'vm',
					bindToController: true,
					imageKey: 456,
					imageTitle: 'abcd123',
					imageDesc: 'abcd123 Description',
					caseKey: 789,
					type: 'case'
				});
			})
		})
	});
}