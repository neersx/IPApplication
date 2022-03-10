'use strict';

describe('Inprotech.CaseDataComparison.caseComparisonViewController', function () {
    var fixture = {};
    var _comparisonData = {};

    beforeEach(function () {
        var modalService;

        module('Inprotech.CaseDataComparison');
        module(function () {
            modalService = test.mock('modalService');
        });

        inject(function ($controller, $rootScope, $location, $injector) {
            var httpBackend = $injector.get('$httpBackend');
            fixture = {
                location: $location,
                httpBackend: httpBackend,
                modalService: modalService,
                controller: function () {
                    fixture.scope = $rootScope.$new();
                    return $controller('caseComparisonViewController', {
                        $location: $location,
                        $scope: fixture.scope,
                        comparisonData: _comparisonData,
                        modalService: modalService
                    });
                },
                viewView: {}
            };
        })
    });

    afterEach(function () {
        fixture.httpBackend.verifyNoOutstandingExpectation();
        fixture.httpBackend.verifyNoOutstandingRequest();
    });

    it('should request case comparison using tsdr system code', function () {
        _comparisonData = _.extend({
            getData: function () {
                return {};
            },
            getLanguages: function() {
                return {
                    then: function() {
                        return {};
                    }
                };
            },
            initData: function () { },
            reset: function () { }
        });

        fixture.httpBackend.whenGET('api/casecomparison/n/1/case/2/USPTO.TSDR')
            .respond({
                viewData: 'viewData'
            });
        fixture.httpBackend.whenGET('api/casecomparison/UsptoTsdr/documents?caseId=2')
            .respond({
                documentsViewData: 'documentsViewData'
            });

        fixture.controller();
        fixture.scope.$broadcast('case-comparison', {
            notificationId: 1,
            caseId: 2,
            dataSource: 'UsptoTsdr'
        });
        fixture.httpBackend.expectGET('api/casecomparison/n/1/case/2/USPTO.TSDR');
        fixture.httpBackend.expectGET('api/casecomparison/UsptoTsdr/documents?caseId=2');

        fixture.scope.viewData = 'viewData';
        fixture.httpBackend.flush();
    });

    it('should request case comparison using private pair system code', function () {
        _comparisonData = _.extend({
            getData: function () {
                return {};
            },
            getLanguages: function() {
                return {
                    then: function() {
                        return {};
                    }
                };
            },
            initData: function () { },
            reset: function () { }
        });

        fixture.httpBackend.whenGET('api/casecomparison/n/1/case/2/USPTO.PrivatePAIR')
            .respond({
                viewData: 'viewData'
            });
        fixture.httpBackend.whenGET('api/casecomparison/UsptoPrivatePair/documents?caseId=2')
            .respond({
                documentsViewData: 'documentsViewData'
            });

        fixture.controller();
        fixture.scope.$broadcast('case-comparison', {
            notificationId: 1,
            caseId: 2,
            dataSource: 'UsptoPrivatePair'
        });
        fixture.httpBackend.expectGET('api/casecomparison/n/1/case/2/USPTO.PrivatePAIR');
        fixture.httpBackend.expectGET('api/casecomparison/UsptoPrivatePair/documents?caseId=2');

        fixture.scope.viewData = 'viewData';
        fixture.httpBackend.flush();
    });

    it('should request case comparison if initialInit is called with notification', function () {
        _comparisonData = _.extend({
            getData: function () {
                return {};
            },
            getLanguages: function() {
                return {
                    then: function() {
                        return {};
                    }
                };
            },
            initData: function () { },
            reset: function () { }
        });

        fixture.httpBackend.whenGET('api/casecomparison/n/1/case/2/USPTO.PrivatePAIR')
            .respond({
                viewData: 'viewData'
            });
        fixture.httpBackend.whenGET('api/casecomparison/UsptoPrivatePair/documents?caseId=2')
            .respond({
                documentsViewData: 'documentsViewData'
            });

        fixture.controller();
        fixture.scope.initialInit({
            notificationId: 1,
            caseId: 2,
            dataSource: 'UsptoPrivatePair'
        });
        fixture.httpBackend.expectGET('api/casecomparison/n/1/case/2/USPTO.PrivatePAIR');
        fixture.httpBackend.expectGET('api/casecomparison/UsptoPrivatePair/documents?caseId=2');

        fixture.scope.viewData = 'viewData';
        fixture.httpBackend.flush();
    });

    describe('document', function () {
        var _scope;

        beforeEach(function () {
            _comparisonData = _.extend({
                getData: function () {
                    return {};
                },
                getLanguages: function() {
                    return {
                        then: function() {
                            return {};
                        }
                    };
                },
                initData: function () { },
                reset: function () { }
            });
            fixture.controller();
            _scope = fixture.scope;
            _scope.viewData = {};
        });

        describe('can send all to dms', function () {
            beforeEach(function () {
                _scope.dmsIntegrationEnabled = true;
            });

            it('should return true if any documents have Downloaded status', function () {
                _scope.documentsViewData = [{
                    status: 'Downloaded'
                }];

                expect(_scope.canSendAllToDms()).toBe(true);
            });
            it('should return true if any documents have FailedToSendToDms status', function () {
                _scope.documentsViewData = [{
                    status: 'FailedToSendToDms'
                }];

                expect(_scope.canSendAllToDms()).toBe(true);
            });
            it('should return false if no documents have Downloaded or FailedToSendToDms status', function () {
                _scope.documentsViewData = {};

                expect(_scope.canSendAllToDms()).toBe(false);
            });
        });

        describe('send all to dms', function () {
            it('should set the status of each document being sent to SendToDms before calling api with correct arguments', function () {
                var doc = {
                    id: 1,
                    status: 'Downloaded'
                };

                _scope.caseId = 1;
                _scope.dataSource = 'usptoPrivatePair';
                _scope.documentsViewData = {
                    doc: doc
                };

                _scope.sendAllToDms();

                expect(doc.status).toBe('SendToDms');

                fixture.httpBackend.expectPOST('api/dms/send/usptoPrivatePair/case/1').respond(200);
                fixture.httpBackend.flush();
            });

            it('should not send documents that have already been sent or are sending', function () {
                var doc = {
                    id: 1,
                    status: 'SendingToDms'
                };

                _scope.caseId = 1;
                _scope.dataSource = 'usptoPrivatePair';
                _scope.sendAllToDms();

                expect(doc.status).toBe('SendingToDms');

                fixture.httpBackend.expectPOST('api/dms/send/usptoPrivatePair/case/1').respond(200);
                fixture.httpBackend.flush();
            });

            it('should not send documents that have already been attached', function () {
                var doc = {
                    id: 1,
                    status: 'Downloaded',
                    imported: true
                };

                _scope.caseId = 1;
                _scope.dataSource = 'usptoPrivatePair';
                _scope.sendAllToDms();

                expect(doc.status).toBe('Downloaded');

                fixture.httpBackend.expectPOST('api/dms/send/usptoPrivatePair/case/1').respond(200);
                fixture.httpBackend.flush();
            });
        });

        describe('status', function () {
            it('should return empty string if viewData has not loaded', function () {
                _scope.viewData = null;

                var res = _scope.documentStatus({
                    status: 'Downloaded'
                });

                expect(res).toBe('');
            });

            it('should return empty string if Pending status', function () {
                var res = _scope.documentStatus({
                    status: 'Pending'
                });

                expect(res).toBe('');
            });

            it('should return SendToDms if waiting to send to dms', function () {
                var res = _scope.documentStatus({
                    status: 'SendToDms'
                });

                expect(res).toBe('SendToDms');
            });

            it('should return SendingToDms if sending to dms in progress', function () {
                var res = _scope.documentStatus({
                    status: 'SendingToDms'
                });

                expect(res).toBe('SendingToDms');
            });

            it('should return Failed if document failed downloading', function () {
                var res = _scope.documentStatus({
                    status: 'Failed'
                });

                expect(res).toBe('Failed');
            });

            it('should return SentToDms if it has already been sent', function () {
                var res = _scope.documentStatus({
                    status: 'SentToDms'
                });

                expect(res).toBe('SentToDms');
            });

            it('should return NotSentToDms if Dms is enabled and not attached', function () {
                _scope.viewData = {
                    updateable: false
                };

                _scope.dmsIntegrationEnabled = true;

                var res = _scope.documentStatus({
                    status: 'Downloaded'
                });

                expect(res).toBe('NotSentToDms');
            });

            it('should return Attached if document has been imported and Dms is enabled', function () {
                _scope.dmsIntegrationEnabled = true;

                var res = _scope.documentStatus({
                    status: 'Downloaded',
                    imported: true
                });

                expect(res).toBe('Attached');
            });

            it('should return Attached if document has been imported and Dms is not enabled', function () {
                _scope.dmsIntegrationEnabled = false;

                var res = _scope.documentStatus({
                    status: 'Downloaded',
                    imported: true
                });

                expect(res).toBe('Attached');
            });

            it('should return Attach if document has not been imported and viewData is updateable', function () {
                _scope.viewData = {
                    updateable: true
                };

                var res = _scope.documentStatus({
                    status: 'Downloaded',
                    imported: false
                });

                expect(res).toBe('Attach');
            });

            it('should return NotAttached if document has not been imported and viewData is not updateable', function () {
                _scope.viewData = {
                    updateable: false
                };

                var res = _scope.documentStatus({
                    status: 'Downloaded',
                    imported: false
                });

                expect(res).toBe('NotAttached');
            });
        });

        describe('documentHasErrors', function () {
            it('should be true if document status is Failed', function () {
                expect(_scope.documentHasErrors({
                    status: 'Failed'
                })).toBe(true);
            });

            it('should be true if document status is FailedToSendToDms', function () {
                expect(_scope.documentHasErrors({
                    status: 'FailedToSendToDms'
                })).toBe(true);
            });

            it('should be false if document status is Downloaded', function () {
                expect(_scope.documentHasErrors({
                    status: 'Downloaded'
                })).toBe(false);
            });

            it('should be false if document status is SendToDms', function () {
                expect(_scope.documentHasErrors({
                    status: 'SendToDms'
                })).toBe(false);
            });

            it('should be false if document status is SendingToDms', function () {
                expect(_scope.documentHasErrors({
                    status: 'SendingToDms'
                })).toBe(false);
            });

            it('should be false if document status is SentToDms', function () {
                expect(_scope.documentHasErrors({
                    status: 'SentToDms'
                })).toBe(false);
            });
        });

        describe('documentCanBeDownloaded', function () {
            it('should be true if document status is Downloaded', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'Downloaded'
                })).toBe(true);
            });

            it('should be true if document status is FailedToSendToDms', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'FailedToSendToDms'
                })).toBe(true);
            });

            it('should be false if document status is Failed', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'Failed'
                })).toBe(false);
            });

            it('should be false if document status is SendingToDms', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'SendingToDms'
                })).toBe(false);
            });

            it('should be false if document status is SentToDms', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'SentToDms'
                })).toBe(false);
            });

            it('should be false if document status is SendToDms', function () {
                expect(_scope.documentCanBeDownloaded({
                    status: 'SendToDms'
                })).toBe(false);
            });
        });
    });

    describe('image', function () {
        beforeEach(function () {
            fixture.controller();
            fixture.scope.viewData = {
                caseImage: {
                    caseImageIds: ['caseImageId='],
                    downloadedImageId: 'downloadedImageId=',
                    downloadedThumbnailId: 'downloadedThumbnailId='
                }
            };
        });

        it('should get image url', function () {
            var url = fixture.scope.caseImage.getCaseImageUrl();

            expect(url).toBe('api/img?source=inprotech.image&id=caseImageId%3D');
        });

        it('should get downloaded image url', function () {
            var url = fixture.scope.caseImage.getDownloadedImageUrl();

            expect(url).toBe('api/img?source=filestore&id=downloadedThumbnailId%3D');
        });

        it('should view case image detail', function () {
            fixture.scope.caseImage.viewCaseImage();
            expect(fixture.modalService.open).toHaveBeenCalled();
            expect(fixture.modalService.open.calls.mostRecent().args[0]).toEqual('ImageView');
            expect(fixture.modalService.open.calls.mostRecent().args[2].imageItem.detailUrl).toEqual(fixture.scope.caseImage.getCaseImageUrl());
            expect(fixture.scope.caseImage.detailUrl).toBe(fixture.scope.caseImage.getCaseImageUrl());
        });

        it('should view downloaded image detail', function () {
            fixture.scope.caseImage.viewDownloadedImage();
            expect(fixture.modalService.open).toHaveBeenCalled();
            expect(fixture.modalService.open.calls.mostRecent().args[0]).toEqual('ImageView');
            expect(fixture.modalService.open.calls.mostRecent().args[2].imageItem.detailUrl).toEqual(fixture.scope.caseImage.detailUrl);
            expect(fixture.scope.caseImage.detailUrl).toBe('api/img?source=filestore&id=downloadedImageId%3D');
        });
    });
});