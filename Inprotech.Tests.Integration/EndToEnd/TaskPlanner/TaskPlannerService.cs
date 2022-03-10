using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    internal static class TaskPlannerService
    {
        internal static TaskPlannerData SetupData(bool createCase = true, bool createOtherStaffCase = false)
        {
            TestUser user = null;
            Name staff = null, otherStaff = null;
            CaseBuilder.SummaryData[] data = null;

            DbSetup.Do(x =>
            {
                var profile = x.DbContext.Set<Profile>().Single(_ => _.Name == "Proffessional");
                SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal);
                staff = new NameBuilder(x.DbContext).CreateStaff(email: "staff@org.com");
                otherStaff = new NameBuilder(x.DbContext).CreateStaff(prefix: "e2eOtherStaff", email: "otherStaff@org.com");
                user = new Users(x.DbContext) { Name = staff, Profile = profile }.WithPermission(ApplicationTask.MaintainTaskPlannerApplication)
                                                                                .WithPermission(ApplicationTask.MaintainReminder)
                                                                                .WithPermission(ApplicationTask.ProvideDueDateInstructions)
                                                                                .WithPermission(ApplicationTask.ChangeDueDateResponsibility)
                                                                                .WithPermission(ApplicationTask.MaintainTaskPlannerSearchColumns, Allow.Modify).Create();
                if (createCase)
                {
                    var summaryData1 = new CaseBuilder(x.DbContext).CreateWithSummaryDataWithoutRenewalDetails("TaskPlanner1", staffModel: staff);
                    var summaryData2 = new CaseBuilder(x.DbContext).CreateWithSummaryDataWithoutRenewalDetails("TaskPlanner2", staffModel: staff);
                    var summaryData3 = new CaseBuilder(x.DbContext).CreateWithSummaryDataWithoutRenewalDetails("TaskPlanner3", staffModel: staff);

                    data = createOtherStaffCase ? new[] { summaryData1, summaryData2, summaryData3, new CaseBuilder(x.DbContext).CreateWithSummaryDataWithoutRenewalDetails("TaskPlanner4", staffModel: otherStaff) }
                        : new[] { summaryData1, summaryData2, summaryData3 };

                }

                x.DbContext.SaveChanges();
            });

            return new TaskPlannerData
            {
                User = user,
                Staff = staff,
                OtherStaff = otherStaff,
                Data = data
            };
        }
        internal static void InsertAdHocDate(int caseId, DateTime dueDate, TestUser user, string messagePrefix = "E2E Test Message ", int? nameId = null)
        {
            DbSetup.Do(db =>
            {
                using (var dbCommand = db.DbContext.CreateStoredProcedureCommand("dbo.ipw_InsertAdHocDate"))
                {
                    dbCommand.Parameters.AddWithValue("pnUserIdentityId", user?.Id);
                    dbCommand.Parameters.AddWithValue("psCulture", "en-GB");
                    dbCommand.Parameters.AddWithValue("pnNameKey", nameId ?? user?.NameId);
                    dbCommand.Parameters.AddWithValue("pnCaseKey", caseId);
                    dbCommand.Parameters.AddWithValue("psAdHocMessage", messagePrefix + Fixture.AlphaNumericString(30));
                    dbCommand.Parameters.AddWithValue("pdtDueDate", dueDate);
                    dbCommand.Parameters.AddWithValue("pnPolicingBatchNo", 2);
                    dbCommand.Parameters.AddWithValue("pbIsElectronicReminder", 0);
                    dbCommand.Parameters.AddWithValue("pnRepeatIntervalDays", 1);
                    dbCommand.Parameters.AddWithValue("pnDaysLead", 10);
                    dbCommand.Parameters.AddWithValue("pbIsEmployee", 1);
                    dbCommand.Parameters.AddWithValue("pbIsSignatory", 0);
                    dbCommand.Parameters.AddWithValue("pbIsCriticalList", 0);
                    dbCommand.ExecuteNonQuery();
                }

                using (var dbCommand = db.DbContext.CreateStoredProcedureCommand("dbo.ipu_Policing"))
                {
                    dbCommand.Parameters.AddWithValue("pnUserIdentityId", user?.Id);
                    dbCommand.Parameters.AddWithValue("pnBatchNo", 2);
                    dbCommand.ExecuteNonQuery();
                }
            });
        }

        internal static void InsertAdHocDateWithComments(int caseId, DateTime dueDate, TestUser user, String comments)
        {
            InsertAdHocDate(caseId, dueDate, user);

            DbSetup.Do(db =>
            {
                var reminder = db.DbContext.Set<StaffReminder>().First(_ => _.StaffId == user.NameId && _.CaseId == caseId);
                reminder.Comments = comments;
                db.DbContext.SaveChanges();
            });
        }

        internal static Case InsertDueDateReminder(DateTime dueDate)
        {
            return DbSetup.Do(setup =>
             {
                 SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal);

                 var casePrefix = Fixture.AlphaNumericString(15);
                 var property = setup.InsertWithNewId(new PropertyType
                 {
                     Name = RandomString.Next(5)
                 }, x => x.Code);
                 var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                 var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                 var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                 var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                 var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                 setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                 setup.Insert(new CaseEvent(@case1.Id, (int)KnownEvents.NextRenewalDate, 1) { EventDueDate = dueDate, IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id });
                 return @case1;
             });
        }

        internal static InstructionData InsertInstruction()
        {
            const int defaultTradeMarkLodgementCriteria = -1071;
            const int cycle = 1;
            Case @case = null;
            var taskPlannerData = SetupData(false);
            var user = taskPlannerData.User;
            Event dueEvent = null;
            Event fileEvent;
            Event doNotFileEvent;
            InstructionDefinition definition = null;
            InstructionResponse fileResponse = null;
            InstructionResponse doNotFileResponse = null;
            DbSetup.Do(x =>
            {
                x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PoliceImmediately).BooleanValue = true;
                var propertyType = x.DbContext.Set<PropertyType>().Single(_ => _.Code == "T");
                var filing = x.DbContext.Set<Action>().Single(_ => _.Code == "AL");

                var criteria = x.DbContext.Set<Criteria>().First(_ => _.Id == defaultTradeMarkLodgementCriteria);
                fileEvent = new EventBuilder(x.DbContext).Create();
                doNotFileEvent = new EventBuilder(x.DbContext).Create();
                dueEvent = new EventBuilder(x.DbContext).Create();
                new ValidEventBuilder(x.DbContext).Create(criteria, dueEvent, Fixture.String(10));

                definition = x.DbContext.Set<InstructionDefinition>().Add(new InstructionDefinition(Fixture.String(25), false, 0)
                {
                    DueEventNo = dueEvent.Id,
                    Explanation = Fixture.String(25),
                    AvailabilityFlag = 1 * 4
                });
                x.DbContext.SaveChanges();

                fileResponse = x.DbContext.Set<InstructionResponse>().Add(new InstructionResponse(definition.Id, 1, Fixture.String(25), fileEvent.Id)
                {
                    Explanation = Fixture.String(25)
                });

                doNotFileResponse = x.DbContext.Set<InstructionResponse>().Add(new InstructionResponse(definition.Id, 2, Fixture.String(25), doNotFileEvent.Id)
                {
                    Explanation = Fixture.String(25)
                });

                @case = new CaseBuilder(x.DbContext).Create("TaskPlanner_" + Fixture.Integer(), true, propertyType: propertyType);
                x.Insert(new OpenAction(filing, @case, 1, null, criteria, true));
                x.Insert(new CaseEvent(@case.Id, dueEvent.Id, cycle) { EventDueDate = DateTime.Today.AddDays(5), IsOccurredFlag = 0, CreatedByCriteriaKey = criteria.Id });
            });

            return new InstructionData
            {
                User = user,
                Cycle = cycle,
                DueEvent = dueEvent,
                Definition = definition,
                DoNotFileResponse = doNotFileResponse,
                FileResponse = fileResponse,
                Case = @case
            };
        }

        internal class TaskPlannerData
        {
            public Name Staff { get; set; }

            public Name OtherStaff { get; set; }
            public TestUser User { get; set; }
            public CaseBuilder.SummaryData[] Data { get; set; }
        }

        internal class InstructionData
        {
            public InstructionDefinition Definition { get; set; }
            public InstructionResponse FileResponse { get; set; }
            public InstructionResponse DoNotFileResponse { get; set; }
            public Event DueEvent { get; set; }
            public TestUser User { get; set; }
            public int Cycle { get; set; }
            public Case Case { get; set; }
        }
    }
}
