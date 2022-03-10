using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    internal class EntryControlDbSetup : DbSetup
    {
        static readonly string CriteriaDescription = Fixture.Prefix("criteria");
        static readonly string EntryDescription = Fixture.Prefix("entry");
        static readonly string UserInstructions = Fixture.Prefix("user-instructions");
        static readonly string OfficialNumberTypeDescription = Fixture.Prefix("number-type");
        static readonly string FileLocationDescription = Fixture.Prefix("file-location");
        static readonly string EventDescription = Fixture.Prefix("event");
        static readonly string EventToUpdateDescription = Fixture.Prefix("event-to-update");
        static readonly string CaseStatusDescription = Fixture.Prefix("entry-case-status");
        static readonly string RenewalStatusDescription = Fixture.Prefix("entry-renewal-status");
        static readonly string DocumentName = Fixture.Prefix("document");
        static readonly string DisplayEventDescription = Fixture.Prefix("display-event");
        static readonly string HideEventDescription = Fixture.Prefix("hide-event");
        static readonly string DimEventDescription = Fixture.Prefix("div-event");
        static readonly string EntryStepOriginalTitle = Fixture.Prefix("original-title");
        static readonly string EntryStepTitle = Fixture.Prefix("step-title");
        static readonly string EntryStepNameTypeTitle = Fixture.Prefix("name-type");
        static readonly string EntryStepTextTypeTitle = Fixture.Prefix("text-type");
        static readonly string EntryStepScreenTip = Fixture.Prefix("screen-tips");

        public DataFixture SetUp()
        {
            var criteria = InsertWithNewId(new Criteria
                                           {
                                               Description = CriteriaDescription,
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                               UserDefinedRule = 0,
                                               RuleInUse = 1,
                                               LocalClientFlag = 1
                                           });

            var officialNumberType = InsertWithNewId(new NumberType {Name = OfficialNumberTypeDescription}, v => v.NumberTypeCode);
            var fileLocation = InsertWithNewId(new TableCode
                                               {
                                                   TableTypeId = (int) TableTypes.FileLocation,
                                                   Name = FileLocationDescription
                                               });
            var displayEvent = InsertWithNewId(new Event {Description = DisplayEventDescription});
            var hideEvent = InsertWithNewId(new Event {Description = HideEventDescription});
            var dimEvent = InsertWithNewId(new Event {Description = DimEventDescription});
            var baseEvent = InsertWithNewId(new Event
                                            {
                                                Description = EventDescription + "-base"
                                            });

            var caseStatus = InsertWithNewId(new Status
                                             {
                                                 Name = CaseStatusDescription,
                                                 RenewalFlag = 0
                                             });

            var renewalStatus = InsertWithNewId(new Status
                                                {
                                                    Name = RenewalStatusDescription,
                                                    RenewalFlag = 1
                                                });

            var baseEventToUpdate = InsertWithNewId(new Event
                                                    {
                                                        Description = EventToUpdateDescription + "_base"
                                                    });

            var @event = Insert(new ValidEvent(criteria, baseEvent, EventDescription));

            var eventToUpdate = Insert(new ValidEvent(criteria, baseEventToUpdate, EventToUpdateDescription));

            var entry = Insert(new DataEntryTask
                               {
                                   CriteriaId = criteria.Id,
                                   Description = EntryDescription,
                                   UserInstruction = UserInstructions,
                                   OfficialNumberType = officialNumberType,
                                   FileLocation = fileLocation,
                                   ShouldPoliceImmediate = true,
                                   CaseStatus = caseStatus,
                                   RenewalStatus = renewalStatus,
                                   DisplayEventNo = displayEvent.Id,
                                   DisplayEvent = displayEvent,
                                   HideEventNo = hideEvent.Id,
                                   HideEvent = hideEvent,
                                   DimEventNo = dimEvent.Id,
                                   DimEvent = dimEvent
                               });

            var screen = InsertWithNewId(new Screen
                                         {
                                             ScreenTitle = EntryStepOriginalTitle,
                                             ScreenType = "X"
                                         });

            var nameType = InsertWithNewId(new InprotechKaizen.Model.Cases.NameType("e2e", EntryStepNameTypeTitle));

            var textType = InsertWithNewId(new TextType
                                           {
                                               TextDescription = EntryStepTextTypeTitle
                                           });

            var entryStep = Insert(new WindowControl(criteria.Id, entry.Id) {IsInherited = true});
            var topicControl = new TopicControl(EntryStepOriginalTitle)
                               {
                                   RowPosition = 0,
                                   ScreenTip = EntryStepScreenTip,
                                   IsInherited = true,
                                   IsMandatory = true,
                                   Title = EntryStepTitle,
                                   Name = screen.ScreenName
                               };
            entryStep.TopicControls.Add(topicControl);

            topicControl.Filters.Add(new TopicControlFilter("TextTypeKey", textType.Id));
            topicControl.Filters.Add(new TopicControlFilter("NameTypeKey", nameType.NameTypeCode));

            var role = InsertWithNewId(new Role
            {
                RoleName = Fixture.String(5)
            });

            Insert(new RolesControl(role.Id, criteria.Id, entry.Id) {Inherited = true});

            var name = new NameBuilder(DbContext).CreateStaff();
            var user = InsertWithNewId(new User(Fixture.String(5), false) {Name = name});
            role.Users = new List<User> { user };

            DbContext.SaveChanges();

            Insert(new AvailableEvent
                   {
                       CriteriaId = criteria.Id,
                       DataEntryTaskId = entry.Id,
                       IsInherited = true,
                       Event = baseEvent,
                       AlsoUpdateEvent = baseEventToUpdate,
                       EventAttribute = 0,
                       DueAttribute = 1,
                       PolicingAttribute = 2,
                       PeriodAttribute = 3
                   });

            var document = InsertWithNewId(new Document
                                           {
                                               Name = DocumentName,
                                               DocumentType = 1
                                           });

            Insert(new DocumentRequirement(criteria, entry, document, true) {Inherited = 1});

            return new DataFixture
                   {
                       CriteriaId = criteria.Id.ToString(),
                       EntryDescription = entry.Description,
                       UserInstructions = entry.UserInstruction,
                       EventNameInDetails = @event.Description,
                       EventNoInDetails = @event.EventId.ToString(),
                       EventToUpdateInDetails = eventToUpdate.Description,
                       EventToUpdateNoInDetails = eventToUpdate.EventId.ToString(),
                       EventDateInDetails = "Display Only",
                       DueDateInDetails = "Must Enter",
                       PolicingInDetails = "Hide",
                       PeriodInDetails = "Optional Entry",
                       ChangeCaseStatus = caseStatus.Name,
                       ChangeRenewalStatus = renewalStatus.Name,
                       DocumentNameInDocuments = DocumentName,
                       DisplayEventId = entry.DisplayEvent.Id,
                       HideEventId = entry.HideEvent.Id,
                       DimEventId = entry.DimEvent.Id,
                       DisplayEventDescription = entry.DisplayEvent.Description,
                       HideEventDescription = entry.HideEvent.Description,
                       DimEventDescription = entry.DimEvent.Description,
                       EntryStepTitle = EntryStepTitle,
                       EntryStepOriginalTitle = screen.ScreenTitle,
                       EntryStepCategory1 = "Name Type",
                       EntryStepCategory2 = "Text Type",
                       EntryStepCategoryValue1 = EntryStepNameTypeTitle,
                       EntryStepCategoryValue2 = EntryStepTextTypeTitle,
                       EntryStepScreenTip = EntryStepScreenTip,
                       UserAccessRoleName = role.RoleName,
                       UserLogInInRole = user.UserName,
                       UserNameInRole = user.Name.LastName + ", " + user.Name.FirstName
                   };
        }

        public int SetUpSeparatorEntry(string description)
        {
            var criteria = InsertWithNewId(new Criteria
            {
                Description = CriteriaDescription,
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                UserDefinedRule = 0,
                RuleInUse = 1,
                LocalClientFlag = 1
            });

            Insert(new DataEntryTask
            {
                CriteriaId = criteria.Id,
                Description = description,
                IsSeparator = true
            });

            return criteria.Id;
        }

        public Event AddEvent(string baseDescription)
        {
            return InsertWithNewId(new Event
                                   {
                                       Description = baseDescription
                                   });
        }

        public void AddValidEventFor(Criteria criteria, Event @event, string validDescription = null)
        {
            Insert(new ValidEvent(criteria, @event, validDescription));
        }

        public string[] GetAllScreenTypes()
        {
            return new[]
                   {
                       "Case Summary", "Checklist", "Designated Countries", "Agreement Cases", "Related Cases",
                       "Names", "Official Nos", "Multiple Name Types", "Case Text Summary", "Text", "Name Text"
                   };
        }

        public string[] AddStepForAllScreensTypes(Criteria criteria, DataEntryTask entry)
        {
            var windowControl = Insert(new WindowControl(criteria.Id, entry.Id));

            var screens = new[]
                          {
                              "frmCaseEventSummry", "frmCheckList", "frmDesignation", "frmAgreementCases",
                              "frmRelationships", "frmNames", "frmOfficialNo", "frmNameGrp",
                              "frmCaseTextSummry", "frmText", "frmNameText"
                          };

            foreach (var screen in screens)
            {
                windowControl.TopicControls.Add(new TopicControl(screen) {Name = screen, Title = screen, TopicSuffix = RandomString.Next(5)});
            }

            entry.TaskSteps.Add(windowControl);
            return screens;
        }

        public dynamic AddValidAction(Country country, CaseType caseType, PropertyType propertyType)
        {
            var action = new ActionBuilder(DbContext).Create(Fixture.Prefix("e2e step action"));

            var validAction = Insert(new ValidAction(Fixture.Prefix("e2e step valid action"), action, country, caseType, propertyType));

            return new
                   {
                       Base = action.Name,
                       Valid = validAction.ActionName
                   };
        }

        public dynamic AddValidChecklist(Country country, CaseType caseType, PropertyType propertyType)
        {
            var checklist = InsertWithNewId(new CheckList {Description = Fixture.Prefix("e2e checklist") });

            var validChecklist = Insert(new ValidChecklist(country, propertyType, caseType, checklist)
                                        {
                                            ChecklistDescription = Fixture.Prefix("e2e valid checklist")
                                        });

            return new
                   {
                       Base = checklist.Description,
                       Valid = validChecklist.ChecklistDescription
                   };
        }

        public string AddRelationship(Country country, PropertyType propertyType)
        {
            var description = Fixture.Prefix("e2e case relation");

            var relationship = InsertWithNewId(new CaseRelation(description, null) {Description = description});

            Insert(new ValidRelationship(country, propertyType, relationship));

            return description;
        }

        public string AddName()
        {
            return new NameTypeBuilder(DbContext).Create().Name;
        }

        public string AddOfficialNumber()
        {
            return InsertWithNewId(new NumberType {Name = Fixture.Prefix("e2e number")}, v => v.NumberTypeCode).Name;
        }

        public string AddTextType()
        {
            return InsertWithNewId(new TextType {TextDescription = Fixture.Prefix("e2e text type"), UsedByFlag = null}).TextDescription;
        }

        public string AddCountryFlag(Country country)
        {
            return Insert(new CountryFlag(country.Id, 1, Fixture.Prefix("e2e country Flag"))).Name;
        }

        public string AddNameGroup()
        {
            return InsertWithNewId(new NameGroup { Value = Fixture.Prefix("e2e name group")}).Value;
        }

        public TopicControl AddNameStepWithFilter(Criteria criteria, DataEntryTask entry)
        {
            var windowControl = DbContext.Set<WindowControl>().SingleOrDefault(_ => _.CriteriaId == criteria.Id && _.EntryNumber == entry.Id) ??
                                Insert(new WindowControl(criteria.Id, entry.Id));

            var topicControl = new TopicControl("frmNames") {Name = "frmNames", Title = "frmNames", TopicSuffix = RandomString.Next(5), RowPosition = Convert.ToInt16(windowControl.TopicControls.Count + 1)};
            windowControl.TopicControls.Add(topicControl);

            var nameType = new NameTypeBuilder(DbContext).Create();
            topicControl.Filters.Add(new TopicControlFilter("NameTypeKey", nameType.NameTypeCode));

            return topicControl;
        }

        public TopicControl AddOfficialNumberWithFilter(Criteria criteria, DataEntryTask entry, string title)
        {
            var windowControl = DbContext.Set<WindowControl>().SingleOrDefault(_ => _.CriteriaId == criteria.Id && _.EntryNumber == entry.Id) ??
                                Insert(new WindowControl(criteria.Id, entry.Id));

            var topicControl = new TopicControl("frmOfficialNo") {Name = "frmOfficialNo", Title = title, TopicSuffix = RandomString.Next(5), RowPosition = Convert.ToInt16(windowControl.TopicControls.Count + 1)};
            windowControl.TopicControls.Add(topicControl);

            var numberType = InsertWithNewId(new NumberType {Name = Fixture.Prefix("e2e number")}, v => v.NumberTypeCode);
            topicControl.Filters.Add(new TopicControlFilter("NumberTypeKeys", numberType.NumberTypeCode));
            return topicControl;
        }

        public class DataFixture
        {
            public string CriteriaId { get; set; }
            public string EntryDescription { get; set; }
            public string UserInstructions { get; set; }
            public string OfficialNumberType => OfficialNumberTypeDescription;
            public string FileLocation => FileLocationDescription;
            public string EventNameInDetails { get; set; }
            public string EventNoInDetails { get; set; }
            public string EventToUpdateInDetails { get; set; }
            public string EventToUpdateNoInDetails { get; set; }
            public string EventDateInDetails { get; set; }
            public string DueDateInDetails { get; set; }
            public string PolicingInDetails { get; set; }
            public string PeriodInDetails { get; set; }
            public string ChangeCaseStatus { get; set; }
            public string ChangeRenewalStatus { get; set; }
            public string DocumentNameInDocuments { get; set; }
            public string DisplayEventDescription { get; set; }
            public string HideEventDescription { get; set; }
            public string DimEventDescription { get; set; }
            public string EntryStepOriginalTitle { get; set; }
            public string EntryStepTitle { get; set; }
            public string EntryStepCategory1 { get; set; }
            public string EntryStepCategoryValue1 { get; set; }
            public string EntryStepCategory2 { get; set; }
            public string EntryStepCategoryValue2 { get; set; }
            public string EntryStepScreenTip { get; set; }
            public string UserAccessRoleName { get; set; }
            public string UserLogInInRole { get; set; }
            public string UserNameInRole { get; set; }

            public int DisplayEventId { get; set; }
            public int HideEventId { get; set; }
            public int DimEventId { get; set; }
        }
    }
}