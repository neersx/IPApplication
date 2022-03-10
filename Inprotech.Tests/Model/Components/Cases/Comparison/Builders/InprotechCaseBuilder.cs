using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Builders
{
    internal class InprotechCaseBuilder : IBuilder<Case>
    {
        readonly InMemoryDbContext _db;
        Case _case;

        public InprotechCaseBuilder(InMemoryDbContext db, string countryCode)
        {
            _db = db;
            _case = new CaseBuilder {CountryCode = countryCode}.Build().In(_db);
        }

        public InprotechCaseBuilder(InMemoryDbContext db)
        {
            _db = db;
            _case = new CaseBuilder().Build().In(_db);
        }

        public InprotechCaseBuilder(InMemoryDbContext db, string countryCode, string propertyType)
        {
            _db = db;
            _case = new CaseBuilder {CountryCode = countryCode, PropertyType = new PropertyType(propertyType, propertyType).In(_db)}.Build().In(_db);
        }

        public Case Build()
        {
            return _case;
        }

        public InprotechCaseBuilder WithClass(string localClass, string intlClass)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            _case.LocalClasses += string.IsNullOrWhiteSpace(_case.LocalClasses) ? localClass : "," + localClass;
            _case.IntClasses += string.IsNullOrWhiteSpace(_case.IntClasses) ? intlClass : "," + intlClass;

            return this;
        }

        public InprotechCaseBuilder WithAllowSubClass(PropertyType propertyType)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);
            _case.PropertyType = propertyType;

            return this;
        }

        public InprotechCaseBuilder WithCaseText(string @class, string goodsServicesText, short number = 0, int? language = null)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            _case.CaseTexts.Add(
                                new CaseText(_case.Id, "G", number, @class)
                                {
                                    ShortText = goodsServicesText,
                                    Language = language
                                }.In(_db));

            return this;
        }

        public InprotechCaseBuilder WithClassFirstUse(string @class, string fud = null, string fuicd = null)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            new ClassFirstUse(_case.Id, @class)
            {
                FirstUsedDate = string.IsNullOrWhiteSpace(fud) ? Fixture.PastDate() : DateTime.Parse(fud),
                FirstUsedInCommerceDate = string.IsNullOrWhiteSpace(fuicd) ? Fixture.Today() : DateTime.Parse(fuicd)
            }.In(_db);

            return this;
        }

        public InprotechCaseBuilder WithOfficialNumber(bool isCurrent, string number, string numberType, DateTime? relatedEventDate = null)
        {
            var numberTypes = _db.Set<NumberType>();

            _case = _case ?? new CaseBuilder().Build().In(_db);
            var numberTypeRecord = numberTypes.SingleOrDefault(_ => _.NumberTypeCode == numberType)
                                   ?? new NumberType(numberType, "numberType", null).In(_db);

            _case.OfficialNumbers.Add(new OfficialNumber(numberTypeRecord, _case, number) {IsCurrent = isCurrent ? 1 : 0}.In(_db));
            _case.CurrentOfficialNumber = number;

            if (relatedEventDate != null)
            {
                if (numberTypeRecord.RelatedEvent == null)
                {
                    numberTypeRecord.RelatedEvent = new EventBuilder().Build().In(_db);
                    numberTypeRecord.RelatedEventId = numberTypeRecord.RelatedEvent.Id;
                }

                WithCaseEvent(numberTypeRecord.RelatedEvent.Id, relatedEventDate);
            }

            return this;
        }

        public InprotechCaseBuilder WithCaseEvent(int eventId, DateTime? date)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);
            var caseEvent = new CaseEvent(_case.Id, eventId, 1) {EventDate = date}.In(_db);

            if (!_db.Set<Event>().Any(_ => _.Id == eventId))
            {
                var @event = new EventBuilder().Build().In(_db).WithKnownId(eventId);
                caseEvent.Event = @event;
            }

            _case.CaseEvents.Add(caseEvent);

            return this;
        }

        public InprotechCaseBuilder WithRelatedCaseEntity(string country, string officialNumber, CaseRelation relation, DateTime? dateTime)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            _case.RelatedCases.Add(new RelatedCase(_case.Id, country, officialNumber, relation) {PriorityDate = dateTime}.In(_db));

            return this;
        }

        public InprotechCaseBuilder WithRelatedCaseEntity(Case @case, CaseRelation relation)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            _case.RelatedCases.Add(new RelatedCase(_case.Id, null, null, relation, @case.Id).In(_db));

            return this;
        }

        public InprotechCaseBuilder WithStatus()
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            _case.CaseStatus.In(_db);

            return this;
        }

        public InprotechCaseBuilder WithRelatedCaseEntity(string irn, string country, string officialNumber, CaseRelation relation, DateTime? dateTime, short statusId = 0)
        {
            _case = _case ?? new CaseBuilder().Build().In(_db);

            var relatedCaseBuilder = new CaseBuilder
            {
                Irn = irn,
                CountryCode = country,
                Status = new Status(statusId, "status").In(_db)
            };
            var relatedCase = relatedCaseBuilder.Build().In(_db);
            relatedCase.CaseEvents.Add(new CaseEvent(relatedCase.Id, relation.FromEventId ?? 0, 1) {EventDate = dateTime}.In(_db));

            var numberType = _db.Set<NumberType>().First(_ => _.NumberTypeCode == "A");
            var officialNo = new OfficialNumber(numberType, relatedCase, officialNumber).In(_db);
            officialNo.MarkAsCurrent();
            relatedCase.OfficialNumbers.Add(officialNo);
            relatedCase.CurrentOfficialNumber = officialNo.Number;

            _case.RelatedCases.Add(new RelatedCase(_case.Id, country, officialNumber, relation, relatedCase.Id).In(_db));

            return this;
        }
    }

    public static class MasterDataBuilder
    {
        public static CaseRelation BuildCaseRelation(InMemoryDbContext db, string relationship, int eventId)
        {
            return new CaseRelation(relationship, eventId) {FromEvent = BuildEvent(db, eventId, "Event")}.In(db);
        }

        public static Event BuildEvent(InMemoryDbContext db, int eventId, string description)
        {
            return new Event(eventId) {Description = description}.In(db);
        }

        public static void BuildNumberTypeAndRelatedEvent(InMemoryDbContext db, string numberTypeId, string name, int relatedEvent)
        {
            new NumberType(numberTypeId, name, relatedEvent)
            {
                IssuedByIpOffice = true,
                RelatedEvent = BuildEvent(db, relatedEvent, "Event")
            }.In(db);
        }
    }
}