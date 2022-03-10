using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
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
    public class EmployeeReminderIntegratorFacts
    {
        public class ProcessMethod : FactBase
        {
            [Fact]
            public async Task CreatesAppointmentAndTask()
            {
                var request = new ExchangeRequest { StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), RequestType = ExchangeRequestType.Add, Id = Fixture.Integer() };
                var exchangeUser = new ExchangeUser { IsUserInitialised = true, Mailbox = Fixture.String() };
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser>
                                                                                                                               {
                                                                                                                                   exchangeUser
                                                                                                                               },
                                                                                                                               new List<ExchangeStaffReminder>
                                                                                                                               {
                                                                                                                                   new ExchangeStaffReminder()
                                                                                                                               })
                         );
                f.IntegrationValidator.ValidUsersForIntegration(Arg.Any<ExchangeRequest>(), Arg.Any<IEnumerable<ExchangeUser>>())
                 .Returns(new List<ExchangeUser>
                 {
                     exchangeUser
                 });

                await f.Subject.Process(request,
                                  new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

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
                var exchangeUser = new ExchangeUser { IsUserInitialised = true, Mailbox = Fixture.String() };
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(
                                                                                                                               new List<ExchangeUser>
                                                                                                                               {
                                                                                                                                   exchangeUser
                                                                                                                               },
                                                                                                                               new List<ExchangeStaffReminder>
                                                                                                                               {
                                                                                                                                   new ExchangeStaffReminder()
                                                                                                                               }));
                f.IntegrationValidator.ValidUsersForIntegration(Arg.Any<ExchangeRequest>(), Arg.Any<IEnumerable<ExchangeUser>>())
                 .Returns(new List<ExchangeUser>
                 {
                     exchangeUser
                 });

                await f.Subject.Process(new ExchangeRequest { StaffId = staffId, SequenceDate = sequenceDate },
                                  new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

                f.ReminderDetails.Received(1).For(staffId, sequenceDate);
            }

            [Fact]
            public async Task ThrowsExceptionWhenNoMatchingReminders()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>()).Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser>(), new List<ExchangeStaffReminder>()));

                var r = await f.Subject.Process(
                                          new ExchangeRequest { StaffId = staffId, SequenceDate = sequenceDate },
                                          new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

                Assert.False(r.Result == KnownStatuses.Failed);
                Assert.False(string.IsNullOrEmpty(r.ErrorMessage));

                f.Logger.DidNotReceive().Exception(Arg.Any<Exception>());
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
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>()).Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser>(), new List<ExchangeStaffReminder> { new ExchangeStaffReminder() }));
                var r = await f.Subject.Process(new ExchangeRequest { StaffId = staffId, SequenceDate = sequenceDate },
                                          new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

                Assert.False(r.Result == KnownStatuses.Obsolete);
                Assert.False(string.IsNullOrEmpty(r.ErrorMessage));

                f.Logger.DidNotReceive().Exception(Arg.Any<Exception>());
                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .CreateOrUpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task UpdatesAppointmentAndTask()
            {
                var request = new ExchangeRequest { StaffId = Fixture.Integer(), SequenceDate = Fixture.PastDate(), RequestType = ExchangeRequestType.Update, Id = Fixture.Integer() };
                var exchangeUser = new ExchangeUser { IsUserInitialised = true, Mailbox = Fixture.String() };
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>())
                 .Returns(new Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders.EmployeeReminders(new List<ExchangeUser>
                                                                                                                               {
                                                                                                                                   exchangeUser
                                                                                                                               },
                                                                                                                               new List<ExchangeStaffReminder>
                                                                                                                               {
                                                                                                                                   new ExchangeStaffReminder()
                                                                                                                               })
                         );
                f.IntegrationValidator.ValidUsersForIntegration(Arg.Any<ExchangeRequest>(), Arg.Any<IEnumerable<ExchangeUser>>())
                 .Returns(new List<ExchangeUser>
                 {
                     exchangeUser
                 });

                await f.Subject.Process(request, new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

                f.ExchangeWebService.Received(1)
                 .UpdateAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .UpdateTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task LogsUnhandledExceptions()
            {
                var staffId = Fixture.Integer();
                var sequenceDate = Fixture.PastDate();
                var error = new Exception(Fixture.String("Error"));
                var f = new EmployeeReminderIntegratorFixture();
                f.ReminderDetails.For(Arg.Any<int>(), Arg.Any<DateTime>()).Throws(error);
                var r = await f.Subject.Process(new ExchangeRequest { StaffId = staffId, SequenceDate = sequenceDate },
                                          new ExchangeConfigurationSettings { Server = Fixture.String("https://") });

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

        public class EmployeeReminderIntegratorFixture : IFixture<EmployeeReminderIntegrator>
        {
            public EmployeeReminderIntegratorFixture()
            {
                ExchangeWebService = Substitute.For<IExchangeService>();
                Strategy = Substitute.For<IStrategy>();
                Strategy.GetService(Arg.Any<Guid>()).Returns(ExchangeWebService);

                ReminderDetails = Substitute.For<IReminderDetails>();
                IntegrationValidator = Substitute.For<IIntegrationValidator>();
                ExchangeIntegrationSettings = Substitute.For<IExchangeIntegrationSettings>();
                Logger = Substitute.For<IBackgroundProcessLogger<IHandleExchangeMessage>>();
                Subject = new EmployeeReminderIntegrator(Strategy, ReminderDetails, IntegrationValidator, Logger);
            }

            public IStrategy Strategy { get; set; }
            public IExchangeService ExchangeWebService { get; set; }
            public IReminderDetails ReminderDetails { get; set; }
            public IExchangeIntegrationSettings ExchangeIntegrationSettings { get; set; }
            public IBackgroundProcessLogger<IHandleExchangeMessage> Logger { get; set; }
            public IIntegrationValidator IntegrationValidator { get; set; }
            public EmployeeReminderIntegrator Subject { get; set; }
        }
    }
}