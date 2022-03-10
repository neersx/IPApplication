using System;
using System.Linq;
using Inprotech.IntegrationServer.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class IntegrationValidatorFacts
    {
        public class RequestInitialiseUsersMethod : FactBase
        {
            [Fact]
            public void AddExchangeRequestUsersNotInitialised()
            {
                ExchangeUser[] notInitialisedUsers =
                {
                    new ExchangeUser {UserIdentityId = 1, IsUserInitialised = false},
                    new ExchangeUser {UserIdentityId = 2, IsUserInitialised = false}
                };

                var s = new IntegrationValidator(Db);

                s.RequestInitialiseUsers(Fixture.Integer(), notInitialisedUsers, Fixture.PastDate());
                var exchangeRequestQueueItems = Db.Set<ExchangeRequestQueueItem>().Where(v => v.RequestTypeId == (int) ExchangeRequestType.Initialise);

                Assert.Equal(2, exchangeRequestQueueItems.Count());
            }
        }

        public class ValidUsersForIntegrationMethod : FactBase
        {
            [Fact]
            public void MakesAnExchangeRequestForEachUserNotInitialised()
            {
                ExchangeUser[] userListOneNotInitialised =
                {
                    new ExchangeUser {UserIdentityId = 1, IsUserInitialised = false, Mailbox = "steph.curry@warriors.com"},
                    new ExchangeUser {UserIdentityId = 2, IsUserInitialised = false, Mailbox = "klay.thompson@warriors.com"},
                    new ExchangeUser {UserIdentityId = 3, IsUserInitialised = true, Mailbox = "rudy.gobert@warriors.com"}
                };

                var request = new ExchangeRequest();
                var s = new IntegrationValidator(Db);

                var result = s.ValidUsersForIntegration(request, userListOneNotInitialised);
                var requestedInitialiseRows = Db.Set<ExchangeRequestQueueItem>().Where(v => v.RequestTypeId == (int) ExchangeRequestType.Initialise);

                Assert.Equal(2, requestedInitialiseRows.Count());
                Assert.Single(result);
            }

            [Fact]
            public void ThrowWhenAllUsersDontHaveMailbox()
            {
                ExchangeUser[] noMailboxUsers =
                {
                    new ExchangeUser {UserIdentityId = 1, IsUserInitialised = true},
                    new ExchangeUser {UserIdentityId = 2, IsUserInitialised = true}
                };

                var request = new ExchangeRequest();
                var s = new IntegrationValidator(Db);

                Assert.Throws<Exception>(() => s.ValidUsersForIntegration(request, noMailboxUsers));
            }

            [Fact]
            public void ThrowWhenNoUsersFound()
            {
                ExchangeUser[] emptyUserList = { };
                var request = new ExchangeRequest();
                var s = new IntegrationValidator(Db);

                Assert.Throws<Exception>(() => s.ValidUsersForIntegration(request, emptyUserList));
            }
        }
    }
}