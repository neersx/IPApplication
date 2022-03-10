using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Search;
using InprotechKaizen.Model;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    public class CaseDetailsActionsDbSetup : DbSetup
    {
        public bool IsPoliceImmediately
        {
            get => DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceImmediately).BooleanValue ?? false;
            set { DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceImmediately).BooleanValue = value; DbContext.SaveChanges(); }
        }

        public bool EventLinksToWorkflowWizard
        {
            get => DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EventLinktoWorkflowAllowed).BooleanValue ?? false;
            set { DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EventLinktoWorkflowAllowed).BooleanValue = value; DbContext.SaveChanges(); }
        }

        public void ResetDataValidations(List<DataValidation> dataValidations)
        {
            foreach (var dataValidation in dataValidations)
            {
                DbContext.Set<DataValidation>().Single(_ => _.Id == dataValidation.Id).InUseFlag = true;
            }
            DbContext.SaveChanges();
        }

        public (int CaseId, string CaseIrn, Importance MaxImportanceLevel,
            (ValidAction Va, CaseEvent[] events) OpenAction,
            (ValidAction Va, CaseEvent[] events) OpenActionWithMultipleEvents,
            (ValidAction Va, CaseEvent[] events) Closed,
            (ValidAction Va, CaseEvent[] events) Potential, Criteria Criteria, ValidEvent validEvent, CaseEvent caseEvent, Case @case) ActionsSetup(bool withDateLogic = false, bool withRuleDetails = false)
        {
            var @case = new CaseBuilder(DbContext).CreateWithSummaryData().Case;
            var otherCase = new CaseBuilder(DbContext).Create("FromCaseFor" + @case.Id, true);
            var otherName = new NameBuilder(DbContext).CreateClientIndividual("FromName");
            var name = @case.CaseNames.First().Name;

            var tableTypeId = DbContext.Set<TableType>().Max(_ => _.Id) + 1;
            var tableType1 = new TableType((short)tableTypeId) { Name = Fixture.String(5), DatabaseTable = "TABLECODES" };
            var tableType2 = new TableType((short)(tableTypeId + 1)) { Name = Fixture.String(5), DatabaseTable = "TABLECODES" };

            DbContext.Set<TableType>().Add(tableType1);
            DbContext.Set<TableType>().Add(tableType2);

            DbContext.SaveChanges();

            var tableCodeId = DbContext.Set<TableCode>().Max(_ => _.Id) + 1;

            var tableCode1 = new TableCode(tableCodeId, tableType1.Id, Fixture.String(5));
            var tableCode2 = new TableCode(tableCodeId + 1, tableType1.Id, Fixture.String(5));

            DbContext.Set<TableCode>().Add(tableCode1);
            DbContext.Set<TableCode>().Add(tableCode2);
            new ScreenCriteriaBuilder(DbContext).Create(@case, out _).WithTopicControl(KnownCaseScreenTopics.Actions);

            var criteria = new CriteriaBuilder(DbContext).Create();

            criteria.RuleInUse = 1;
            criteria.CaseTypeId = @case.TypeId;

            var criteria1 = new CriteriaBuilder(DbContext).Create();

            criteria.RuleInUse = 1;
            criteria.CaseTypeId = @case.TypeId;

            var criteriaClosed = new CriteriaBuilder(DbContext).Create();

            criteria.RuleInUse = 1;
            criteria.CaseTypeId = @case.TypeId;

            var importanceLevel = Insert(new Importance("91", Fixture.Prefix(Fixture.String(3))));
            var action = InsertWithNewId(new Action(Fixture.Prefix("action"), importanceLevel));
            Insert(new OpenAction(action, @case, 1, null, criteria, true));
            var validAction = Insert(new ValidAction("ABC", action, @case.Country, @case.Type, @case.PropertyType) { DisplaySequence = 0 });
            var validEvent = new ValidEventBuilder(DbContext).Create(criteria, importance: importanceLevel);

            criteria.ActionId = action.Code;
            var ce = Insert(new CaseEvent(@case.Id, validEvent.EventId, 1) { EventDueDate = Fixture.Today(), IsOccurredFlag = 0, FromCaseId = otherCase.Id, EmployeeNo = otherName.Id, IsDateDueSaved = 2 });

            var attachment = new Activity(NewActivityId(), Fixture.String(3), tableCode1, tableCode2, @case, name, name, name, name, name);
            attachment.Attachments.Add(new ActivityAttachment(attachment.Id, Fixture.Integer()) { FileName = @"c:\temp\attachment.pdf", AttachmentName = "attachment"});
            DbContext.Set<Activity>().Add(attachment);
            attachment.EventId = ce.EventNo;
            attachment.Cycle = ce.Cycle;

            var attachment2 = new Activity(NewActivityId(), Fixture.String(3), tableCode1, tableCode2, @case, name, name, name, name, name);
            attachment2.Attachments.Add(new ActivityAttachment(attachment2.Id, Fixture.Integer()) { FileName = @"c:\temp\attachment.pdf", AttachmentName = "attachment2"});
            DbContext.Set<Activity>().Add(attachment2);

            new CaseSearchResult {Case = @case, CaseId = @case.Id, PriorArtId = 1};
            var attachment3 = new Activity(NewActivityId(), Fixture.String(3), tableCode1, tableCode2, @case, name, name, name, name, name){PriorartId = 1};
            attachment3.Attachments.Add(new ActivityAttachment(attachment3.Id, Fixture.Integer()) { FileName = @"c:\temp\attachment.pdf", AttachmentName = "attachment3"});
            DbContext.Set<Activity>().Add(attachment3);

            var validNote = Insert(new EventText() { EventNoteType = new EventNoteType("test Type", false, false), EventNoteTypeId = null, Text = @"test event text", TextTId = 1 });
            Insert(new CaseEventText() { CaseId = @case.Id, Cycle = 1, EventId = validEvent.EventId, EventTextId = validNote.Id });
            var validNote2 = Insert(new EventText() { EventNoteType = null, EventNoteTypeId = null, Text = @"no type event text", TextTId = 2 });
            Insert(new CaseEventText() { CaseId = @case.Id, Cycle = 1, EventId = validEvent.EventId, EventTextId = validNote2.Id });
            var validEvent6 = new ValidEventBuilder(DbContext).Create(criteria, importance: importanceLevel);
            var ce6 = Insert(new CaseEvent(@case.Id, validEvent6.EventId, 2) { EventDueDate = Fixture.Today(), ReminderDate = null, IsOccurredFlag = 0 });

            var openActionObject = (validAction, new[] { ce, ce6 });

            var importanceLevelMax = Insert(new Importance("92", Fixture.Prefix(Fixture.String(3))));
            var action1 = InsertWithNewId(new Action(Fixture.Prefix("action"), importanceLevelMax));
            Insert(new OpenAction(action1, @case, 1, null, criteria1, true));
            var validAction1 = Insert(new ValidAction(null, action1, @case.Country, @case.Type, @case.PropertyType) { DisplaySequence = 1 });
            var validEvent1 = new ValidEventBuilder(DbContext).Create(criteria1, importance: importanceLevel, description: "event1");
            var dueDateCalc = Insert(new DueDateCalc(validEvent1, 1)
            {
                FromEventId = validEvent1.Event.Id,
                FromEvent = validEvent1.Event,
                RelativeCycle = 1,
                Operator = "A",
                DeadlinePeriod = Fixture.Short(),
                PeriodType = "D",
                Inherited = 0
            });
            validEvent1.DueDateCalcs.Add(dueDateCalc);
            var ce1 = Insert(new CaseEvent(@case.Id, validEvent1.EventId, 1) { EventDueDate = Fixture.Today(), IsOccurredFlag = 0, CreatedByCriteriaKey = criteria1.Id });
            var det = Insert(new DataEntryTask(criteria1, 0) { DisplaySequence = 0 });
            Insert(new AvailableEvent(det, ce1.Event)
            {
                DisplaySequence = 1,
                EventAttribute = (short)EntryAttribute.EntryOptional
            });

            var validEvent2 = new ValidEventBuilder(DbContext).Create(criteria1, importance: importanceLevelMax, description: "event2");
            var ce2 = Insert(new CaseEvent(@case.Id, validEvent2.EventId, 1) { EventDueDate = Fixture.Today(), IsOccurredFlag = 1 });

            var validEvent3 = new ValidEventBuilder(DbContext).Create(criteria1, importance: importanceLevel);
            var ce3 = Insert(new CaseEvent(@case.Id, validEvent3.EventId, 1) { EventDueDate = Fixture.Today(), ReminderDate = Fixture.Today(), IsOccurredFlag = 8 });

            var validEvent4 = new ValidEventBuilder(DbContext).Create(criteria1, importance: importanceLevelMax, description: "event4");
            var ce4 = Insert(new CaseEvent(@case.Id, validEvent4.EventId, 1) { EventDueDate = Fixture.Today(), ReminderDate = Fixture.Today(), IsOccurredFlag = 0, CreatedByCriteriaKey = criteria1.Id });

            var validEvent5 = new ValidEventBuilder(DbContext).Create(criteria1, importance: importanceLevelMax);
            var ce5 = Insert(new CaseEvent(@case.Id, validEvent5.EventId, 2) { EventDueDate = null, ReminderDate = null, IsOccurredFlag = 0 });

            if (withDateLogic)
            {
                ce3.EventDate = new DateTime(2019, 10, 1);
                ce4.EventDate = new DateTime(2019, 08, 08);
                ce5.EventDate = new DateTime(2019, 8, 09);
                DbContext.SaveChanges();
                Insert(new DatesLogic(validEvent1, 0) { DateTypeId = 1, Operator = "<", RelativeCycle = 3, CompareEvent = validEvent4.Event, CompareDateTypeId = 1, DisplayErrorFlag = 1, ErrorMessage = "error message error", Inherited = 0 });
                Insert(new DatesLogic(validEvent3, 1) { DateTypeId = 1, Operator = "<", RelativeCycle = 3, CompareEvent = validEvent4.Event, CompareDateTypeId = 1, DisplayErrorFlag = 0, ErrorMessage = "error message warning", Inherited = 0 });

            }

            var openActionObject2 = (validAction1, new[] { ce1, ce2, ce3, ce4, ce5 });
            var actionClosed = InsertWithNewId(new Action(Fixture.Prefix("action2"), importanceLevel));

            Insert(new OpenAction(actionClosed, @case, 0, null, criteriaClosed, false));
            var validActionClosed = Insert(new ValidAction(null, actionClosed, @case.Country, @case.Type, @case.PropertyType));
            var closedActionObject = (validActionClosed, new CaseEvent[0]);

            var actionPotential = InsertWithNewId(new Action(Fixture.Prefix("actionPotential"), importanceLevel));
            var validActionPotential = Insert(new ValidAction(null, actionPotential, @case.Country, @case.Type, @case.PropertyType));
            var potentialActionObject = (validActionPotential, new CaseEvent[1]);

            if (withRuleDetails)
            {
                SetupEventRulesData(validEvent, validEvent1, validEvent2);
            }

            return (@case.Id, @case.Irn, importanceLevelMax, openActionObject, openActionObject2, closedActionObject, potentialActionObject, criteria, validEvent, ce, @case);

            int NewActivityId()
            {
                var lastSequence = DbContext.Set<LastInternalCode>().SingleOrDefault(_ => _.TableName == KnownInternalCodeTable.Activity) ?? new LastInternalCode( KnownInternalCodeTable.Activity){InternalSequence = 0};
                lastSequence.InternalSequence++;
                DbContext.SaveChanges();

                return lastSequence.InternalSequence;
            }
        }

        void SetupEventRulesData(ValidEvent validEvent, ValidEvent validEvent1, ValidEvent validEvent2)
        {
            Insert(new DueDateCalc(validEvent, 0)
            {
                FromEventId = validEvent.Event.Id,
                FromEvent = validEvent.Event,
                RelativeCycle = 0,
                Operator = "A",
                DeadlinePeriod = Fixture.Short(),
                PeriodType = "D",
                Inherited = 0,
                Adjustment = "G",
                MustExist = 1,
                EventDateFlag = 2
            });

            Insert(new DueDateCalc(validEvent, 1)
            {
                FromEventId = validEvent.Event.Id,
                FromEvent = validEvent.Event,
                Comparison = "=",
                CompareEvent = validEvent1.Event,
                CompareEventId = validEvent1.EventId,
                CompareEventFlag = 1,
                CompareCycle = 1,
                CompareSystemDate = false,
                RelativeCycle = 1
            });
            Insert(new DueDateCalc(validEvent, 2)
            {
                FromEventId = validEvent.Event.Id,
                FromEvent = validEvent.Event,
                Comparison = ">=",
                CompareEvent = validEvent2.Event,
                CompareEventId = validEvent2.EventId,
                CompareEventFlag = 1,
                CompareCycle = 1,
                CompareSystemDate = true,
                RelativeCycle = 2
            });

            Insert(new RelatedEventRule(validEvent, 0)
            {
                RelatedEventId = validEvent1.EventId,
                RelativeCycleId = 1,
                SatisfyEvent = 1,
                IsInherited = true
            });
            Insert(new RelatedEventRule(validEvent, 1)
            {
                RelatedEventId = validEvent2.EventId,
                RelativeCycleId = 1,
                SatisfyEvent = 1
            });

            var instructionType = new InstructionTypeBuilder(DbContext).Create();
            var characteristic1 = new CharacteristicBuilder(DbContext).Create(instructionType.Code);
            var charge1 = new ChargeTypeBuilder(DbContext).Create();
            var charge2 = new ChargeTypeBuilder(DbContext).Create();
            var createAction = new ActionBuilder(DbContext).Create();
            var closeAction = new ActionBuilder(DbContext).Create();
            var status = new Status(Fixture.Short(), Fixture.String(10));

            validEvent.FlagNumber = characteristic1.Id;
            validEvent.InstructionType = instructionType.Code;
            validEvent.SaveDueDate = 1;
            validEvent.Notes = "Event Control Notes";
            validEvent.PayFeeCode = "1";
            validEvent.InitialFee = charge1;
            validEvent.PayFeeCode2 = "2";
            validEvent.InitialFee2 = charge2;
            validEvent.OpenAction = createAction;
            validEvent.CloseAction = closeAction;
            validEvent.UpdateEventImmediate = true;
            validEvent.ChangeStatus = status;
            validEvent.SetThirdPartyOn = 1;

            Insert(new ReminderRule(validEvent, 1)
            {
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 1,
                FreqPeriodType = "M",
                StopTime = 1,
                StopTimePeriodType = "Y",
                Inherited = 1,
                Message1 = "e2e - Reminder"
            });

            var doc = InsertWithNewId(new Document("reminder-letter", "rm-lt"));

            Insert(new ReminderRule
            {
                Sequence = Fixture.Short(),
                CriteriaId = validEvent.CriteriaId,
                EventId = validEvent.EventId,
                LetterNo = doc.Id,
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 1,
                FreqPeriodType = "M",
                StopTime = 1,
                StopTimePeriodType = "Y",
                Inherited = 1,
                Message1 = "e2e - Document"
            });

            var caseRelation = new CaseRelationBuilder(DbContext).Create("CaseRelationship");
            Insert(new DatesLogic(validEvent, 1)
            {
                DateTypeId = 1,
                Operator = ">",
                CompareEventId = validEvent1.EventId,
                CompareDateTypeId = 1,
                MustExist = 1,
                RelativeCycle = 3,
                CaseRelationshipId = caseRelation.Relationship,
                CaseRelationship = caseRelation,
                DisplayErrorFlag = 0,
                ErrorMessage = Fixture.String(10)
            });

            var adjustment = InsertWithNewId(new DateAdjustment { Description = Fixture.Prefix("Date Adjustment") });
            Insert(new RelatedEventRule(validEvent, 2)
            {
                RelatedEventId = validEvent1.EventId,
                RelativeCycleId = 1,
                UpdateEvent = 1,
                DateAdjustment = adjustment

            });
            Insert(new RelatedEventRule(validEvent, 3)
            {
                RelatedEventId = validEvent2.EventId,
                RelativeCycleId = 1,
                UpdateEvent = 1
            });

            Insert(new RelatedEventRule(validEvent, 4)
            {
                RelatedEventId = validEvent1.EventId,
                RelativeCycleId = 1,
                ClearDue = 1,
                ClearDueOnDueChange = true

            });
            Insert(new RelatedEventRule(validEvent, 5)
            {
                RelatedEventId = validEvent2.EventId,
                RelativeCycleId = 1,
                ClearEvent = 1,
                ClearEventOnDueChange = true
            });
        }

        public void EnsureEventLogDoesNotExist()
        {
            DbContext.Set<AuditLogTable>().Single(_ => _.Name == "CASEEVENT").IsLoggingRequired = false;
            DbContext.SaveChanges();
            if (!new SqlDbArtifacts(DbContext).Exists("CASEEVENT_iLOG", SysObjects.Table, SysObjects.View))
                return;
            if (new SqlDbArtifacts(DbContext).Exists("CASEEVENT_iLOGTempZ", SysObjects.Table, SysObjects.View))
            {
                const string scriptDeleteTempTable = "Drop table CASEEVENT_iLOGTempZ";
                DbContext.CreateSqlCommand(scriptDeleteTempTable).ExecuteNonQuery();
            }

            const string script = "EXEC sp_rename 'CASEEVENT_iLOG', 'CASEEVENT_iLOGTempZ'";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();
        }

        public bool RevertEventLog()
        {
            if (new SqlDbArtifacts(DbContext).Exists("CASEEVENT_iLOG", SysObjects.Table, SysObjects.View))
                return true;

            if (!new SqlDbArtifacts(DbContext).Exists("CASEEVENT_iLOGTempZ", SysObjects.Table, SysObjects.View))
                return false;

            const string script = "EXEC sp_rename 'CASEEVENT_iLOGTempZ', 'CASEEVENT_iLOG'";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();

            return true;
        }

        public void EnsureLogExists()
        {
            DbContext.Set<AuditLogTable>().Single(_ => _.Name == "CASEEVENT").IsLoggingRequired = true;
            DbContext.SaveChanges();
            if (RevertEventLog())
                return;

            const string script = "CREATE TABLE CASEEVENT_iLOG(LOGDATETIMESTAMP datetime, LOGACTION nchar (1), CREATEDBYE2E bit Default 1)";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();
        }

        public (int CaseId, Importance ImportanceLevel, Importance MaxImportanceLevel,
           (ValidAction Va, CaseEvent[] events) OpenActionWithMultipleEvents,
           EventText defaultNote, Criteria Criteria) ActionsSetupExternal(int userId)
        {
            var @case = new CaseBuilder(DbContext).CreateWithSummaryData().Case;
            var instructor = @case.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Instructor);
            var user = DbContext.Set<User>().Single(_ => _.Id == userId);
            Insert(new AccessAccountName { AccessAccountId = user.AccessAccount.Id, NameId = instructor.NameId });
            Insert(new CaseAccess(@case, user.AccessAccount.Id, KnownNameTypes.Instructor, instructor.NameId, instructor.Sequence));

            int criteriaId;
            new ScreenCriteriaBuilder(DbContext).Create(@case, out _, KnownCasePrograms.ClientAccess).WithTopicControl(KnownCaseScreenTopics.Actions);

            var criteria = new CriteriaBuilder(DbContext).Create();

            criteria.RuleInUse = 1;
            criteria.CaseTypeId = @case.TypeId;

            //var importanceLevelMin = Insert(new Importance("23", Fixture.Prefix(Fixture.String(3))));
            var importanceLevel = Insert(new Importance("91", Fixture.Prefix(Fixture.String(3))));
            var importanceLevelMax = Insert(new Importance("92", Fixture.Prefix(Fixture.String(3))));

            var action = InsertWithNewId(new Action(Fixture.Prefix("action"), importanceLevel));
            Insert(new OpenAction(action, @case, 1, null, criteria, true));
            var validAction = Insert(new ValidAction("ABC", action, @case.Country, @case.Type, @case.PropertyType) { DisplaySequence = 0 });

            var action1 = InsertWithNewId(new Action(Fixture.Prefix("action"), importanceLevelMax));
            Insert(new OpenAction(action1, @case, 1, null, criteria, true));
            Insert(new ValidAction("CDE", action1, @case.Country, @case.Type, @case.PropertyType) { DisplaySequence = 1 });

            var baseEvent = new EventBuilder(DbContext).Create(clientImportanceLevel: importanceLevel.Level);
            var validEvent = new ValidEventBuilder(DbContext).Create(criteria, baseEvent, importance: importanceLevel);
            var ce = Insert(new CaseEvent(@case.Id, validEvent.EventId, 1) { EventDueDate = DateTime.Now, IsOccurredFlag = 0 });

            var baseEvent1 = new EventBuilder(DbContext).Create(clientImportanceLevel: importanceLevelMax.Level);
            var validEvent1 = new ValidEventBuilder(DbContext).Create(criteria, baseEvent1, importance: importanceLevel, description: "event1");
            var ce1 = Insert(new CaseEvent(@case.Id, validEvent1.EventId, 1) { EventDate = new DateTime(2019, 12, 1), EventDueDate = DateTime.Now, IsOccurredFlag = 0 });

            var baseEvent2 = new EventBuilder(DbContext).Create(clientImportanceLevel: importanceLevel.Level);
            var validEvent2 = new ValidEventBuilder(DbContext).Create(criteria, baseEvent2, importance: importanceLevelMax);
            var ce2 = Insert(new CaseEvent(@case.Id, validEvent2.EventId, 1) { EventDueDate = Fixture.PastDate(), IsOccurredFlag = 0 });

            var validEvent3 = new ValidEventBuilder(DbContext).Create(criteria, importance: importanceLevel);
            var ce3 = Insert(new CaseEvent(@case.Id, validEvent3.EventId, 1) { EventDueDate = DateTime.Now, ReminderDate = Fixture.Today(), IsOccurredFlag = 8 });

            var validEvent4 = new ValidEventBuilder(DbContext).Create(criteria, importance: importanceLevelMax, description: "event4");
            var ce4 = Insert(new CaseEvent(@case.Id, validEvent4.EventId, 1) { EventDate = new DateTime(2019, 10, 10), EventDueDate = Fixture.Today(), ReminderDate = Fixture.Today(), IsOccurredFlag = 0 });

            var validEvent5 = new ValidEventBuilder(DbContext).Create(criteria, importance: importanceLevel);
            var ce5 = Insert(new CaseEvent(@case.Id, validEvent5.EventId, 2) { EventDueDate = null, ReminderDate = null, IsOccurredFlag = 0 });

            var openActionObject = (validAction, new[] { ce, ce1, ce2, ce3, ce4, ce5 });

            var internalNote = Insert(new EventText { EventNoteType = new EventNoteType("Internal Note Type", false, false), Text = @"Internal Note", TextTId = 1 });
            Insert(new CaseEventText { CaseId = @case.Id, Cycle = 1, EventId = validEvent.EventId, EventTextId = internalNote.Id });

            var defaultNote = Insert(new EventText { Text = @"Default Null Note" });
            Insert(new CaseEventText { CaseId = @case.Id, Cycle = 1, EventId = validEvent.EventId, EventTextId = defaultNote.Id });

            return (@case.Id, importanceLevel, importanceLevelMax, openActionObject, defaultNote, criteria);
        }

        public DateTime UpdateEventDate(int eventId, int caseId, DateTime date)
        {
            IsPoliceImmediately = true;
            var eEvent = DbContext.Set<ValidEvent>().SingleOrDefault(e => e.EventId == eventId);
            var caseEvent = DbContext.Set<CaseEvent>().Single(x => x.CaseId == 551 && x.EventNo == eEvent.EventId);
            caseEvent.EventDueDate = date;
            DbContext.SaveChanges();
            return caseEvent.EventDueDate.Value;
        }

        public CaseDetailsActionsDbSetup SetSiteControlForClientNote(bool clientEventTextValue)
        {
            var siteControl = DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.ClientEventText);
            siteControl.BooleanValue = clientEventTextValue;
            DbContext.SaveChanges();
            return this;
        }

        public CaseDetailsActionsDbSetup SetGlobalPreferenceForNoteType(int? noteTypeId)
        {
            var settingValue = DbContext.Set<SettingValues>().FirstOrDefault(sc => sc.SettingId == KnownSettingIds.DefaultEventNoteType && sc.User == null) ?? new SettingValues { SettingId = KnownSettingIds.DefaultEventNoteType };
            settingValue.IntegerValue = noteTypeId;
            DbContext.SaveChanges();
            return this;
        }

        public CaseDetailsActionsDbSetup SetSiteControlForDueDatesOverdueDays(int? value)
        {
            var siteControl = DbContext.Set<SiteControl>().Single(sc => sc.ControlId == SiteControls.ClientDueDates_OverdueDays);
            siteControl.IntegerValue = value;
            DbContext.SaveChanges();
            return this;
        }

        public void SetUserPreferenceForNoteType(string username, int? noteTypeId)
        {
            var user = DbContext.Set<User>().FirstOrDefault(u => u.UserName == username);
            var settingValue = DbContext.Set<SettingValues>().FirstOrDefault(sc => sc.SettingId == KnownSettingIds.DefaultEventNoteType && sc.User.UserName.Equals(username)) ?? new SettingValues { SettingId = KnownSettingIds.DefaultEventNoteType };
            settingValue.IntegerValue = noteTypeId;
            settingValue.User = user;
            DbContext.SaveChanges();
        }

        public EventText SetupNote(int caseId, int eventNo, bool isExternal)
        {
            var note = Insert(new EventText() { EventNoteType = new EventNoteType(Fixture.String(5), isExternal, false), Text = @Fixture.String(10) });
            Insert(new CaseEventText() { CaseId = caseId, Cycle = 1, EventId = eventNo, EventTextId = note.Id });
            return note;
        }
    }
}