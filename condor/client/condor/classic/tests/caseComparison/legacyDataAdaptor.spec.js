describe('legacyDataAdaptor', function() {
    'use strict';

    var _legacyDataAdaptor;

    var makeLegacy = function(data) {
        if (!data.case) {
            return _.extend(data, {
                case: {
                    ref: {
                        uspto: 'making legacy data'
                    }
                }
            });
        }
        return data;
    };

    beforeEach(module('Inprotech.CaseDataComparison'));

    beforeEach(inject(function(legacyDataAdaptor) {
        _legacyDataAdaptor = legacyDataAdaptor;
    }));

    describe('adapt method', function() {
        it('should return validation messages as is', function() {
            var d = {
                messages: 'something wrong'
            };
            var r = _legacyDataAdaptor.adapt(d);

            expect(r.messages).toBe(d.messages);
        });

        describe('case', function() {

            var data = {
                case: {
                    ref: {
                        inprotech: 'a',
                        uspto: 'b'
                    },
                    title: {
                        inprotech: 'a',
                        uspto: 'b'
                    },
                    status: {
                        inprotech: 'a',
                        uspto: 'b'
                    },
                    statusDate: {
                        inprotech: 'a',
                        uspto: 'b'
                    },
                    localClasses: {
                        inprotech: 'a',
                        uspto: 'b'
                    }
                }
            };

            it('should return case ref adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.case.ref.ourValue).toBe(data.case.ref.inprotech);
                expect(r.case.ref.theirValue).toBe(data.case.ref.uspto);
            });

            it('should return case title adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.case.title.ourValue).toBe(data.case.title.inprotech);
                expect(r.case.title.theirValue).toBe(data.case.title.uspto);
            });

            it('should return case status adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.case.status.ourValue).toBe(data.case.status.inprotech);
                expect(r.case.status.theirValue).toBe(data.case.status.uspto);
            });

            it('should return case status date adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.case.statusDate.ourValue).toBe(data.case.statusDate.inprotech);
                expect(r.case.statusDate.theirValue).toBe(data.case.statusDate.uspto);
            });

            it('should return case local classes adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.case.localClasses.ourValue).toBe(data.case.localClasses.inprotech);
                expect(r.case.localClasses.theirValue).toBe(data.case.localClasses.uspto);
            });
        });

        describe('case names', function() {

            var data = {
                caseNames: [{
                    nameType: 'Examiner',
                    syncId: 1,
                    name: {
                        uspto: 'JACKSON, GARY',
                        different: true,
                        updateable: true
                    }
                }, {
                    nameType: 'Inventor',
                    syncId: 2,
                    name: {
                        inprotech: 'Hopkins, Leo N.United States of America',
                        uspto: 'HOPKINS LEO'
                    }
                }]
            };

            beforeEach(function() {
                data = makeLegacy(data);
            });

            it('should return all case names adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);

                expect(r.caseNames.length).toBe(data.caseNames.length);
                expect(r.caseNames[0].name.ourValue).toBe(data.caseNames[0].name.inprotech);
                expect(r.caseNames[0].name.theirValue).toBe(data.caseNames[0].name.uspto);
                expect(r.caseNames[1].name.ourValue).toBe(data.caseNames[1].name.inprotech);
                expect(r.caseNames[1].name.theirValue).toBe(data.caseNames[1].name.uspto);
            });

            it('should return other properties as is', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.caseNames[0].different).toBe(data.caseNames[0].different);
                expect(r.caseNames[0].updateable).toBe(data.caseNames[0].updateable);
                expect(r.caseNames[0].syncId).toBe(data.caseNames[0].syncId);
            });
        });

        describe('official numbers', function() {

            var data = {
                officialNumbers: [{
                    syncId: 1,
                    numberType: 'Registration/Grant',
                    number: {
                        inprotech: '6129739',
                        uspto: '111-0808',
                        different: true,
                        updateable: true
                    },
                    'event': 'Register On',
                    eventDate: {
                        inprotech: '2010-11-15T00:00:00',
                        uspto: '2010-11-15T00:00:00'
                    }
                }]
            };

            beforeEach(function() {
                data = makeLegacy(data);
            });

            it('should return all official numbers adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);

                expect(r.officialNumbers.length).toBe(data.officialNumbers.length);
                expect(r.officialNumbers[0].number.ourValue).toBe(data.officialNumbers[0].number.inprotech);
                expect(r.officialNumbers[0].number.theirValue).toBe(data.officialNumbers[0].number.uspto);
                expect(r.officialNumbers[0].eventDate.ourValue).toBe(data.officialNumbers[0].eventDate.inprotech);
                expect(r.officialNumbers[0].eventDate.theirValue).toBe(data.officialNumbers[0].eventDate.uspto);
            });

            it('should return other properties as is', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.officialNumbers[0].different).toBe(data.officialNumbers[0].different);
                expect(r.officialNumbers[0].updateable).toBe(data.officialNumbers[0].updateable);
                expect(r.officialNumbers[0].syncId).toBe(data.officialNumbers[0].syncId);
            });
        });

        describe('events', function() {

            var data = {
                events: [{
                    syncId: 1,
                    eventType: 'Change of Address filed',
                    cycle: 2,
                    eventDate: {
                        uspto: '2002-06-03T00:00:00',
                        different: true,
                        updateable: true
                    }
                }]
            };

            beforeEach(function() {
                data = makeLegacy(data);
            });

            it('should return all events adapted', function() {
                var r = _legacyDataAdaptor.adapt(data);

                expect(r.events.length).toBe(data.events.length);
                expect(r.events[0].eventDate.ourValue).toBe(data.events[0].eventDate.inprotech);
                expect(r.events[0].eventDate.theirValue).toBe(data.events[0].eventDate.uspto);
            });

            it('should return other properties as is', function() {
                var r = _legacyDataAdaptor.adapt(data);
                expect(r.events[0].eventDate.different).toBe(data.events[0].eventDate.different);
                expect(r.events[0].eventDate.updateable).toBe(data.events[0].eventDate.updateable);
                expect(r.events[0].syncId).toBe(data.events[0].syncId);
            });
        });
    });
});