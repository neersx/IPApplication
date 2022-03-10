using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerDetailsResolverFacts
    {
        static dynamic SetupData(InMemoryDbContext db, bool isReminderData = false)
        {
            var @case = new CaseBuilder().Build().In(db);
            var name = new NameBuilder(db).Build().In(db);
            var country = new Country("EP", Fixture.String("EP"), Fixture.String()).In(db);
            var criteria = new Criteria { Country = country }.In(db);
            var action1 = new ActionBuilder().Build().In(db);
            var event1 = new EventBuilder { Description = "event 1", ControllingAction = action1.Code }.Build().In(db);
            var office = new Office { Name = Fixture.String(), NameTId = Fixture.Integer() };
            @case.Office = office;
            var reminder = new StaffReminder(name.Id, Fixture.PastDate())
            {
                ReminderDate = DateTime.Today.AddDays(1),
                CaseId = @case.Id,
                Cycle = 1,
                EventId = event1.Id,
                ShortMessage = Fixture.String(),
                Source = isReminderData ? 0 : 1,
                ForwardedFrom = name.Id
            }.In(db);

            new ValidEventBuilder
            {
                Event = event1,
                Description = Fixture.String(),
                Criteria = criteria
            }.Build().In(db);
            new DueDateCalc(criteria.Id, Fixture.Integer(), (short)event1.Id) { Criteria = criteria, Cycle = null }.In(db);
            var caseEvent = new CaseEventBuilder
            {
                EventNo = event1.Id,
                Cycle = 1,
                DueDate = DateTime.Now,
                EventDate = DateTime.Now.AddDays(-2),
                IsOccurredFlag = 0,
                CaseId = @case.Id,
                EmployeeNo = name.Id
            }.Build().In(db);

            action1.ActionType = 0;
            var openAction = new OpenActionBuilder(db) { Action = action1, Criteria = criteria }.Build().In(db);
            openAction.Case = @case;

            return new { @case, reminder, event1, name, caseEvent, office };
        }

        static dynamic SetupDifferentRecipientRemindersData(InMemoryDbContext db, TaskPlannerDetailsResolverFixture fixture, bool isReminderData = false)
        {
            var @case = new CaseBuilder().Build().In(db);
            var name = new NameBuilder(db).Build().In(db);
            var name1 = new NameBuilder(db).Build().In(db);
            var name2 = new NameBuilder(db).Build().In(db);
            fixture.WithNameType(KnownNameTypes.StaffMember, out var nt1).WithCaseName(@case, nt1, name1);
            fixture.WithNameType(KnownNameTypes.Signatory, out var nt2).WithCaseName(@case, nt2, name2);
            var country = new Country("EP", Fixture.String("EP"), Fixture.String()).In(db);
            var criteria = new Criteria { Country = country }.In(db);
            var action1 = new ActionBuilder().Build().In(db);
            var event1 = new EventBuilder { Description = "event 1", ControllingAction = action1.Code }.Build().In(db);
            var office = new Office { Name = Fixture.String(), NameTId = Fixture.Integer() };
            @case.Office = office;
            new StaffReminder(name.Id, Fixture.PastDate())
            {
                ReminderDate = DateTime.Today.AddDays(1),
                CaseId = @case.Id,
                Cycle = 1,
                EventId = event1.Id,
                ShortMessage = Fixture.String(),
                Source = isReminderData ? 0 : 1,
                EmployeeReminderId = Fixture.Integer()
            }.In(db);

            var reminder1 = new StaffReminder(name1.Id, Fixture.PastDate())
            {
                ReminderDate = DateTime.Today.AddDays(1),
                CaseId = @case.Id,
                Cycle = 1,
                EventId = event1.Id,
                ShortMessage = Fixture.String(),
                Source = isReminderData ? 0 : 1,
                EmployeeReminderId = Fixture.Integer()
            }.In(db);

            var reminder2 = new StaffReminder(name2.Id, Fixture.PastDate())
            {
                ReminderDate = DateTime.Today.AddDays(1),
                CaseId = @case.Id,
                Cycle = 1,
                EventId = event1.Id,
                ShortMessage = Fixture.String(),
                Source = isReminderData ? 0 : 1,
                EmployeeReminderId = Fixture.Integer()
            }.In(db);

            new ValidEventBuilder
            {
                Event = event1,
                Description = Fixture.String(),
                Criteria = criteria
            }.Build().In(db);
            new DueDateCalc(criteria.Id, Fixture.Integer(), (short)event1.Id) { Criteria = criteria, Cycle = null }.In(db);
            var caseEvent = new CaseEventBuilder
            {
                EventNo = event1.Id,
                Cycle = 1,
                DueDate = DateTime.Now,
                EventDate = DateTime.Now.AddDays(-2),
                IsOccurredFlag = 0,
                CaseId = @case.Id,
                EmployeeNo = name.Id,
                Id = Fixture.Integer()
            }.Build().In(db);

            action1.ActionType = 0;
            var openAction = new OpenActionBuilder(db) { Action = action1, Criteria = criteria }.Build().In(db);
            openAction.Case = @case;

            return new { @case, reminder1, reminder2, event1, name, name1, name2, caseEvent, office };
        }

        public class TaskDetailsFacts : FactBase
        {
            dynamic CreateCaseNamesAlert(TaskPlannerDetailsResolverFixture fixture)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);
                fixture.WithNameType(KnownNameTypes.StaffMember, out var nt1).WithCaseName(@case, nt1, name1);
                fixture.WithNameType(KnownNameTypes.Signatory, out var nt2).WithCaseName(@case, nt2, name2);
                var cn1 = @case.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.StaffMember);
                var cn2 = @case.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Signatory);
                var a = new AlertRule { StaffId = name.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var a1 = new AlertRule { StaffId = name1.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var a2 = new AlertRule { StaffId = name2.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var reminder = new StaffReminder(name.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                var reminder1 = new StaffReminder(name1.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name1.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                var reminder2 = new StaffReminder(name2.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name2.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                var reminder3 = new StaffReminder(name.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name2.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);

                return new { @case.Id, name, name1, name2, reminder, reminder1, reminder2, reminder3, a, a1, a2, cn1, cn2 };
            }

            dynamic SetupDifferentRecipientData(TaskPlannerDetailsResolverFixture fixture)
            {
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);
                fixture.WithNameType(KnownNameTypes.StaffMember, out var nt1).WithCaseName(@case, nt1, name1);
                fixture.WithNameType(KnownNameTypes.Signatory, out var nt2).WithCaseName(@case, nt2, name2);

                var a1 = new AlertRule { StaffId = name.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var a2 = new AlertRule { StaffId = name1.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var a3 = new AlertRule { StaffId = name2.Id, CaseId = @case.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Id = Fixture.Integer() }.In(Db);
                var reminder = new StaffReminder(name.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name2.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                var reminder1 = new StaffReminder(name1.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name2.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                var reminder2 = new StaffReminder(name2.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    CaseId = @case.Id,
                    Cycle = 1,
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name2.Id,
                    EmployeeReminderId = Fixture.Integer()
                }.In(Db);
                return new { @case.Id, name, name1, name2, reminder, reminder1, reminder2, a1, a2, a3 };
            }

            [Fact]
            public async Task ShouldReturnAlertDetails()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = CreateCaseNamesAlert(f);
                var taskPlannerRowKey = "A" + "^" + data.a2.Id + "^" + data.reminder2.EmployeeReminderId;
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    },
                    {
                        data.name1.Id, new NameFormatted {Name = "Formatted, Name1"}
                    },
                    {
                        data.reminder2.StaffId, new NameFormatted {Name = "Formatted, Reminder1"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Alert, result.Type);
                Assert.Contains(formatted[data.name.Id].Name, result.OtherRecipients);
                Assert.Contains(formatted[data.reminder2.StaffId].Name, result.ReminderFor);
            }

            [Fact]
            public async Task ShouldReturnAlertForNames()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var alert = new AlertRule { StaffId = name.Id, AlertDate = DateTime.Now.Date, DateCreated = DateTime.Now.Date, SequenceNo = 1, Name = name, Id = Fixture.Integer() }.In(Db);
                var reminder = new StaffReminder(name.Id, Fixture.PastDate())
                {
                    ReminderDate = DateTime.Today.AddDays(1),
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name.Id,
                    Name = name
                }.In(Db);
                
                var taskPlannerRowKey = "A" + "^" + alert.Id + "^" + reminder.EmployeeReminderId;
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Alert, result.Type);
                Assert.Contains(formatted[name.Id].Name, result.ReminderFor);
            }

            [Fact]
            public async Task ShouldReturnDifferentRecipientsAndReminder()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupDifferentRecipientData(f);
                var taskPlannerRowKey = "A" + "^" + data.a3.Id + "^" + data.reminder2.EmployeeReminderId;
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    },
                    {
                        data.name1.Id, new NameFormatted {Name = "Formatted, Name1"}
                    },
                    {
                        data.reminder2.StaffId, new NameFormatted {Name = "Formatted, Reminder1"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);
                var otherRecipients = formatted[data.name.Id].Name + "; " + formatted[data.name1.Id].Name;
                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Alert, result.Type);
                Assert.Contains(otherRecipients, result.OtherRecipients);
                Assert.Contains(formatted[data.reminder2.StaffId].Name, result.ReminderFor);
            }

            [Fact]
            public async Task ShouldReturnDueDateResponsibility()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupData(Db);
                var taskPlannerRowKey = "C" + "^" + data.caseEvent.Id + "^" + data.reminder.EmployeeReminderId;
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(data.name.Id, result.DueDateResponsibilityId);
                Assert.Equal(formatted[data.name.Id].Name, result.DueDateResponsibility);
            }

            [Fact]
            public async Task ShouldReturnDelegationDetails()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupData(Db);
                var taskPlannerRowKey = "C" + "^" + data.caseEvent.Id + "^" + data.reminder.EmployeeReminderId;
                var formatted = "Formated, Name";
                f.DisplayFormattedName.For(Arg.Any<int>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Contains(data.office.Name, result.CaseOffice);
                Assert.Equal(data.name.Id, result.ReminderForId);
                Assert.Equal(formatted, result.ForwardedFrom);
            }

            [Fact]
            public async Task ShouldReturnMatchingDueDateData()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupData(Db);
                var taskPlannerRowKey = "C" + "^" + data.caseEvent.Id + "^" + data.reminder.EmployeeReminderId;
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Reminder, result.Type);
                Assert.Equal(data.reminder.ReminderDate, result.ReminderDate);
                Assert.Equal(data.reminder.ShortMessage, result.ReminderMessage);
                Assert.Equal(data.caseEvent.ReminderDate, result.NextReminderDate);
                Assert.Equal(data.name.Id, result.ReminderForId);
            }

            [Fact]
            public async Task ShouldReturnMatchingReminderData()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupData(Db);
                var taskPlannerRowKey = "C" + "^" + data.caseEvent.Id + "^" + data.reminder.EmployeeReminderId;

                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Reminder, result.Type);
                Assert.Equal(data.reminder.ReminderDate, result.ReminderDate);
                Assert.Equal(data.caseEvent.ReminderDate, result.NextReminderDate);
                Assert.Equal(data.reminder.ShortMessage, result.ReminderMessage);
            }

            [Fact]
            public async Task ShouldReturnDifferentRecipientsForReminder()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var data = SetupDifferentRecipientRemindersData(Db, f);
                var taskPlannerRowKey = "C" + "^" + data.caseEvent.Id + "^" + data.reminder1.EmployeeReminderId;
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        data.name.Id, new NameFormatted {Name = "Formatted, ABC"}
                    },
                    {
                        data.name1.Id, new NameFormatted {Name = "Formatted, Name1"}
                    },
                    {
                        data.reminder2.StaffId, new NameFormatted {Name = "Formatted, Reminder1"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.Resolve(taskPlannerRowKey);
                var otherRecipients = formatted[data.name.Id].Name + "; " + formatted[data.reminder2.StaffId].Name;
                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Reminder, result.Type);
                Assert.Equal(otherRecipients, result.OtherRecipients);
                Assert.Equal(data.caseEvent.ReminderDate, result.NextReminderDate);
            }

            [Fact]
            public async Task ShouldReturnAdhocDateForName()
            {
                var f = new TaskPlannerDetailsResolverFixture(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                var adhoc = new AlertRule { StaffId = name.Id, AlertDate = Fixture.Date(), DateCreated = Fixture.Date(), SequenceNo = 1, Name = name, Id = Fixture.Integer() }.In(Db);
                var adhocReminder = new StaffReminder(name.Id, Fixture.PastDate())
                {
                    ReminderDate = Fixture.Date().AddDays(1),
                    EventId = null,
                    ShortMessage = Fixture.String(),
                    Source = 1,
                    SequenceNo = 1,
                    AlertNameId = name.Id,
                    Name = name
                }.In(Db);

                var taskPlannerRowKey = "A" + "^" + adhoc.Id + "^" + adhocReminder.EmployeeReminderId;
                f.DisplayFormattedName.For(Arg.Any<int>()).Returns("George, Grey");
                var result = await f.Subject.Resolve(taskPlannerRowKey);

                Assert.NotNull(result);
                Assert.Equal(TaskPlannerRowTypeDesc.Alert, result.Type);
                Assert.Contains("George, Grey", result.AdhocResponsibleName);
            }
        }
    }

    public class TaskPlannerDetailsResolverFixture : IFixture<TaskPlannerDetailsResolver>
    {
        readonly string _culture = Fixture.String();
        readonly InMemoryDbContext _db;

        public TaskPlannerDetailsResolverFixture(InMemoryDbContext db)
        {
            _db = db;
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(_culture);
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
            Subject = new TaskPlannerDetailsResolver(preferredCultureResolver, db, DisplayFormattedName);
        }

        public IDisplayFormattedName DisplayFormattedName { get; }
        public TaskPlannerDetailsResolver Subject { get; }

        public TaskPlannerDetailsResolverFixture WithCaseName(InprotechKaizen.Model.Cases.Case @case, NameType nameType, InprotechKaizen.Model.Names.Name name = null, NameVariant nv = null, InprotechKaizen.Model.Names.Name attn = null, Address addr = null)
        {
            new CaseNameBuilder(_db)
            {
                Name = name ?? new NameBuilder(_db).Build().In(_db),
                NameType = nameType,
                NameVariant = nv,
                AttentionName = attn,
                Address = addr
            }.BuildWithCase(@case).In(_db);

            return this;
        }

        public TaskPlannerDetailsResolverFixture WithNameType(string nameTypeCode, out NameType nt, bool isAllowable = true)
        {
            nt = new NameTypeBuilder
            {
                NameTypeCode = nameTypeCode,
                PriorityOrder = (short)_db.Set<NameType>().Count()
            }
                 .Build()
                 .In(_db);

            if (isAllowable) new FilteredUserNameTypes { NameType = nt.NameTypeCode }.In(_db);

            return this;
        }
    }
}