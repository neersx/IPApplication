using System;
using System.Net;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Reminders;
using Xunit;
using NameBuilder = Inprotech.Tests.Web.Builders.Model.Names.NameBuilder;

namespace Inprotech.Tests.Web.Search.TaskPlanner.Reminders
{
    public class ReminderDetailsResolverFacts : FactBase
    {
        dynamic SetUpAdhocReminders(InMemoryDbContext db)
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var n1 = new NameBuilder(db)
            {
                FirstName = "George",
                LastName = "Grey",
                NameCode = "GG",
                UsedAs = 3
            }.Build().In(db);

            var n2 = new NameBuilder(db)
            {
                FirstName = "Colleen C",
                LastName = "Cork",
                NameCode = "CCC",
                UsedAs = 3
            }.Build().In(db);

            var today = DateTime.Today.ToUniversalTime();
            var dueDate = today.AddDays(5);
            var alert = new AlertRule(n1.Id, today)
            {
                Id = Fixture.Integer(),
                DueDate = dueDate,
                CaseId = c1.Id,
                StaffId = n1.Id,
                SequenceNo = 7
            }.In(Db);

            new AlertRule(n2.Id, today)
            {
                Id = Fixture.Integer(),
                DueDate = dueDate,
                CaseId = c1.Id,
                StaffId = n2.Id,
                SequenceNo = 7
            }.In(Db);

            var adhocReminder1 = new StaffReminder(n1.Id, today.AddSeconds(1).AddMilliseconds(100))
            {
                EmployeeReminderId = Fixture.Integer(),
                CaseId = c1.Id,
                Comments = "Comments from George Grey",
                DueDate = dueDate,
                ReminderDate = Fixture.TodayUtc().AddDays(1),
                ShortMessage = "adhoc reminder",
                Source = 1,
                SequenceNo = 7
            }.In(db);

            var adhocReminder2 = new StaffReminder(n2.Id, today.AddSeconds(1).AddMilliseconds(200))
            {
                EmployeeReminderId = Fixture.Integer(),
                CaseId = c1.Id,
                Comments = "Comments from Cork Colleen in response to George Grey",
                DueDate = dueDate,
                ReminderDate = Fixture.TodayUtc().AddDays(1),
                ShortMessage = "adhoc reminder",
                Source = 1,
                SequenceNo = 7
            }.In(db);

            var taskPlannerRowKey = "A^" + alert.Id + "^" + adhocReminder1.EmployeeReminderId;

            return new
            {
                c1,
                n1,
                n2,
                adhocReminder1,
                adhocReminder2,
                taskPlannerRowKey
            };
        }

        dynamic SetupSystemGeneratedReminders(InMemoryDbContext db)
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var e1 = new EventBuilder { Id = -1011785, Description = "Acceptance 18 month deadline" }.Build().In(db);
            var n1 = new NameBuilder(db)
            {
                FirstName = "George",
                LastName = "Grey",
                NameCode = "GG",
                UsedAs = 3
            }.Build().In(db);

            var n2 = new NameBuilder(db)
            {
                FirstName = "Colleen C",
                LastName = "Cork",
                NameCode = "CCC",
                UsedAs = 3
            }.Build().In(db);

            var today = DateTime.Today.ToUniversalTime();
            var dueDate = today.AddDays(5);

            var adhocReminder1 = new StaffReminder(n1.Id, today.AddSeconds(1).AddMilliseconds(100))
            {
                CaseId = c1.Id,
                Comments = "Comments from George Grey",
                DueDate = dueDate,
                ReminderDate = Fixture.TodayUtc().AddDays(1),
                ShortMessage = e1.Description,
                Cycle = 1,
                EventId = e1.Id,
                EmployeeReminderId = Fixture.Integer()
            }.In(db);

            var adhocReminder2 = new StaffReminder(n2.Id, today.AddSeconds(1).AddMilliseconds(200))
            {
                CaseId = c1.Id,
                Comments = "Comments from Cork Colleen in response to George Grey",
                DueDate = dueDate,
                ReminderDate = Fixture.TodayUtc().AddDays(1),
                ShortMessage = e1.Description,
                Cycle = 1,
                EventId = e1.Id,
                EmployeeReminderId = Fixture.Integer()
            }.In(db);

            var taskPlannerRowKey = "C^" + Fixture.Integer() + "^" + adhocReminder1.EmployeeReminderId;

            return new
            {
                c1,
                e1,
                adhocReminder1,
                adhocReminder2,
                taskPlannerRowKey
            };
        }

        [Fact]
        public void ShouldResolveAdhocReminderDetails()
        {
            var data = SetUpAdhocReminders(Db);
            var f = new ReminderDetailsResolverFixture(Db);

            var r = f.Subject.Resolve((string)data.taskPlannerRowKey);
            Assert.Equal(data.c1.Id, r.CaseId);
            Assert.Null(r.Cycle);
            Assert.Null(r.EventNo);
            Assert.Equal(data.adhocReminder1.StaffId, r.EmployeeKey);
            Assert.Equal(data.adhocReminder1.ShortMessage, r.ReminderMessage);
            Assert.Equal(data.adhocReminder1.DateCreated, r.ReminderDateCreated);
        }

        [Fact]
        public void ShouldReturnNotFoundHttpResponseExceptionForInvalidRowKey()
        {
            var f = new ReminderDetailsResolverFixture(Db);
            SetUpAdhocReminders(Db);

            var taskPlannerRowKey = "A^" + Fixture.Integer() + "^" + Fixture.Integer();
            var exception = Assert.Throws<HttpResponseException>(() => f.Subject.Resolve(taskPlannerRowKey));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public void ShouldReturnSystemGeneratedReminderDetails()
        {
            var f = new ReminderDetailsResolverFixture(Db);
            var data = SetupSystemGeneratedReminders(Db);

            var r = f.Subject.Resolve((string)data.taskPlannerRowKey);
            Assert.Equal(data.c1.Id, r.CaseId);
            Assert.Equal(1, r.Cycle.GetValueOrDefault());
            Assert.Equal(data.e1.Id, r.EventNo);
            Assert.Equal(data.adhocReminder1.StaffId, r.EmployeeKey);
            Assert.Equal(data.e1.Description, r.ReminderMessage);
            Assert.Equal(data.adhocReminder1.DateCreated, r.ReminderDateCreated);
        }

    }
    public class ReminderDetailsResolverFixture : IFixture<ReminderDetailsResolver>
    {
        public ReminderDetailsResolverFixture(InMemoryDbContext db)
        {
            Subject = new ReminderDetailsResolver(db);
        }

        public ReminderDetailsResolver Subject { get; }
    }
}