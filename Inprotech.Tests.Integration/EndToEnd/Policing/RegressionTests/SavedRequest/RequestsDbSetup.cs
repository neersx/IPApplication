using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;
using Action = InprotechKaizen.Model.Cases.Action;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    public class RequestsDbSetup : DbSetup
    {
        readonly string _eventName = @"e2e-event-" + typeof(RequestsDbSetup).Name;
        static readonly string OfficeDescription = Fixture.Prefix("office");
        static readonly string EventDescription = Fixture.Prefix("event");
        static readonly string CaseTypeDescription = Fixture.Prefix("casetype");
        static readonly string JurisdictionDescription = Fixture.Prefix("country");
        static readonly string PropertyTypeDescription = Fixture.Prefix("propertytype");
        static readonly string ActionDescription = Fixture.Prefix("action");
        static readonly string CaseCategoryDescription = Fixture.Prefix("casecategory");
        static readonly string SubTypeDescription = Fixture.Prefix("subtype");

        public RequestsDbSetup()
        {
            Users = new Users(DbContext);
        }

        public Users Users { get; }

        public Case GetCase(string irn = null)
        {
            return new CaseBuilder(DbContext).Create(Fixture.Prefix(irn));
        }

        public RequestsDbSetup WithDefaultPolicingRequest(DateTime? dateEntered = null)
        {
            var criteria = InsertWithNewId(new Criteria
                                           {
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                           });

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = _eventName
                                         });

            Insert(new ValidEvent(criteria, @event, _eventName));

            var @case = GetCase();

            Insert(
                   new PolicingRequest(@case.Id)
                   {
                       Name = "1A E2E-" + RandomString.Next(6),
                       DateEntered = Helpers.UniqueDateTime(dateEntered),
                       IsSystemGenerated = 0,
                       Case = @case,
                       EventNo = @event.Id,
                       CriteriaNo = criteria.Id,
                       EventCycle = 1,
                       OnHold = KnownValues.StringToHoldFlag["waiting-to-start"],
                       TypeOfRequest = (short) KnownValues.StringToTypeOfRequest["event-occurred"]
                   });

            return this;
        }

        public ScenarioData PolicingRequestAndOpenAction(DateTime? dateEntered = null)
        {
            var criteria = InsertWithNewId(new Criteria
                                           {
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                           });

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = _eventName
                                         });

            Insert(new ValidEvent(criteria, @event, _eventName));

            var @case = GetCase();

            var action = Insert(new Action(ActionDescription, id: "e2"));
            Insert(new OpenAction(action, @case, 1, null, criteria, true));

            var request = Insert(
                                 new PolicingRequest
                                 {
                                     Name = "1A E2E-" + RandomString.Next(6),
                                     DateEntered = Helpers.UniqueDateTime(dateEntered),
                                     IsSystemGenerated = 0,
                                     Jurisdiction = @case.Country.Id,
                                     OnHold = KnownValues.StringToHoldFlag["waiting-to-start"],
                                     IsRecalculateCriteria = 1
                                 });

            return new ScenarioData()
                   {
                       RequestId = request.RequestId,
                       RequestDateTime = request.DateEntered,
                       CriteriaId = criteria.Id,
                       EventId = @event.Id,
                       CaseId = @case.Id
                   };
        }

        public ValidCharacteristics SetValidCharacteristics()
        {
            var caseType = InsertWithNewId(new CaseType {Name = CaseTypeDescription});
            var country = InsertWithNewId(new Country {Name = JurisdictionDescription, Type = "0"});
            InsertWithNewId(new Office {Name = OfficeDescription});
            InsertWithNewId(new Event {Description = EventDescription});
            var name = new NameBuilder(DbContext).CreateStaff();
            var nameType = new NameTypeBuilder(DbContext).Create();
            var propertyType = InsertWithNewId(new PropertyType {Name = "base " + PropertyTypeDescription});
            var caseCategory = Insert(new CaseCategory {Name = "base" + CaseCategoryDescription, CaseTypeId = caseType.Code, CaseCategoryId = "e2"});
            var subType = InsertWithNewId(new SubType {Name = "base " + SubTypeDescription});
            var act = InsertWithNewId(new Action {Name = "base " + ActionDescription});

            Insert(new ValidProperty {CountryId = country.Id, PropertyTypeId = propertyType.Code, PropertyName = PropertyTypeDescription});
            Insert(new ValidCategory {CountryId = country.Id, PropertyTypeId = propertyType.Code, CaseCategoryId = caseCategory.CaseCategoryId, CaseTypeId = caseType.Code, CaseCategoryDesc = CaseCategoryDescription});
            Insert(new ValidSubType {CaseCategoryId = caseCategory.CaseCategoryId, CaseTypeId = caseType.Code, PropertyTypeId = propertyType.Code, CountryId = country.Id, SubtypeId = subType.Code, SubTypeDescription = SubTypeDescription});
            Insert(new ValidAction(country.Id, propertyType.Code, caseType.Code, act.Code) {ActionName = ActionDescription});
            return new ValidCharacteristics
                   {
                       Office = OfficeDescription,
                       CaseType = CaseTypeDescription,
                       Jurisdiction = JurisdictionDescription,
                       PropertyType = PropertyTypeDescription,
                       Action = ActionDescription,
                       CaseCategory = CaseCategoryDescription,
                       SubType = SubTypeDescription,
                       EventName = EventDescription,
                       NameType = nameType.Name,
                       Name = name.Formatted()
                   };
        }
    }

    public class ValidCharacteristics
    {
        public string EventName;
        public string PropertyTypeName;
        public string Action;
        public string Office;
        public string CaseType;
        public string Jurisdiction;
        public string PropertyType;
        public string CaseCategory;
        public string SubType;
        public string NameType;
        public string Name;
    }

    public class ScenarioData
    {
        public int RequestId;
        public DateTime RequestDateTime;
        public int CriteriaId;
        public int EventId;
        public int CaseId;
    }
}