using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
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
    public class ExchangeDeleteHandlerFacts
    {
        public class ProcessMethod : FactBase
        {
            [Fact]
            public async Task ChecksForValidUsers()
            {
                var staffId = Fixture.Integer();
                var request = new ExchangeRequest {StaffId = staffId};
                var users = new List<ExchangeUser>
                    {new ExchangeUser {Mailbox = Fixture.String()}, new ExchangeUser {Mailbox = Fixture.String()}};
                var f = new ExchangeDeleteHandlerFixture();
                f.UserFormatter.Users(Arg.Any<int>())
                 .Returns(users);
                await f.Subject.Process(request, new ExchangeConfigurationSettings());
                f.UserFormatter.Received(1).Users(staffId);
                f.IntegrationValidator.Received(1).ValidUsersForIntegration(request, users);
            }

            [Fact]
            public async Task DeletesForEachValidUser()
            {
                var staffId = Fixture.Integer();
                var dateKey = Fixture.PastDate();
                var request = new ExchangeRequest {StaffId = staffId, SequenceDate = dateKey};
                var settings = new ExchangeConfigurationSettings();
                var user1 = new ExchangeUser {Mailbox = Fixture.String()};
                var user2 = new ExchangeUser {Mailbox = Fixture.String()};
                var user3 = new ExchangeUser {Mailbox = Fixture.String()};
                var users = new List<ExchangeUser>
                    {user1, user2, user3};
                var validUsers = new List<ExchangeUser>
                    {user1, user3};
                var f = new ExchangeDeleteHandlerFixture();
                f.UserFormatter.Users(Arg.Any<int>())
                 .Returns(users);
                f.IntegrationValidator.ValidUsersForIntegration(Arg.Any<ExchangeRequest>(), users).Returns(validUsers);
                var r = await f.Subject.Process(request, settings);
                
                f.UserFormatter.Received(1).Users(staffId);
                f.IntegrationValidator.Received(1).ValidUsersForIntegration(request, users);
                f.ExchangeWebService.Received(2)
                 .DeleteAppointment(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(2)
                 .DeleteTask(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<string>(), Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .DeleteAppointment(settings, staffId, dateKey, user2.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.DidNotReceive()
                 .DeleteTask(settings, staffId, dateKey, user2.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .DeleteAppointment(settings, staffId, dateKey, user1.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .DeleteAppointment(settings, staffId, dateKey, user3.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .DeleteTask(settings, staffId, dateKey, user1.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                f.ExchangeWebService.Received(1)
                 .DeleteTask(settings, staffId, dateKey, user3.Mailbox, Arg.Any<int>())
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.True(r.Result == KnownStatuses.Success);
            }

            [Fact]
            public async Task RetrievesUsersForTheStaff()
            {
                var staffId = Fixture.Integer();
                var f = new ExchangeDeleteHandlerFixture();
                f.UserFormatter.Users(Arg.Any<int>()).Returns(new List<ExchangeUser>());

                await f.Subject.Process(new ExchangeRequest {StaffId = staffId}, new ExchangeConfigurationSettings());
                
                f.UserFormatter.Received(1).Users(staffId);
            }

            [Fact]
            public async Task ReturnsErrorMessage()
            {
                var staffId = Fixture.Integer();
                var error = Fixture.String("Error");
                var f = new ExchangeDeleteHandlerFixture();
                f.UserFormatter.Users(Arg.Any<int>()).Throws(new Exception(error));

                var r = await f.Subject.Process(new ExchangeRequest {StaffId = staffId}, new ExchangeConfigurationSettings());

                Assert.True(r.Result == KnownStatuses.Failed);
                Assert.Equal(error, r.ErrorMessage);
                f.Logger.Received(1).Exception(Arg.Any<Exception>());
            }
        }

        public class ExchangeDeleteHandlerFixture : IFixture<ExchangeDeleteHandler>
        {
            public ExchangeDeleteHandlerFixture()
            {
                ExchangeWebService = Substitute.For<IExchangeService>();
                Strategy = Substitute.For<IStrategy>();
                Strategy.GetService(Arg.Any<Guid>()).Returns(ExchangeWebService);

                UserFormatter = Substitute.For<IUserFormatter>();
                IntegrationValidator = Substitute.For<IIntegrationValidator>();
                Logger = Substitute.For<IBackgroundProcessLogger<IHandleExchangeMessage>>();
                Subject = new ExchangeDeleteHandler(Strategy, UserFormatter, IntegrationValidator, Logger);
            }

            public IStrategy Strategy { get; set; }

            public IExchangeService ExchangeWebService { get; set; }

            public IIntegrationValidator IntegrationValidator { get; set; }

            public IBackgroundProcessLogger<IHandleExchangeMessage> Logger { get; set; }

            public IUserFormatter UserFormatter { get; set; }

            public ExchangeDeleteHandler Subject { get; set; }
        }
    }
}