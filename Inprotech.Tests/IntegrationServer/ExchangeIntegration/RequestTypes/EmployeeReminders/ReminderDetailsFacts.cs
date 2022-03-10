using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Reminders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class ReminderDetailsFacts
    {
        public class ReminderDetailsClass : FactBase
        {
            [Fact]
            public void GetsCriticalLevelSiteControl()
            {
                var f = new ReminderDetailsFixture(Db);
                f.SiteControlReader.Received(1).Read<int>(SiteControls.CRITICALLEVEL);
            }
        }

        public class Retrieval : FactBase
        {
            [Fact]
            public void FormatsAllCurrentRemindersForTheStaff()
            {
                var today = DateTime.Today;

                var staffId = Fixture.Integer();
                var userId = Fixture.Integer();
                var r1 = new StaffReminder(staffId, Fixture.PastDate()) {ReminderDate = today.AddDays(1)}.In(Db);
                var r2 = new StaffReminder(staffId, Fixture.PastDate()) {ReminderDate = today}.In(Db);
                var r3 = new StaffReminder(staffId, Fixture.PastDate()) {ReminderDate = today.Subtract(new TimeSpan(1, 0, 0, 0))}.In(Db);

                var f = new ReminderDetailsFixture(Db);
                f.ReminderFormatter.Create(Arg.Any<StaffReminder>()).Returns(new ExchangeStaffReminder());
                f.ReminderFormatter.GetPriority(Arg.Any<StaffReminder>(), Arg.Any<int>()).Returns(false);
                f.UserFormatter.Users(Arg.Any<int>()).ReturnsForAnyArgs(new List<ExchangeUser> {new ExchangeUser {UserIdentityId = userId}});
                var result = f.Subject.ForUsers(staffId, userId, today);

                f.ReminderFormatter.Received(2).Create(Arg.Any<StaffReminder>());
                f.ReminderFormatter.Received(2).GetComments(Arg.Any<StaffReminder>());
                f.ReminderFormatter.Received(2).GetPriority(Arg.Any<StaffReminder>(), Arg.Any<int>());

                f.ReminderFormatter.Received(1).Create(r1);
                f.ReminderFormatter.Received(1).GetComments(r1);
                f.ReminderFormatter.Received(1).GetPriority(r1, Arg.Any<int>());

                f.ReminderFormatter.Received(1).Create(r2);
                f.ReminderFormatter.Received(1).GetComments(r2);
                f.ReminderFormatter.Received(1).GetPriority(r2, Arg.Any<int>());

                f.ReminderFormatter.DidNotReceive().Create(r3);
                f.ReminderFormatter.DidNotReceive().GetComments(r3);
                f.ReminderFormatter.DidNotReceive().GetPriority(r3, Arg.Any<int>());

                Assert.Equal(2, result.ReminderDetails.Count());
                Assert.True(result.Users.All(_ => _.UserIdentityId == userId));
            }

            [Fact]
            public void FormatsMatchingStaffReminder()
            {
                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate()).In(Db);

                var f = new ReminderDetailsFixture(Db);
                f.ReminderFormatter.Create(Arg.Any<StaffReminder>()).Returns(new ExchangeStaffReminder());
                f.ReminderFormatter.GetPriority(Arg.Any<StaffReminder>(), Arg.Any<int>()).Returns(false);
                f.UserFormatter.Users(Arg.Any<int>()).ReturnsForAnyArgs(new List<ExchangeUser>());
                f.Subject.For(r.StaffId, r.DateCreated);

                f.ReminderFormatter.Received(1).Create(r);
                f.ReminderFormatter.Received(1).GetComments(r);
                f.ReminderFormatter.Received(1).GetPriority(r, Arg.Any<int>());
            }

            [Fact]
            public void ReturnNullIfNoMatchingReminderFound()
            {
                var f = new ReminderDetailsFixture(Db);
                f.ReminderFormatter.Create(Arg.Any<StaffReminder>()).Returns(new ExchangeStaffReminder());
                f.ReminderFormatter.GetPriority(Arg.Any<StaffReminder>(), Arg.Any<int>()).Returns(false);
                f.UserFormatter.Users(Arg.Any<int>()).ReturnsForAnyArgs(new List<ExchangeUser>());
                var result = f.Subject.For(Fixture.Integer(), Fixture.PastDate());

                Assert.Null(result);
            }
        }

        public class ReminderDetailsFixture : IFixture<ReminderDetails>
        {
            public ReminderDetailsFixture(InMemoryDbContext db)
            {
                ValidEventResolver = Substitute.For<IValidEventResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                SiteControlReader.Read<int>(SiteControls.CRITICALLEVEL).Returns(Fixture.Integer());

                ReminderFormatter = Substitute.For<IReminderFormatter>();
                UserFormatter = Substitute.For<IUserFormatter>();

                Subject = new ReminderDetails(db, SiteControlReader, ReminderFormatter, UserFormatter);
            }

            public IValidEventResolver ValidEventResolver { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public IReminderFormatter ReminderFormatter { get; set; }
            public IUserFormatter UserFormatter { get; set; }
            public ReminderDetails Subject { get; set; }
        }
    }
}