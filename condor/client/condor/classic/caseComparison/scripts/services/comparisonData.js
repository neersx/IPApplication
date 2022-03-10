angular.module('Inprotech.CaseDataComparison')
    .factory('comparisonData', ['$rootScope', 'http', 'comparisonDataSourceMap', 'url',
        function ($rootScope, http, comparisonDataSourceMap, url) {
            'use strict';

            var viewData = null;
            var source = null;
            var notification = null;
            var allSelectdFlag = true;

            var saveChanges = function (scope) {

                if (scope.saveState === 'saving') {
                    return;
                }

                allSelectdFlag = true;

                var req = {
                    'case': {},
                    officialNumbers: [],
                    events: [],
                    goodsServices: [],
                    caseNames: [],
                    source: source,
                    notificationId: notification.notificationId,
                    caseId: notification.caseId,
                    systemCode: comparisonDataSourceMap.systemCode(notification.dataSource),
                    importImage: viewData.caseImage ? viewData.caseImage.importImage : false
                };

                if (viewData['case']) {
                    if (viewData['case'].title.updated || (viewData['case'].typeOfMark && viewData['case'].typeOfMark.updated)) {
                        req.case = viewData.case;
                    }
                }
                if (viewData.officialNumbers) {
                    viewData.officialNumbers.forEach(function (n) {
                        if ((n.number && n.number.updated) || (n.eventDate && n.eventDate.updated)) {
                            req.officialNumbers.push(n);
                        }
                    });
                }

                if (viewData.events) {
                    viewData.events.forEach(function (e) {
                        if (e.eventDate.updated) {
                            req.events.push(e);
                        }
                    });
                }

                if (viewData.goodsServices) {
                    viewData.goodsServices.forEach(function (g) {
                        if (g.class.updated || (g.firstUsedDate && g.firstUsedDate.updated) || (g.firstUsedDateInCommerce && g.firstUsedDateInCommerce.updated) || g.text.updated) {
                            req.goodsServices.push(g);
                        }
                    });
                }

                if (viewData.caseNames) {
                    viewData.caseNames.forEach(function (n) {
                        if (n.reference && n.reference.updated) {
                            req.caseNames.push(n);
                        }
                    });
                }

                scope.saveState = 'saving';
                http.post(url.api('casecomparison/saveChanges'), req)
                    .success(function (data) {
                        viewData.validationErrors = null;
                        scope.saveState = null;

                        if (data.success) {
                            checkAllDiffSelected();
                            viewData = data.viewData;
                            viewData.notificationId = req.notificationId;
                            $rootScope.$broadcast('case-comparison-updated');

                        } else {
                            viewData.validationErrors = data.messages;
                            $rootScope.$broadcast('case-comparison-error');
                        }
                    });
            };

            var selectAllDiffs = function () {
                if (!viewData || viewData.errors) {
                    return;
                }

                if (viewData['case'].title.updateable) {
                    viewData['case'].title.updated = true;
                }

                if (viewData.officialNumbers) {

                    _.each(viewData.officialNumbers, function (o) {
                        if (o.number && o.number.updateable) {
                            o.number.updated = true;
                        }

                        if (o.eventDate && o.eventDate.updateable) {
                            o.eventDate.updated = true;
                        }
                    });
                }

                if (viewData.events) {
                    _.each(viewData.events, function (e) {
                        if (e.eventDate && e.eventDate.updateable) {
                            e.eventDate.updated = true;
                        }
                    });
                }

                if (viewData.goodsServices) {
                    _.each(viewData.goodsServices, function (gs) {
                        if (gs.class.updateable) {
                            gs.class.updated = true;
                        }

                        if (gs.firstUsedDate && gs.firstUsedDate.updateable) {
                            gs.firstUsedDate.updated = true;
                        }

                        if (gs.firstUsedDateInCommerce && gs.firstUsedDateInCommerce.updateable) {
                            gs.firstUsedDateInCommerce.updated = true;
                        }

                        if (gs.text.updateable) {
                            gs.text.updated = true;
                        }
                    });
                }
            };

            var checkAllDiffSelected = function () {
                allSelectdFlag = true;
                if ((!viewData || viewData.errors) || (viewData['case'].title.updateable && !viewData['case'].title.updated)) {
                    allSelectdFlag = false;
                    return;
                }

                if ((viewData.officialNumbers && _.find(viewData.officialNumbers, function (n) {
                    return ((n.number && n.number.updateable && !n.number.updated) || (n.eventDate && n.eventDate.updateable && !n.eventDate.updated) === true);
                })) ||
                    (viewData.events && _.find(viewData.events, function (e) {
                        return ((e.eventDate && e.eventDate.updateable && !e.eventDate.updated) === true);
                    })) ||
                    (viewData.goodsServices && _.find(viewData.goodsServices, function (e) {
                        return (goodsServicesAllSelected(e) === true);
                    }))) {
                    allSelectdFlag = false;
                    return;
                }
            };

            var goodsServicesAllSelected = function (gs) {
                return ((gs.class.updateable && !gs.class.updated) || (gs.firstUsedDate && gs.firstUsedDate.updateable && !gs.firstUsedDate.updated) || 
                (gs.firstUsedDateInCommerce && gs.firstUsedDateInCommerce.updateable && !gs.firstUsedDateInCommerce.updated) || (gs.text.updateable && !gs.text.updated));
            };

            var goodsServicesUpdated = function (gs) {
                return gs.class.updated || (gs.firstUsedDate && gs.firstUsedDate.updated) || (gs.firstUsedDateInCommerce && gs.firstUsedDateInCommerce.updated) || gs.text.updated;
            };

            var saveable = function () {
                var result = viewData && !viewData.errors && (viewData['case'].title.updated ||
                    (viewData['case'].typeOfMark && viewData['case'].typeOfMark.updated) ||
                    (viewData.officialNumbers && _.any(viewData.officialNumbers, function(n) {
                        return (n.number && n.number.updated) || (n.eventDate && n.eventDate.updated);
                    })) ||
                    (viewData.events && _.any(viewData.events, function (e) {
                        return (e.eventDate && e.eventDate.updated);
                    })) ||
                    (viewData.goodsServices && _.any(viewData.goodsServices, function (e) {
                        return goodsServicesUpdated(e);
                    })) ||
                    (viewData.caseImage && viewData.caseImage.importImage) ||
                    (viewData.caseNames && _.any(viewData.caseNames, function (n) {
                        return n.reference && n.reference.updated;
                    }))
                );

                return result || false;
            };

            var getLanguages = function () {
                return http.get('api/picklists/tablecodes?tableType=47')
                    .then(function (response) {
                        return response.data;
                    });
            }

            var getGoodsServicesText = function (caseId, classKey, language) {
                var uri = 'api/case/' + caseId +'/goods-services-text/class/'+ classKey + '/language/'+ language;
                return http.get(uri)
                    .then(function (response) {
                        return response.data;
                    });
            }

            var getImportedGoodsServicesText = function (notificationId, classKey, languageCode) {
                var uri = 'api/casecomparison/imported-goods-services-text/n/' + notificationId + '/class/'+ classKey + '/language/'+ languageCode;
                return http.get(uri)
                    .then(function (response) {
                        return response.data;
                    });
            }

            return {
                reset: function () {
                    viewData = source = null;
                },
                initData: function (data, sourceData) {
                    viewData = data;
                    source = sourceData;
                },
                setNotification: function (notificationData) {
                    notification = notificationData;
                },
                getData: function () {
                    return viewData;
                },
                saveable: saveable,
                saveChanges: saveChanges,
                updateable: function () {
                    return viewData && viewData.updateable;
                },
                rejectable: function () {
                    return viewData && viewData.rejectable;
                },
                areAllDifferencesSelected: function () {
                    return allSelectdFlag;
                },
                selectAllDiffs: selectAllDiffs,
                getLanguages: getLanguages,
                getGoodsServicesText : getGoodsServicesText,
                getImportedGoodsServicesText : getImportedGoodsServicesText
            };
        }
    ]);