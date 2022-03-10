using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.IntegrationServer.Properties;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public interface IIntegrationValidator
    {
        IEnumerable<ExchangeUser> ValidUsersForIntegration(ExchangeRequest exchangeRequest, IEnumerable<ExchangeUser> users);
        void RequestInitialiseUsers(int staffId, IEnumerable<ExchangeUser> notInitialisedUsers, DateTime requestSequenceDate);
    }

    public class IntegrationValidator : IIntegrationValidator
    {
        readonly IDbContext _dbContext;
        public IntegrationValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ExchangeUser> ValidUsersForIntegration(ExchangeRequest exchangeRequest, IEnumerable<ExchangeUser> users)
        {
            var exchangeUsers = users as ExchangeUser[] ?? users.ToArray();
            if (!exchangeUsers.Any())
                throw new Exception(ExchangeResources.ValidateUserAdditionalInfo);

            if (exchangeUsers.All(v => string.IsNullOrEmpty(v.Mailbox)))
                throw new Exception(string.Format(ExchangeResources.ValidateUsersNoMailBox, String.Join(",", exchangeUsers.Select(v => v.UserIdentityId.ToString()))));
          
            var notInitialisedUsers = exchangeUsers.Where(u => !u.IsUserInitialised && !string.IsNullOrEmpty(u.Mailbox)).ToArray();
            if (notInitialisedUsers.Any())
                RequestInitialiseUsers(exchangeRequest.StaffId, notInitialisedUsers, exchangeRequest.SequenceDate);

            return exchangeUsers.Where(u => u.IsUserInitialised && !string.IsNullOrEmpty(u.Mailbox));
        }

        public void RequestInitialiseUsers(int staffId, IEnumerable<ExchangeUser> notInitialisedUsers, DateTime requestSequenceDate)
        {
            foreach (var user in notInitialisedUsers)
            {
                if (!_dbContext.Set<ExchangeRequestQueueItem>().Any(q => q.StaffId == staffId && q.IdentityId == user.UserIdentityId))
                {
                    _dbContext.Set<ExchangeRequestQueueItem>()
                              .Add(new ExchangeRequestQueueItem(staffId, requestSequenceDate, DateTime.Now, (short)ExchangeRequestType.Initialise, (short)ExchangeRequestStatus.Ready)
                              {
                                  IdentityId = user.UserIdentityId
                              });
                    _dbContext.SaveChanges();
                }
            }
        }
    }
}