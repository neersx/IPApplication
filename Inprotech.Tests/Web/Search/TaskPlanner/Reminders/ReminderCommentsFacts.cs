using System;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.TaskPlanner.Reminders;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Reminders;
using NSubstitute;
using Xunit;
using NameBuilder = Inprotech.Tests.Web.Builders.Model.Names.NameBuilder;

namespace Inprotech.Tests.Web.Search.TaskPlanner.Reminders
{
    public class ReminderCommentsFacts : FactBase
    {
        dynamic SetupReminderDetails(InMemoryDbContext db)
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
            var adhocReminder1 = new StaffReminder(n1.Id, today.AddMilliseconds(100))
            {
                EmployeeReminderId = Fixture.Integer(),
                CaseId = c1.Id,
                Comments = "Comments from George Grey",
                DueDate = today.AddDays(3),
                ReminderDate = today.AddDays(1),
                ShortMessage = "adhoc reminder",
                Source = 1
            }.In(db);

            var adhocReminder2 = new StaffReminder(n2.Id, today.AddMilliseconds(150))
            {
                EmployeeReminderId = Fixture.Integer(),
                CaseId = c1.Id,
                Comments = "Comments from Cork Colleen in response to George Grey",
                DueDate = today.AddDays(3),
                ReminderDate = Fixture.TodayUtc().AddDays(1),
                ShortMessage = "adhoc reminder",
                Source = 1
            }.In(db);

            var taskPlannerRowKey = "A^" + n1.Id + "^" + today + "^" + Fixture.String() + "^" + n1.Id + adhocReminder1.EmployeeReminderId;

            return new
            {
                adhocReminder1,
                adhocReminder2,
                n1,
                n2,
                taskPlannerRowKey
            };
        }

        [Fact]
        public void ShouldReturnReminderComments()
        {
            var f = new ReminderCommentsFixture(Db);
            var data = SetupReminderDetails(Db);
            var reminderDetails = new ReminderDetails
            {
                EmployeeKey = data.adhocReminder1.StaffId,
                ReminderDateCreated = data.adhocReminder1.DateCreated,
                ReminderMessage = data.adhocReminder1.ShortMessage,
                EventNo = data.adhocReminder1.EventId,
                Cycle = data.adhocReminder1.Cycle,
                CaseId = data.adhocReminder1.CaseId,
                Reference = data.adhocReminder1.Reference
            };
            f.ReminderDetailsResolver.Resolve(Arg.Any<string>()).Returns(reminderDetails);

            var result = f.Subject.Get(Fixture.String());
            Assert.Equal(2, result.Comments.Count());
        }

        [Fact]
        public void ShouldReturnReminderCommentsInOrder()
        {
            var f = new ReminderCommentsFixture(Db);
            var data = SetupReminderDetails(Db);
            var reminderDetails = new ReminderDetails
            {
                EmployeeKey = data.adhocReminder1.StaffId,
                ReminderDateCreated = data.adhocReminder1.DateCreated,
                ReminderMessage = data.adhocReminder1.ShortMessage,
                EventNo = data.adhocReminder1.EventId,
                Cycle = data.adhocReminder1.Cycle,
                CaseId = data.adhocReminder1.CaseId,
                Reference = data.adhocReminder1.Reference
            };
            f.ReminderDetailsResolver.Resolve(Arg.Any<string>()).Returns(reminderDetails);
            f.DisplayFormattedName.For((int)data.n1.Id).Returns("George Grey");
            f.DisplayFormattedName.For((int)data.n2.Id).Returns("Colleen C Cork");

            var result = f.Subject.Get(Fixture.String());
            var reminderComments = result.Comments as ReminderComments[] ?? result.Comments.ToArray();
            Assert.Equal(data.adhocReminder1.Comments, reminderComments.First().Comments);
            Assert.Equal(data.adhocReminder2.Comments, reminderComments.Last().Comments);
            Assert.Equal(true, reminderComments.First().IsRecipientComment);
            Assert.Equal(false, reminderComments.Last().IsRecipientComment);
            Assert.Equal("George Grey", reminderComments.First().StaffDisplayName);
            Assert.Equal("Colleen C Cork", reminderComments.Last().StaffDisplayName);
        }

        [Fact]
        public void ShouldUpdateComments()
        {
            var f = new ReminderCommentsFixture(Db);
            var data = SetupReminderDetails(Db);
            var reminderDetails = new ReminderDetails
            {
                Id = data.adhocReminder1.EmployeeReminderId,
                EmployeeKey = data.adhocReminder1.StaffId,
                ReminderDateCreated = data.adhocReminder1.DateCreated,
                ReminderMessage = data.adhocReminder1.ShortMessage,
                EventNo = data.adhocReminder1.EventId,
                Cycle = data.adhocReminder1.Cycle,
                CaseId = data.adhocReminder1.CaseId,
                Reference = data.adhocReminder1.Reference
            };

            var rowKey = (string) data.taskPlannerRowKey;
            f.ReminderDetailsResolver.Resolve(rowKey).Returns(reminderDetails);

            var reminderSaveDetails = new ReminderCommentsSaveDetails
            {
                TaskPlannerRowKey = data.taskPlannerRowKey,
                Comments = "Comments updated from George Grey"
            };

            var updateResult = f.Subject.Update(reminderSaveDetails);

            Assert.Equal("success", updateResult.result);
            Assert.Equal("Comments updated from George Grey", Db.Set<StaffReminder>().Single(_ => _.EmployeeReminderId == reminderDetails.Id).Comments);
        }

        [Fact]
        public void ShouldThrowExceptionWhenReminderNotFound()
        {
            var f = new ReminderCommentsFixture(Db);
            var data = SetupReminderDetails(Db);
            var reminderDetails = new ReminderDetails
            {
                Id = Fixture.Integer(),
                EmployeeKey = Fixture.Integer(),
                ReminderDateCreated = data.adhocReminder1.DateCreated,
                ReminderMessage = data.adhocReminder1.ShortMessage,
                EventNo = data.adhocReminder1.EventId,
                Cycle = data.adhocReminder1.Cycle,
                CaseId = data.adhocReminder1.CaseId,
                Reference = data.adhocReminder1.Reference
            };
            f.ReminderDetailsResolver.Resolve(Arg.Any<string>()).Returns(reminderDetails);

            var reminderSaveDetails = new ReminderCommentsSaveDetails
            {
                TaskPlannerRowKey = data.taskPlannerRowKey,
                Comments = "Comments updated from George Grey"
            };
            
            var exception = Assert.Throws<HttpResponseException>(() => f.Subject.Update(reminderSaveDetails));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }
    }

    public class ReminderCommentsFixture : IFixture<ReminderCommentsService>
    {
        public ReminderCommentsFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            ReminderDetailsResolver = Substitute.For<IReminderDetailsResolver>();
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
            Subject = new ReminderCommentsService(db, PreferredCultureResolver, ReminderDetailsResolver, DisplayFormattedName);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IReminderDetailsResolver ReminderDetailsResolver { get; set; }
        public IDisplayFormattedName DisplayFormattedName { get; set; }
        public ReminderCommentsService Subject { get; }
    }
}