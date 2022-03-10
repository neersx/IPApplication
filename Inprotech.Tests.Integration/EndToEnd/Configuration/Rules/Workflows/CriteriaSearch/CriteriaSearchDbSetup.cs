using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    public class CriteriaSearchDbSetup : DbSetup
    {
        internal const string Irn = "e2e";
        internal const string NameCode = "e2e";
        internal const string InstructorName = "e2eInstructor";
        internal const string EventDescription = "e2eEvent";

        internal const string CaseTypeDescription = "e2e - case type";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string PropertyTypeDescription = "e2e - property type";
        internal const string PropertyTypeDescription2 = PropertyTypeDescription + "2";
        internal const string ActionDescription = "e2e - action";
        internal const string CaseCategoryDescription = "e2e - case category";
        internal const string SubTypeDescription = "e2e - sub type";
        internal const string BasisDescription = "e2e - basis";
        internal const string OfficeDescription = "e2e - office";
        internal const string OfficeDescription1 = "e2e - office1";
        internal const string InvalidCaseTypeDescription = "e2e - invalid case type";
        internal const string InvalidJurisdictionDescription = "e2e - invalid jurisdiction";
        internal const string InvalidJurisdictionCode = "e2*";
        internal const string InvalidPropertyTypeDescription = "e2e - invalid property type";
        internal const string InvalidCaseCategoryDescription = "e2e - invalid case category";
        internal const string InvalidBasisDescription = "e2e - invalid basis";
        internal const string ValidPropertyTypeDescription = "e2e - valid property type";
        internal const string ValidCaseCategoryDescription = "e2e - valid case category";
        internal const string ValidSubTypeDescription = "e2e - valid sub type";
        internal const string ValidActionDescription = "e2e - valid action";
        internal const string ValidBasisDescription = "e2e - valid basis";

        internal const int CriteriaCount = 5;
        const string CriteriaDescription1 = "e2e - events and entries - criteria 001";
        const string CriteriaDescription2 = "e2e - events and entries - criteria 002";
        const string CriteriaDescription3 = "e2e - events and entries - criteria 003";
        const string CriteriaDescription4 = "e2e - events and entries - criteria 004";
        const string CriteriaForFilter = "e2e - events and entries - criteria 005";

        const string CriteriaDescriptionChild = "e2e - events and entries - criteria child";
        const string CriteriaDescriptionParent = "e2e - events and entries - criteria parent";

        internal const string InvalidEventDescription = "e2e - InvalidEvent";
        internal const string EventControlDescription = "e2e - EventControl";
        internal const string UpdateFromEventDescription = "e2e - UpdateFromEvent";
        internal const string DueDateEventDescription = "e2e - DueDateEvent";
        internal const string DatesLogicEventDescription = "e2e - DatesLogicEvent";
        internal const string RelatedEventsEventDescription = "e2e - RelatedEventsEvent";
        internal const string RequiredEventsEventDescription = "e2e - RequiredEventsEvent";
        internal const string DetailDatesEventDescription = "e2e - DetailDatesEvent";
        internal const string DetailControlEventDescription = "e2e - DetailControlEventDescription";

        internal const string CaseRelationDescription = "e2e relationship";
        internal const string StatusDescription = "e2e - Status";
        string _actionCode;
        string _basisCode;
        string _caseCategoryCode;
        string _caseTypeCode;

        DateTime _dateOfLaw;
        int _eventId;
        string _jurisdictionCode;
        int _officeCode;
        int _officeCode1;
        string _propertyTypeCode;
        string _subTypeCode;
        int _unreferencedEventId;

        public Result Setup(string criteriaDescription = CriteriaDescription1)
        {
            PrepareValidCharacteristics();
            PrepareInvalidCharacteristics();
            PrepareHighestParentCriteria();

            var retval = new Result
                         {
                             CriteriaNo = PrepareCharacteristicsCriteria(),
                             InheritedCriteriaNo = PrepareInheritedCriteria(),
                             FormattedDateOfLaw = _dateOfLaw.ToString("dd-MMM-yyyy"),
                             EventId = _eventId,
                             UnreferencedEventId = _unreferencedEventId
                         };

            #region referenced events

            var criteria = DbContext.Set<Criteria>().Single(x => x.Id == retval.CriteriaNo);
            var @event = DbContext.Set<Event>().Single(x => x.Id == _eventId);
            var eventId = DbContext.Set<Event>().Max(x => x.Id) + 1;

            // eventcontrol

            var updateFromEvent = new Event(eventId++) {Description = UpdateFromEventDescription};
            DbContext.Set<Event>().Add(updateFromEvent);
            DbContext.SaveChanges();

            var nameType = DbContext.Set<InprotechKaizen.Model.Cases.NameType>().First();
            var name = DbContext.Set<Name>().First();

            var eventControl = new ValidEvent(retval.CriteriaNo, retval.EventId, EventControlDescription)
                               {
                                   SyncedEventId = updateFromEvent.Id,
                                   SaveDueDate = 8,
                                   DateToUse = "E",
                                   RecalcEventDate = true,
                                   ExtendPeriod = 6,
                                   ExtendPeriodType = "M",
                                   SuppressDueDateCalculation = true,
                                   Name = name,
                                   DueDateRespNameType = nameType
                               };
            DbContext.Set<ValidEvent>().Add(eventControl);
            DbContext.SaveChanges();

            retval.ReferencedEvents.UpdateFrom = updateFromEvent.Id;

            // duedatecalc

            var dueDateEvent = new Event(eventId++) {Description = DueDateEventDescription};
            DbContext.Set<Event>().Add(dueDateEvent);
            DbContext.SaveChanges();

            var dueDateCalc = new DueDateCalc(eventControl, 0) {CompareEventId = dueDateEvent.Id, FromEventId = dueDateEvent.Id};
            DbContext.Set<DueDateCalc>().Add(dueDateCalc);
            DbContext.SaveChanges();

            retval.ReferencedEvents.DueDate = dueDateEvent.Id;

            // dateslogic

            var datesLogicEvent = new Event(eventId++) {Description = DatesLogicEventDescription};
            DbContext.Set<Event>().Add(datesLogicEvent);
            DbContext.SaveChanges();

            var datesLogic = new DatesLogic(eventControl, 0) {CompareEventId = datesLogicEvent.Id};
            DbContext.Set<DatesLogic>().Add(datesLogic);
            DbContext.SaveChanges();

            retval.ReferencedEvents.DatesLogic = datesLogicEvent.Id;

            // relatedevents

            var relatedEventsEvent = new Event(eventId++) {Description = RelatedEventsEventDescription};
            DbContext.Set<Event>().Add(relatedEventsEvent);
            DbContext.SaveChanges();

            var relatedEvent = new RelatedEventRule(eventControl, 0) {RelatedEventId = relatedEventsEvent.Id};
            DbContext.Set<RelatedEventRule>().Add(relatedEvent);
            DbContext.SaveChanges();

            retval.ReferencedEvents.RelatedEvents = relatedEventsEvent.Id;

            // Event required
            var requiredEventsEvent = new Event(eventId++) { Description = RequiredEventsEventDescription };
            DbContext.Set<Event>().Add(requiredEventsEvent);
            DbContext.SaveChanges();

            var requiredEvent = new RequiredEventRule(eventControl, requiredEventsEvent);
            DbContext.Set<RequiredEventRule>().Add(requiredEvent);
            DbContext.SaveChanges();

            retval.ReferencedEvents.EventRequired = requiredEventsEvent.Id;

            // detaildates

            var detailDatesEvent = new Event(eventId++) {Description = DetailDatesEventDescription};
            DbContext.Set<Event>().Add(detailDatesEvent);
            DbContext.SaveChanges();

            var dataEntryTask = new DataEntryTask(criteria, 0);
            var detailDate = new AvailableEvent(dataEntryTask, @event, detailDatesEvent);

            DbContext.Set<DataEntryTask>().Add(dataEntryTask);
            DbContext.Set<AvailableEvent>().Add(detailDate);
            DbContext.SaveChanges();

            retval.ReferencedEvents.DetailDates = detailDatesEvent.Id;

            // detailcontrol

            var detailControlEvent = new Event(eventId++) {Description = DetailControlEventDescription};
            DbContext.Set<Event>().Add(detailControlEvent);
            DbContext.SaveChanges();

            var dataEntryTask1 = new DataEntryTask(criteria, 1) {DisplayEventNo = detailControlEvent.Id};
            DbContext.Set<DataEntryTask>().Add(dataEntryTask1);
            DbContext.SaveChanges();

            retval.ReferencedEvents.DetailControl = detailControlEvent.Id;

            #endregion

            #region Dates Logic

            var caseRelation = DbContext.Set<CaseRelation>().Add(new CaseRelation("e2e", CaseRelationDescription, null));
            DbContext.Set<DatesLogic>().Add(new DatesLogic(eventControl, 1) {DateTypeId = 0, Operator = "<", CompareEvent = eventControl.Event, CompareDateTypeId = 1, CaseRelationship = caseRelation});

            #endregion

            DbContext.SaveChanges();

            retval.DueDate.Name = name.Formatted();
            retval.DueDate.NameType = nameType.Name;
            retval.DueDate.ExtendPeriod = eventControl.ExtendPeriod.ToString();

            return retval;
        }

        void PrepareHighestParentCriteria()
        {
            var newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
            var parentId = newId + 1;
            DbContext.Set<Criteria>().Add(new Criteria { Id = newId, Description = CriteriaDescriptionChild, PurposeCode = CriteriaPurposeCodes.EventsAndEntries });
            DbContext.Set<Criteria>().Add(new Criteria { Id = parentId, Description = CriteriaDescriptionParent, PurposeCode = CriteriaPurposeCodes.EventsAndEntries });
            DbContext.Set<Inherits>().Add(new Inherits(newId, parentId));
            DbContext.SaveChanges();
        }

        int PrepareInheritedCriteria()
        {
            var newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
            var parentId = newId + 1;
            DbContext.Set<Criteria>().Add(new Criteria {Id = newId, Description = CriteriaDescriptionChild, PurposeCode = CriteriaPurposeCodes.EventsAndEntries, UserDefinedRule = 1, RuleInUse = 1});
            DbContext.Set<Criteria>().Add(new Criteria {Id = parentId, Description = CriteriaDescriptionParent, PurposeCode = CriteriaPurposeCodes.EventsAndEntries, UserDefinedRule = 1, RuleInUse = 1 });
            DbContext.Set<Inherits>().Add(new Inherits(newId, parentId));
            DbContext.SaveChanges();
            return newId;
        }

        void PrepareValidCharacteristics()
        {
            _dateOfLaw = new DateTime(2015, 12, 21);

            // Base ObjectsPropertyType

            var caseType = DbContext.Set<CaseType>().SingleOrDefault(_ => _.Name == CaseTypeDescription) ??
                           DbContext.Set<CaseType>().Add(new CaseType("_", CaseTypeDescription));

            var jurisdiction = DbContext.Set<Country>().SingleOrDefault(_ => _.Name == JurisdictionDescription) ??
                               DbContext.Set<Country>()
                                        .Add(new Country("e2e", JurisdictionDescription, "0") {AllMembersFlag = 0});

            var propertyType = DbContext.Set<PropertyType>().SingleOrDefault(_ => _.Name == PropertyTypeDescription) ??
                               DbContext.Set<PropertyType>().Add(new PropertyType("_", PropertyTypeDescription));

            if (!DbContext.Set<PropertyType>().Any(_ => _.Name == PropertyTypeDescription2))
            {
                DbContext.Set<PropertyType>().Add(new PropertyType("!", PropertyTypeDescription2));
            }

            var action = DbContext.Set<Action>().SingleOrDefault(_ => _.Name == ActionDescription) ??
                         DbContext.Set<Action>().Add(new Action(id: "e2", name: ActionDescription));

            var subType = DbContext.Set<SubType>().SingleOrDefault(_ => _.Name == SubTypeDescription) ??
                          DbContext.Set<SubType>().Add(new SubType("e2", SubTypeDescription));

            var basis = DbContext.Set<ApplicationBasis>().SingleOrDefault(_ => _.Name == BasisDescription) ??
                        DbContext.Set<ApplicationBasis>().Add(new ApplicationBasis("e2", BasisDescription));

            var newOfficeId = DbContext.Set<Office>().Max(_ => _.Id) + 1;
            var office = DbContext.Set<Office>().SingleOrDefault(_ => _.Name == OfficeDescription) ??
                         DbContext.Set<Office>().Add(new Office(newOfficeId, OfficeDescription));
            var office1 = DbContext.Set<Office>().SingleOrDefault(_ => _.Name == OfficeDescription1) ??
                          DbContext.Set<Office>().Add(new Office(newOfficeId + 1, OfficeDescription1));

            DbContext.SaveChanges();

            var caseCategory = DbContext.Set<CaseCategory>().SingleOrDefault(_ => _.Name == CaseCategoryDescription);
            if (caseCategory == null)
            {
                caseCategory =
                    DbContext.Set<CaseCategory>().Add(new CaseCategory(caseType.Code, "e2", CaseCategoryDescription));
                DbContext.SaveChanges();
            }

            // Valid objects
            var dateOfLaw = DbContext.Set<DateOfLaw>().SingleOrDefault(_ => _.Date == _dateOfLaw);

            if (dateOfLaw == null)
            {
                dateOfLaw = new DateOfLaw
                            {
                                PropertyType = propertyType,
                                Country = jurisdiction,
                                Date = _dateOfLaw
                            };

                DbContext.Set<DateOfLaw>().Add(dateOfLaw);
            }

            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == ValidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                                                   {
                                                       CountryId = jurisdiction.Id,
                                                       PropertyTypeId = propertyType.Code,
                                                       PropertyName = ValidPropertyTypeDescription
                                                   });
            }

            if (!DbContext.Set<ValidCategory>().Any(_ => _.CaseCategoryDesc == ValidCaseCategoryDescription))
            {
                DbContext.Set<ValidCategory>().Add(new ValidCategory
                                                   {
                                                       CountryId = jurisdiction.Id,
                                                       PropertyTypeId = propertyType.Code,
                                                       CaseTypeId = caseType.Code,
                                                       CaseCategoryId = caseCategory.CaseCategoryId,
                                                       CaseCategoryDesc = ValidCaseCategoryDescription
                                                   });
            }

            if (!DbContext.Set<ValidSubType>().Any(_ => _.SubTypeDescription == ValidSubTypeDescription))
            {
                DbContext.Set<ValidSubType>().Add(new ValidSubType
                                                  {
                                                      CountryId = jurisdiction.Id,
                                                      PropertyTypeId = propertyType.Code,
                                                      CaseTypeId = caseType.Code,
                                                      CaseCategoryId = caseCategory.CaseCategoryId,
                                                      SubtypeId = subType.Code,
                                                      SubTypeDescription = ValidSubTypeDescription
                                                  });
            }

            if (!DbContext.Set<ValidAction>().Any(_ => _.ActionName == ValidActionDescription))
            {
                DbContext.Set<ValidAction>()
                         .Add(new ValidAction(ValidActionDescription, action, jurisdiction, caseType, propertyType));
            }

            if (!DbContext.Set<ValidBasis>().Any(_ => _.BasisDescription == ValidBasisDescription))
            {
                DbContext.Set<ValidBasis>().Add(new ValidBasis(jurisdiction, propertyType, basis)
                                                {
                                                    BasisDescription = ValidBasisDescription
                                                });
            }
            DbContext.SaveChanges();

            if (!DbContext.Set<ValidBasisEx>().Any(_ => _.BasisId == basis.Code))
            {
                DbContext.Set<ValidBasisEx>().Add(new ValidBasisEx(caseType, caseCategory)
                                                  {
                                                      CountryId = jurisdiction.Id,
                                                      PropertyTypeId = propertyType.Code,
                                                      BasisId = basis.Code
                                                  });
                DbContext.SaveChanges();
            }

            #region case

            var newCaseId = DbContext.Set<Case>().Max(_ => _.Id) + 1;
            var @case = new Case(newCaseId, Irn, jurisdiction, caseType, propertyType)
                        {
                            Office = office,
                            SubType = subType,
                            CategoryId = caseCategory.CaseCategoryId,
                            LocalClientFlag = 0
                        };

            DbContext.Set<Case>().Add(@case);

            DbContext.SaveChanges();

            #endregion

            #region basis

            var statusId = DbContext.Set<Status>().Max(_ => _.Id) + 1;
            var status = new Status((short) statusId, StatusDescription);

            var caseProperty = new CaseProperty(@case, basis, status);

            DbContext.Set<Status>().Add(status);
            DbContext.Set<CaseProperty>().Add(caseProperty);

            #endregion

            #region instructor

            var newNameId = DbContext.Set<Name>().Max(_ => _.Id) + 1;
            var name = new Name(newNameId) {NameCode = NameCode, LastName = InstructorName};
            var nameType = DbContext.Set<InprotechKaizen.Model.Cases.NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Instructor);
            var caseName = new CaseName(@case, nameType, name, 0);
            DbContext.Set<CaseName>().Add(caseName);

            #endregion

            #region event

            var newEventNo = DbContext.Set<Event>().Max(_ => _.Id) + 1;
            var @event = new Event(newEventNo) {Description = EventDescription};
            DbContext.Set<Event>().Add(@event);

            DbContext.SaveChanges();

            var caseEvent = new CaseEvent(@case.Id, newEventNo, 1) {EventDate = DateTime.Today};
            DbContext.Set<CaseEvent>().Add(caseEvent);

            #endregion

            #region DateOfLaw event

            dateOfLaw.LawEventId = caseEvent.EventNo;

            #endregion

            #region unreferenced event

            var unreferencedEvent = DbContext.Set<Event>().SingleOrDefault(_ => _.Description == InvalidEventDescription);
            if (unreferencedEvent == null)
            {
                unreferencedEvent = new Event(newEventNo + 1) {Description = InvalidEventDescription};
                DbContext.Set<Event>().Add(unreferencedEvent);
            }

            #endregion

            DbContext.SaveChanges();

            _jurisdictionCode = jurisdiction.Id;
            _propertyTypeCode = propertyType.Code;
            _actionCode = action.Code;
            _subTypeCode = subType.Code;
            _basisCode = basis.Code;
            _officeCode = office.Id;
            _caseTypeCode = caseType.Code;
            _officeCode1 = office1.Id;
            _caseCategoryCode = caseCategory.CaseCategoryId;
            _eventId = @event.Id;
            _unreferencedEventId = unreferencedEvent.Id;
        }

        void PrepareInvalidCharacteristics()
        {
            var caseType = DbContext.Set<CaseType>().SingleOrDefault(_ => _.Name == InvalidCaseTypeDescription) ??
                           DbContext.Set<CaseType>().Add(new CaseType("*", InvalidCaseTypeDescription));

            var jurisdiction = DbContext.Set<Country>().SingleOrDefault(_ => _.Name == InvalidJurisdictionDescription) ??
                               DbContext.Set<Country>().Add(new Country("e2*", InvalidJurisdictionDescription, "0"));

            var propertyType = DbContext.Set<PropertyType>().SingleOrDefault(_ => _.Name == InvalidPropertyTypeDescription) ??
                               DbContext.Set<PropertyType>().Add(new PropertyType("*", InvalidPropertyTypeDescription));

            var basis = DbContext.Set<ApplicationBasis>().SingleOrDefault(_ => _.Name == InvalidBasisDescription) ??
                        DbContext.Set<ApplicationBasis>().Add(new ApplicationBasis("e*", InvalidBasisDescription));

            DbContext.SaveChanges();

            var caseCategory = DbContext.Set<CaseCategory>().SingleOrDefault(_ => _.Name == InvalidCaseCategoryDescription);
            if (caseCategory == null)
            {
                caseCategory = DbContext.Set<CaseCategory>().Add(new CaseCategory(caseType.Code, "e2", InvalidCaseCategoryDescription));
                DbContext.SaveChanges();
            }

            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == InvalidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                                                   {
                                                       CountryId = jurisdiction.Id,
                                                       PropertyTypeId = propertyType.Code,
                                                       PropertyName = InvalidPropertyTypeDescription
                                                   });
            }

            if (!DbContext.Set<ValidCategory>().Any(_ => _.CaseCategoryDesc == InvalidCaseCategoryDescription))
            {
                DbContext.Set<ValidCategory>().Add(new ValidCategory
                                                   {
                                                       CountryId = jurisdiction.Id,
                                                       PropertyTypeId = propertyType.Code,
                                                       CaseTypeId = caseType.Code,
                                                       CaseCategoryId = caseCategory.CaseCategoryId,
                                                       CaseCategoryDesc = InvalidCaseCategoryDescription
                                                   });
            }

            if (!DbContext.Set<ValidBasis>().Any(_ => _.BasisDescription == InvalidBasisDescription))
            {
                DbContext.Set<ValidBasis>().Add(new ValidBasis(jurisdiction, propertyType, basis)
                                                {
                                                    BasisDescription = InvalidBasisDescription
                                                });
            }
            DbContext.SaveChanges();
        }

        int PrepareCharacteristicsCriteria(string criteriaDescription = CriteriaDescription1, bool asProtected = false)
        {
            var criteria = DbContext.Set<Criteria>().SingleOrDefault(_ => _.Description == criteriaDescription);

            var userDefinedRule = asProtected ? 0 : 1;

            if (criteria == null)
            {
                var country = DbContext.Set<Country>().Single(_ => _.Id == _jurisdictionCode);
                var propertyType = DbContext.Set<PropertyType>().Single(_ => _.Code == _propertyTypeCode);
                var action = DbContext.Set<Action>().Single(_ => _.Code == _actionCode);
                var subType = DbContext.Set<SubType>().Single(_ => _.Code == _subTypeCode);
                var basis = DbContext.Set<ApplicationBasis>().Single(_ => _.Code == _basisCode);
                var office = DbContext.Set<Office>().Single(_ => _.Id == _officeCode);

                var newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
                criteria = new Criteria
                           {
                               Id = newId,
                               CaseTypeId = _caseTypeCode,
                               Country = country,
                               PropertyType = propertyType,
                               CaseCategoryId = _caseCategoryCode,
                               Action = action,
                               SubType = subType,
                               Basis = basis,
                               Office = office,
                               DateOfLaw = _dateOfLaw,
                               Description = criteriaDescription,
                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                               UserDefinedRule = userDefinedRule,
                               RuleInUse = 1,
                               LocalClientFlag = 1
                           };
                DbContext.Set<Criteria>().Add(criteria);
                DbContext.SaveChanges();

                var office1 = DbContext.Set<Office>().Single(_ => _.Id == _officeCode1);
                newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
                var criteria1 = new Criteria
                                {
                                    Id = newId,
                                    CaseTypeId = _caseTypeCode,
                                    Country = country,
                                    PropertyType = propertyType,
                                    CaseCategoryId = _caseCategoryCode,
                                    Action = action,
                                    SubType = subType,
                                    Basis = basis,
                                    Office = office1,
                                    DateOfLaw = _dateOfLaw,
                                    Description = CriteriaDescription2,
                                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                    UserDefinedRule = userDefinedRule,
                                    RuleInUse = 1
                                };
                DbContext.Set<Criteria>().Add(criteria1);
                DbContext.SaveChanges();

                newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
                var criteria2 = new Criteria
                                {
                                    Id = newId,
                                    CaseTypeId = _caseTypeCode,
                                    Country = country,
                                    PropertyType = propertyType,
                                    CaseCategoryId = _caseCategoryCode,
                                    Action = action,
                                    SubType = subType,
                                    Basis = basis,
                                    Office = null,
                                    DateOfLaw = _dateOfLaw,
                                    Description = CriteriaDescription3,
                                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                    UserDefinedRule = userDefinedRule,
                                    RuleInUse = 1
                                };
                DbContext.Set<Criteria>().Add(criteria2);
                DbContext.SaveChanges();

                newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
                DbContext.Set<Criteria>()
                         .Add(new Criteria
                              {
                                  Id = newId,
                                  CaseTypeId = _caseTypeCode,
                                  CountryId = InvalidJurisdictionCode,
                                  PropertyType = propertyType,
                                  CaseCategoryId = _caseCategoryCode,
                                  Action = action,
                                  SubType = subType,
                                  Basis = basis,
                                  Office = null,
                                  DateOfLaw = _dateOfLaw,
                                  Description = CriteriaDescription4,
                                  PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                  UserDefinedRule = userDefinedRule,
                                  RuleInUse = 1
                              });
                DbContext.SaveChanges();

                newId = DbContext.Set<Criteria>().Max(_ => _.Id) + 1;
                DbContext.Set<Criteria>()
                         .Add(new Criteria
                              {
                                  Id = newId,
                                  CaseTypeId = _caseTypeCode,
                                  Description = CriteriaForFilter,
                                  PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                  UserDefinedRule = userDefinedRule,
                                  RuleInUse = 1
                              });
                DbContext.SaveChanges();
            }

            return criteria.Id;
        }

        public class Result
        {
            public int CriteriaNo;
            public string FormattedDateOfLaw;
            public int InheritedCriteriaNo;
            public int EventId { get; set; }
            public int UnreferencedEventId { get; set; }
            public ReferencedEventCollection ReferencedEvents { get; set; } = new ReferencedEventCollection();
            public DueDateData DueDate { get; set; } = new DueDateData();

            public class ReferencedEventCollection
            {
                public int DetailControl { get; set; }
                public int DetailDates { get; set; }
                public int RelatedEvents { get; set; }
                public int DatesLogic { get; set; }
                public int DueDate { get; set; }
                public int EventRequired { get; set; }
                public int UpdateFrom { get; set; }
            }

            public class DueDateData
            {
                public string Name { get; set; }
                public string NameType { get; set; }
                public string ExtendPeriod { get; set; }
            }
        }
    }
}