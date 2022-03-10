using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Translations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Events
{
    public class EventsPicklistDbSetup : DbSetup
    {
        Importance _existingInternalImportance;
        Importance _existingClientImportance;
        InprotechKaizen.Model.Cases.Events.EventCategory _existingEventCategory;
        TableCode _existingEventGroup;
        TableCode _noteSharingGroup;
        TableCode _toBeDeletedEventGroup;
        TableCode _toBeDeletedEventNotesGroup;
        Image _image;
        Event _draftCaseEvent;
        InprotechKaizen.Model.Cases.Action _existingAction;
        ValidEvent _existingValidEvent;
        ValidEvent _updatableEventControl;
        Event _baseEvent;
        Criteria _eventCriteria;
        TestUser _updateLogin;

        const string ExistingNotes = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum dignissim, neque eu pharetra varius, nulla elit vulputate ex, eu vehicula erat purus at massa. Pellentesque eros turpis, dapibus a lacinia sed, hendrerit sed metus. Sed tempor cras amet.";
        const string ExistingCode = "E2E101";
        const string BaseEventCode = "E2E111";

        public ScenarioData DataSetup(bool withValidEvent = false, string preferredCulture = null)
        {
            var description = Fixture.String(90);
            var draftCaseEvent = Fixture.String(100);
            var translatable = !string.IsNullOrWhiteSpace(preferredCulture);

            var internalImportance = AddImportanceLevel(99, "E2E Internal");
            var clientImportance = AddImportanceLevel(88, "E2E Client");
            _existingInternalImportance = AddImportanceLevel(77, "E2E Internal Existing");
            _existingClientImportance = AddImportanceLevel(55, "E2E Client Existing");
            _image = InsertWithNewId(new Image { ImageData = new byte[] { } });
            _existingEventCategory = InsertWithNewId(new InprotechKaizen.Model.Cases.Events.EventCategory { Name = "E2E Event Category", ImageId = _image.Id });
            _existingEventGroup = InsertWithNewId(new TableCode { TableTypeId = (short)TableTypes.EventGroup, Name = "E2E Event Group" });
            _noteSharingGroup = InsertWithNewId(new TableCode { TableTypeId = (short)TableTypes.NoteSharingGroup, Name = "E2E Notes Group" });
            _toBeDeletedEventGroup = InsertWithNewId(new TableCode { TableTypeId = (short)TableTypes.EventGroup, Name = "Delete this Event Group" });
            _toBeDeletedEventNotesGroup = InsertWithNewId(new TableCode { TableTypeId = (short)TableTypes.NoteSharingGroup, Name = "Delete this Notes Group" });

            var lastinternalCode = DbContext.Set<LastInternalCode>().First(_ => _.TableName.Equals("TABLECODES"));
            lastinternalCode.InternalSequence = _toBeDeletedEventNotesGroup.Id;
            DbContext.SaveChanges();

            _draftCaseEvent = InsertWithNewId(new Event
            {
                Description = draftCaseEvent,
                NumberOfCyclesAllowed = 999,
                InternalImportance = _existingInternalImportance,
                ClientImportance = _existingClientImportance
            }); 

            _existingAction = InsertWithNewId(new InprotechKaizen.Model.Cases.Action { Name = Fixture.String(50) });
            _updateLogin = new Users()
                .WithLicense(LicensedModule.IpMatterManagementModule)
                .WithPermission(ApplicationTask.MaintainWorkflowRules)
                .WithPermission(ApplicationTask.MaintainLists, Deny.Delete)
                .WithPermission(ApplicationTask.MaintainLists, Deny.Create)
                .WithPermission(ApplicationTask.MaintainLists, Allow.Modify).Create("UpdateLogin");

            var updateEvent = AddEvent(description, ExistingCode);
            if (translatable)
            {
                InsertWithNewId(new SettingValues { SettingId = KnownSettingIds.PreferredCulture, CharacterValue = preferredCulture });
                _draftCaseEvent.DescriptionTId = InsertWithNewId(new TranslatedItem {SourceId = 12}).Id;
                Insert(new TranslatedText { CultureId = preferredCulture, ShortText = preferredCulture + draftCaseEvent, Tid = _draftCaseEvent.DescriptionTId.GetValueOrDefault() });
                updateEvent.DescriptionTId = InsertWithNewId(new TranslatedItem { SourceId = 12 }).Id;
                Insert(new TranslatedText { CultureId = preferredCulture, ShortText = preferredCulture + description, Tid = updateEvent.DescriptionTId.GetValueOrDefault() });
            }
            
            if (withValidEvent)
            {
                _baseEvent = AddEvent(Fixture.String(10), BaseEventCode);
                _eventCriteria = InsertWithNewId(new Criteria
                {
                    Description = Fixture.String(20),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                    UserDefinedRule = 1,
                    RuleInUse = 1,
                    LocalClientFlag = 1
                });
                _updatableEventControl = Insert(new ValidEvent(
                    InsertWithNewId(new Criteria
                    {
                        Description = Fixture.String(20),
                        PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                        UserDefinedRule = 1,
                        RuleInUse = 1,
                        LocalClientFlag = 1
                    }), _baseEvent, _baseEvent.Description)
                {
                    ImportanceLevel = _baseEvent.ImportanceLevel,
                    NumberOfCyclesAllowed = _baseEvent.NumberOfCyclesAllowed
                });
                _existingValidEvent = Insert(new ValidEvent(_eventCriteria, _baseEvent, _baseEvent.Description + " Alias")
                {
                    ImportanceLevel = _baseEvent.ImportanceLevel,
                    NumberOfCyclesAllowed = _baseEvent.NumberOfCyclesAllowed
                });
                
                var e = AddEvent(Fixture.String(10), "E2E102");
                Insert(new ValidEvent(_eventCriteria, e, e.Description + " Alias"));
                Insert(new ValidEvent(_eventCriteria, AddEvent(Fixture.String(10), "E2E103"), "E2E103 Event Description Alias"));

                if (translatable)
                {
                    _baseEvent.DescriptionTId = InsertWithNewId(new TranslatedItem { SourceId = 12 }).Id;
                    Insert(new TranslatedText { CultureId = preferredCulture, ShortText = preferredCulture + _baseEvent.Description, Tid = _baseEvent.DescriptionTId.GetValueOrDefault() });
                    _existingValidEvent.DescriptionTId = InsertWithNewId(new TranslatedItem { SourceId = 12 }).Id;
                    Insert(new TranslatedText { CultureId = preferredCulture, ShortText = preferredCulture + _existingValidEvent.Description, Tid = _existingValidEvent.DescriptionTId.GetValueOrDefault() });
                    e.DescriptionTId = InsertWithNewId(new TranslatedItem { SourceId = 12 }).Id;
                    Insert(new TranslatedText { CultureId = preferredCulture, ShortText = preferredCulture + e.Description, Tid = e.DescriptionTId.GetValueOrDefault() });
                }
            }

            var firstEvent = DbContext.Set<Event>().OrderBy(v => v.Description).First();

            return new ScenarioData
            {
                InternalImportance = internalImportance,
                ClientImportance = clientImportance,
                Event = updateEvent,
                ExistingInternalImportance = _existingInternalImportance,
                ExistingClientImportance = _existingClientImportance,
                Notes = ExistingNotes,
                Code = ExistingCode,
                Description = description,
                ExistingCategory = _existingEventCategory.Name,
                ExistingGroup = _existingEventGroup.Name,
                ExistingNotesGroup = _noteSharingGroup.Name,
                DeleteEventGroup = _toBeDeletedEventGroup.Name,
                DeleteEventNotesGroup = _toBeDeletedEventNotesGroup.Name,
                ExistingAction = _existingAction.Name,
                UpdatableEventControl = _updatableEventControl, 
                ExistingEventControl = _existingValidEvent,
                BaseEvent = _baseEvent,
                UpdateLogin = _updateLogin,
                FirstEvent = firstEvent
            };
        }

        Importance AddImportanceLevel(short id, string description)
        {
            var importanceLevel = Insert(new Importance(id.ToString(), description));
            return importanceLevel;
        }

        Event AddEvent(string description, string code)
        {
            var @event = InsertWithNewId(new Event
            {
                Description = description,
                NumberOfCyclesAllowed = 1,
                Notes = ExistingNotes,
                Code = code,
                InternalImportance = _existingInternalImportance,
                ClientImportance = _existingClientImportance,
                RecalcEventDate = true,
                ShouldPoliceImmediate = true,
                SuppressCalculation = true,
                IsAccountingEvent = true,
                CategoryId = _existingEventCategory.Id,
                NoteGroupId = _noteSharingGroup.Id,
                GroupId = _existingEventGroup.Id,
                DraftEventId = _draftCaseEvent.Id,
                ControllingAction = _existingAction.Code
            });
            return @event;
        }

        public class ScenarioData
        {
            public Event Event;
            public Importance InternalImportance;
            public Importance ClientImportance;
            public int EventCategoryId;
            public int EventGroupId;
            public string ActionId;
            public int DraftEventId;
            public Importance ExistingInternalImportance;
            public Importance ExistingClientImportance;
            public string Notes;
            public string Code;
            public string Description;
            public string ExistingCategory;
            public string DeleteEventGroup;
            public string DeleteEventNotesGroup;
            public string ExistingGroup;
            public string ExistingNotesGroup;
            public string ExistingAction;
            public string EventControlDescription;
            public Event BaseEvent;
            public ValidEvent ExistingEventControl;
            public ValidEvent UpdatableEventControl;
            public TestUser UpdateLogin;
            public Event FirstEvent;
        }
    }
}
