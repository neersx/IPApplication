using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public interface IExchangeIntegrationQueue
    {
        Task QueueDraftEmailRequest(DraftEmailProperties draftEmailProperties, int documentQueueId);
        Task QueueDraftEmailRequest(DraftEmailProperties draftEmailProperties, int? caseId, (int staffId, int userID) user);
    }

    public class ExchangeIntegrationQueue : IExchangeIntegrationQueue
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IFileHelpers _fileHelpers;

        public ExchangeIntegrationQueue(IDbContext dbContext, Func<DateTime> now, IFileHelpers fileHelpers)
        {
            _dbContext = dbContext;
            _now = now;
            _fileHelpers = fileHelpers;
        }

        public async Task QueueDraftEmailRequest(DraftEmailProperties draftEmailProperties, int documentQueueId)
        {
            if (draftEmailProperties == null) throw new ArgumentNullException(nameof(draftEmailProperties));

            var origin = await (from ar in _dbContext.Set<CaseActivityRequest>()
                                join i in _dbContext.Set<User>() on ar.IdentityId equals i.Id into i1
                                from i in i1.DefaultIfEmpty()
                                join v in _dbContext.Set<ClassicUser>() on ar.SqlUser equals v.Id into v1
                                from v in v1.DefaultIfEmpty()
                                where ar.Id == documentQueueId
                                select new
                                {
                                    ar.CaseId,
                                    IdentityId = ar.IdentityId ?? v.UserIdentity.Id,
                                    ar.WhenRequested,
                                    NameId = ar.IdentityId != null ? i.NameId : v.UserIdentity.NameId,
                                    ar.FileName
                                }).SingleAsync();

            var toEnqueue = new ExchangeRequestQueueItem
            {
                RequestTypeId = (int)ExchangeRequestType.SaveDraftEmail,
                StatusId = (int)ExchangeRequestStatus.Ready,
                DateCreated = _now(),
                StaffId = origin.NameId,
                SequenceDate = origin.WhenRequested,
                IdentityId = origin.IdentityId,
                CaseId = origin.CaseId,
                MailBox = draftEmailProperties.Mailbox,
                Recipients = string.Join(";", draftEmailProperties.Recipients),
                Body = draftEmailProperties.Body,
                Subject = draftEmailProperties.Subject,
                IsBodyHtml = draftEmailProperties.IsBodyHtml
            };

            if (draftEmailProperties.CcRecipients.Any())
            {
                toEnqueue.CcRecipients = string.Join(";", draftEmailProperties.CcRecipients);
            }

            if (draftEmailProperties.BccRecipients.Any())
            {
                toEnqueue.BccRecipients = string.Join(";", draftEmailProperties.BccRecipients);
            }

            if (draftEmailProperties.Attachments.Any())
            {
                toEnqueue.Attachments = JsonConvert.SerializeObject(draftEmailProperties.Attachments);
            }

            _dbContext.Set<ExchangeRequestQueueItem>().Add(toEnqueue);

            if (!string.IsNullOrWhiteSpace(origin.FileName) && _fileHelpers.Exists(origin.FileName))
            {
                _fileHelpers.DeleteFile(origin.FileName);
            }
        }

        public async Task QueueDraftEmailRequest(DraftEmailProperties draftEmailProperties, int? caseId, (int staffId, int userID) user)
        {
            if (draftEmailProperties == null) throw new ArgumentNullException(nameof(draftEmailProperties));

            var toEnqueue = new ExchangeRequestQueueItem(user.staffId, _now(), _now(), (int)ExchangeRequestType.SaveDraftEmail, (int)ExchangeRequestStatus.Ready)
            {
                IdentityId = user.userID,
                MailBox = draftEmailProperties.Mailbox,
                Recipients = string.Join(";", draftEmailProperties.Recipients),
                Body = draftEmailProperties.Body,
                Subject = draftEmailProperties.Subject,
                IsBodyHtml = draftEmailProperties.IsBodyHtml,
                CaseId = caseId
            };

            if (draftEmailProperties.CcRecipients.Any())
            {
                toEnqueue.CcRecipients = string.Join(";", draftEmailProperties.CcRecipients);
            }

            if (draftEmailProperties.BccRecipients.Any())
            {
                toEnqueue.BccRecipients = string.Join(";", draftEmailProperties.BccRecipients);
            }

            if (draftEmailProperties.Attachments.Any())
            {
                toEnqueue.Attachments = JsonConvert.SerializeObject(draftEmailProperties.Attachments);
            }

            _dbContext.Set<ExchangeRequestQueueItem>()
                      .Add(toEnqueue);
        }
    }
}
