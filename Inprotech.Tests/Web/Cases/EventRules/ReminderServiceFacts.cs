using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class ReminderServiceFacts : FactBase
    {
        [Fact]
        public void ShouldReturnReminders()
        {
            var f = new RemindersServiceFixture();

            var reminderDetails = new List<ReminderDetails>
            {
                new ReminderDetails
                {
                    LeadTime = 3,
                    PeriodType = "W",
                    Frequency = 0,
                    NameType = string.Empty,
                    FreqPeriodType = null,
                    CriticalFlag = null,
                    EmployeeNameType = "Staff Member",
                    SignatoryNameType = "Signatory",
                    UseBeforeDueDate = false
                }
            };

            f.StaticTranslator.Translate(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns("Reminder Description");
            var r = f.Subject.GetReminders(reminderDetails).ToArray();

            var info = r.First();
            Assert.Equal(1, r.Length);
            Assert.Equal("Reminder Description", info.FormattedDescription);
            Assert.Equal( "Reminder Description", info.MessageInfo);
            Assert.Equal("Staff Member, Signatory", info.NameTypes);
            Assert.Equal("Reminder Description", info.FormattedDescription);
        }
    }

    public class RemindersServiceFixture : IFixture<RemindersService>
    {
        public IStaticTranslator StaticTranslator { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public IEventRulesHelper EventRulesHelper { get; }

        public RemindersServiceFixture()
        {
            StaticTranslator = Substitute.For<IStaticTranslator>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            EventRulesHelper = Substitute.For<IEventRulesHelper>();
            Subject = new RemindersService(PreferredCultureResolver, StaticTranslator, EventRulesHelper);
        }

        public RemindersService Subject { get; }
    }
}
