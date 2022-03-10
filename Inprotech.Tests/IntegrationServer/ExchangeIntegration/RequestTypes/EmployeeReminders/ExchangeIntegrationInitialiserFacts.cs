using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Integration.Exchange;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class ExchangeIntegrationInitialiserFacts
    {
        public class ExchangeIntegrationInitialiserFixture : IFixture<ExchangeIntegrationInitialiser>
        {
            public ExchangeIntegrationInitialiserFixture()
            {
                ExchangeWebService = Substitute.For<IExchangeService>();
                Strategy = Substitute.For<IStrategy>();
                Strategy.GetService(Arg.Any<Guid>()).Returns(ExchangeWebService);

                ReminderDetails = Substitute.For<IReminderDetails>();
                Logger = Substitute.For<IBackgroundProcessLogger<IHandleExchangeMessage>>();
                Subject = new ExchangeIntegrationInitialiser(Strategy, ReminderDetails, PreferenceManager, Logger);
            }

            public IBackgroundProcessLogger<IHandleExchangeMessage> Logger { get; set; }

            public IStrategy Strategy { get; set; }

            public IExchangeService ExchangeWebService { get; set; }
            
            public IReminderDetails ReminderDetails { get; set; }
            
            public IUserPreferenceManager PreferenceManager { get; set; }
            
            public ExchangeIntegrationInitialiser Subject { get; set; }
        }

        public class ProcessMethod : FactBase
        {
            [Fact]
            public async Task CreatesAppointmentAndTask()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var userIdentity = Fixture.Integer();
                var exchangeUser = new ExchangeUser {IsUserInitialised = true, Mailbox = Fixture.String()};
                var f = new ExchangeIntegrationInitialiserFixture();
                f.ReminderDetails.ForUsers(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser> {exchangeUser}, new List<ExchangeStaffReminder> {new ExchangeStaffReminder()}));
                var request = new ExchangeRequest {StaffId = staffId, SequenceDate = sequenceDate, UserId = userIdentity, RequestType = ExchangeRequestType.Initialise};
                var exchangeSettings = new ExchangeConfigurationSettings();
                
                await f.Subject.Process(request, exchangeSettings);

                f.ExchangeWebService.Received(1)
                 .CreateOrUpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .CreateOrUpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task RetrievesUsersAndReminders()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var userIdentity = Fixture.Integer();
                var exchangeUser = new ExchangeUser {IsUserInitialised = true, Mailbox = Fixture.String()};
                var f = new ExchangeIntegrationInitialiserFixture();
                f.ReminderDetails.ForUsers(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser> {exchangeUser}, new List<ExchangeStaffReminder> {new ExchangeStaffReminder()}));
                var request = new ExchangeRequest {StaffId = staffId, SequenceDate = sequenceDate, UserId = userIdentity};
                var exchangeSettings = new ExchangeConfigurationSettings();

                await f.Subject.Process(request, exchangeSettings);
                f.ReminderDetails.Received(1).ForUsers(staffId, userIdentity, sequenceDate);
            }

            [Fact]
            public async Task ThrowsExceptionWhenNoMatchingReminders()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var userIdentity = Fixture.Integer();
                var exchangeUser = new ExchangeUser {IsUserInitialised = true, Mailbox = Fixture.String()};
                var f = new ExchangeIntegrationInitialiserFixture();
                f.ReminderDetails.ForUsers(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser> {exchangeUser}, new List<ExchangeStaffReminder>()));
                var request = new ExchangeRequest {StaffId = staffId, SequenceDate = sequenceDate, UserId = userIdentity};
                var exchangeSettings = new ExchangeConfigurationSettings();
                var r = await f.Subject.Process(request, exchangeSettings);

                Assert.False(r.Result == KnownStatuses.Failed);
                Assert.False(string.IsNullOrEmpty(r.ErrorMessage));
                
                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsExceptionWhenNoValidUsers()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var userIdentity = Fixture.Integer();
                var f = new ExchangeIntegrationInitialiserFixture();
                f.ReminderDetails.ForUsers(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser>(), new List<ExchangeStaffReminder> {new ExchangeStaffReminder()}));
                var request = new ExchangeRequest {StaffId = staffId, SequenceDate = sequenceDate, UserId = userIdentity};
                var exchangeSettings = new ExchangeConfigurationSettings();
                var r = await f.Subject.Process(request, exchangeSettings);

                Assert.False(r.Result == KnownStatuses.Obsolete);
                Assert.False(string.IsNullOrEmpty(r.ErrorMessage));

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task LogsUnhandledExceptions()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var userIdentity = Fixture.Integer();
                var error = new Exception(Fixture.String("Error"));

                var f = new ExchangeIntegrationInitialiserFixture();
                f.ReminderDetails.ForUsers(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>()).Throws(error);
                var request = new ExchangeRequest { StaffId = staffId, SequenceDate = sequenceDate, UserId = userIdentity };
                var exchangeSettings = new ExchangeConfigurationSettings();
                var r = await f.Subject.Process(request, exchangeSettings);

                Assert.False(r.Result == KnownStatuses.Obsolete);
                Assert.False(string.IsNullOrEmpty(r.ErrorMessage));
                f.Logger.Received(1).Exception(error);

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}