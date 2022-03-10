using System;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class ReminderFormatterFacts
    {
        public class CreateMethod : FactBase
        {
            [Theory]
            [InlineData("ABC", true)]
            [InlineData(null, false)]
            public void ReturnsCaseRefWhereAvailable(string irn, bool hasIrn)
            {
                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate());
                if (!string.IsNullOrWhiteSpace(irn))
                {
                    r.Case = new Case(irn, new Country(), new CaseType(), new PropertyType(), new CaseProperty());
                }

                var f = new ReminderFormatterFixture(Db);
                var n = f.Subject.Create(r);

                Assert.Equal(hasIrn, !string.IsNullOrWhiteSpace(n.CaseReference) && n.CaseReference == irn);
            }

            [Theory]
            [InlineData("longmessage", "shortmessage", "longmessage")]
            [InlineData("", "shortmessage", "shortmessage")]
            [InlineData(null, "shortmessage", "shortmessage")]
            public void ReturnsLongMessageWhereAvailable(string longmessage, string shortmessage, string expected)
            {
                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate())
                {
                    LongMessage = longmessage,
                    ShortMessage = shortmessage
                };
                var f = new ReminderFormatterFixture(Db);
                var n = f.Subject.Create(r);

                Assert.Equal(expected, n.Message);
            }

            [Fact]
            public void SetsBasicReminderProperties()
            {
                var staffId = Fixture.Integer();
                var dateCreated = DateTime.Now;
                var dueDate = Fixture.FutureDate().AddDays(5);
                var reference = Fixture.String();
                var reminderDate = Fixture.FutureDate();

                var r = new StaffReminder(staffId, dateCreated)
                {
                    DueDate = dueDate,
                    ReminderDate = reminderDate,
                    Reference = reference
                };

                var f = new ReminderFormatterFixture(Db);
                var n = f.Subject.Create(r);
                Assert.Equal(staffId, n.StaffId);
                Assert.Equal(dateCreated, n.DateCreated);
                Assert.Equal(dueDate, n.DueDate);
                Assert.Equal(reminderDate, n.ReminderDate);
                Assert.Equal(reference, n.AlertReference);
            }
        }

        public class GetCommentsMethod : FactBase
        {
            [Theory]
            [InlineData(true, "FSB")]
            [InlineData(false, "Reminder Comments: ABC")]
            public void AddsCaseInformationWhereAvailable(bool hasCase, string expectedStart)
            {
                var @case = new Case(Fixture.String(),
                                     new Country {CountryAdjective = "FSB"},
                                     new CaseType(Fixture.String("CaseType"), Fixture.String()),
                                     new PropertyType(Fixture.String(), Fixture.String()),
                                     new CaseProperty()).In(Db);

                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate())
                {
                    Comments = "ABC"
                };
                if (hasCase)
                {
                    r.Case = @case;
                }

                var f = new ReminderFormatterFixture(Db);
                var n = f.Subject.GetComments(r);

                Assert.StartsWith(expectedStart, n);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void AddsEventTextWhereAvailable(bool hasCaseEvent, bool hasEventText)
            {
                var eventText = Fixture.String("EventText_");
                var @case = new Case(Fixture.Integer(), Fixture.String(),
                                     new Country {CountryAdjective = "FSB"},
                                     new CaseType(),
                                     new PropertyType(Fixture.String(), Fixture.String()),
                                     new CaseProperty()).In(Db);

                var e = new Event(Fixture.Integer()).In(Db);
                var ce = new CaseEvent(@case.Id, e.Id, 1) {IsLongEventText = 1, EventLongText = eventText}.In(Db);
                @case.CaseEvents.Add(ce);

                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate())
                {
                    Comments = "ABC",
                    CaseId = @case.Id,
                    Case = @case,
                    EventId = hasCaseEvent ? e.Id : (int?) null,
                    Cycle = hasCaseEvent ? ce.Cycle : (short?) null
                };

                var f = new ReminderFormatterFixture(Db);
                var n = f.Subject.GetComments(r);

                Assert.Equal(hasEventText, n.IndexOf(eventText, StringComparison.Ordinal) > 0);
            }
        }

        public class GetPriority : FactBase
        {
            [Theory]
            [InlineData(3, 3, true)]
            [InlineData(3, 9, true)]
            [InlineData(3, 1, false)]
            [InlineData(null, 3, false)]
            public void ChecksAlertImportanceLevel(int? criticalLevel, int importanceLevel, bool expected)
            {
                var staffId = Fixture.Integer();
                var sequenceNo = Fixture.Integer();
                var reference = Fixture.String();
                new AlertRule(staffId, Fixture.PastDate()) {Importance = importanceLevel.ToString(), Reference = reference, SequenceNo = sequenceNo}.In(Db);

                var r = new StaffReminder(staffId, Fixture.PastDate())
                {
                    Reference = reference,
                    SequenceNo = sequenceNo
                };

                var f = new ReminderFormatterFixture(Db);
                var b = f.Subject.GetPriority(r, criticalLevel);
                Assert.Equal(expected, b);
            }

            [Theory]
            [InlineData(3, 3, true)]
            [InlineData(3, 9, true)]
            [InlineData(5, 1, false)]
            [InlineData(null, 3, false)]
            public void ChecksValidEventImportanceWhereAvailable(int? criticalLevel, int importanceLevel, bool expected)
            {
                var staffId = Fixture.Integer();
                var sequenceNo = Fixture.Integer();
                var reference = Fixture.String();
                var eventId = Fixture.Integer();
                new AlertRule(staffId, Fixture.PastDate()) {Importance = "5", Reference = reference, SequenceNo = sequenceNo}.In(Db);
                var @case = new Case(Fixture.Integer(), Fixture.String(),
                                     new Country {CountryAdjective = "FSB"},
                                     new CaseType(),
                                     new PropertyType(Fixture.String(), Fixture.String()),
                                     new CaseProperty()).In(Db);
                var e = new Event(eventId) {ImportanceLevel = "5"}.In(Db);
                var v = new ValidEvent(Fixture.Integer(), eventId) {ImportanceLevel = importanceLevel.ToString()}.In(Db);

                var r = new StaffReminder(staffId, Fixture.PastDate())
                {
                    Case = @case,
                    Event = e,
                    SequenceNo = sequenceNo
                };

                var f = new ReminderFormatterFixture(Db);
                f.ValidEventResolver.Resolve(Arg.Any<Case>(), Arg.Any<Event>()).Returns(v);

                var b = f.Subject.GetPriority(r, criticalLevel);
                Assert.Equal(expected, b);
            }

            [Fact]
            public void ReturnsFalseByDefault()
            {
                var r = new StaffReminder(Fixture.Integer(), Fixture.PastDate())
                {
                    Comments = "ABC"
                };
                var f = new ReminderFormatterFixture(Db);
                var b = f.Subject.GetPriority(r, null);
                Assert.False(b);
            }
        }

        public class ReminderFormatterFixture : IFixture<ReminderFormatter>
        {
            public ReminderFormatterFixture(InMemoryDbContext db)
            {
                ValidEventResolver = Substitute.For<IValidEventResolver>();
                Subject = new ReminderFormatter(db, ValidEventResolver);
            }

            public IValidEventResolver ValidEventResolver { get; set; }

            public ReminderFormatter Subject { get; set; }
        }
    }
}