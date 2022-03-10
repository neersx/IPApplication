using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.ExchangeIntegration
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ExchangeIntegrationAdministration)]
    [RoutePrefix("api/exchange/requests")]
    public class ExchangeIntegrationController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IRequestQueueItemModel _model;
        readonly IPreferredCultureResolver _preferredCulture;

        public ExchangeIntegrationController(IDbContext dbContext, IRequestQueueItemModel model, IPreferredCultureResolver preferredCulture)
        {
            _dbContext = dbContext;
            _model = model;
            _preferredCulture = preferredCulture;
        }

        [HttpPost]
        [Route("view")]
        public PagedResults GetViewData(CommonQueryParameters queryParameters)
        {
            var preferredCulture = _preferredCulture.Resolve();

            var list = (from item in _dbContext.Set<ExchangeRequestQueueItem>()
                        join staffReminder in _dbContext.Set<StaffReminder>()
                            on new {item.StaffId, DateCreated = item.SequenceDate}
                            equals new {staffReminder.StaffId, staffReminder.DateCreated} into reminders
                        from reminder in reminders.DefaultIfEmpty()
                        select new
                        {
                            Item = item,
                            item.Case,
                            item.Name,
                            EventDescription = !item.EventId.HasValue ? null : DbFuncs.GetTranslation(item.Event.Description, null, item.Event.DescriptionTId, preferredCulture)
                        })
                       .OrderBy(_ => _.Item.Id)
                       .ToArray();

            var identityIds = list.Where(x => (ExchangeRequestType) x.Item.RequestTypeId == ExchangeRequestType.SaveDraftEmail && x.Item.IdentityId.HasValue).Select(x => x.Item.IdentityId.Value).Distinct().ToArray();
            var staffIds = list.Where(x => (ExchangeRequestType) x.Item.RequestTypeId == ExchangeRequestType.SaveDraftEmail).Select(x => x.Item.StaffId).Distinct().ToArray();

            var mailboxes = (from setting in _dbContext.Set<SettingValues>()
                             where setting.SettingId == KnownSettingIds.ExchangeMailbox && (identityIds.Contains(setting.User.Id) || staffIds.Contains(setting.User.NameId) && setting.CharacterValue != null)
                             select new MailboxItem {IdentityId = setting.User.Id, StaffId = setting.User.NameId, Mailbox = setting.CharacterValue}).ToList();

            return list.Select(_ => _model.Get(_.Item, _.EventDescription, GetStaffMemberMailbox(mailboxes, _.Item))).AsPagedResults(queryParameters);
        }

        string GetStaffMemberMailbox(List<MailboxItem> mailboxes, ExchangeRequestQueueItem item)
        {
            if ((ExchangeRequestType) item.RequestTypeId == ExchangeRequestType.SaveDraftEmail)
            {
                return item.MailBox;
            }

            var list = from mail in mailboxes
                       where item.IdentityId.HasValue && mail.IdentityId == item.IdentityId.Value || mail.StaffId == item.StaffId
                       select mail.Mailbox;

            return string.Join("; ", list);
        }

        [HttpPost]
        [Route("reset")]
        public dynamic ResetExchangeRequests(IEnumerable<long> exchangeIds)
        {
            var updated = 0;
            var toUpdate = _dbContext.Set<ExchangeRequestQueueItem>()
                                     .Where(v => exchangeIds.Contains(v.Id) && v.StatusId == (short) ExchangeRequestStatus.Failed)
                                     .ToArray();
            foreach (var item in toUpdate)
            {
                item.StatusId = (short) ExchangeRequestStatus.Ready;
                item.ErrorMessage = null;
                _dbContext.SaveChanges();
                updated++;
            }

            return new
            {
                Result = new
                {
                    Status = "success",
                    Updated = updated
                }
            };
        }

        [HttpPost]
        [Route("reset/{userid}")]
        public async Task<dynamic> ResetExchangeRequests(int userId)
        {
            var user = _dbContext.Set<User>().SingleOrDefault(_ => _.Id == userId);

            if (user == null) return null;

            var updated = await _dbContext.UpdateAsync(_dbContext.Set<ExchangeRequestQueueItem>()
                                                                 .Where(v => v.NameId == user.NameId && v.IdentityId == user.Id
                                                                                                     && v.StatusId == (short) ExchangeRequestStatus.Failed),
                                                       _ => new ExchangeRequestQueueItem
                                                       {
                                                           StatusId = (short) ExchangeRequestStatus.Ready,
                                                           ErrorMessage = null
                                                       });

            return new
            {
                Result = new
                {
                    Status = "success",
                    Updated = updated
                }
            };
        }

        [HttpPost]
        [Route("delete")]
        public dynamic DeleteExchangeRequests(IEnumerable<long> exchangeIds)
        {
            var deletedItems = _dbContext.Set<ExchangeRequestQueueItem>().Where(v => exchangeIds.Contains(v.Id) && v.StatusId != (int) ExchangeRequestStatus.Processing).ToList();
            deletedItems.ForEach(v => _dbContext.Set<ExchangeRequestQueueItem>().Remove(v));
            _dbContext.SaveChanges();

            return new
            {
                Result = new
                {
                    Status = "success"
                }
            };
        }
    }

    public class RequestQueueItem
    {
        public long Id { get; set; }
        public string Staff { get; set; }
        public string Reference { get; set; }
        public DateTime RequestDate { get; set; }
        public string Status { get; set; }
        public string TypeOfRequest { get; set; }
        public string FailedMessage { get; set; }
        public short StatusId { get; set; }
        public short RequestTypeId { get; set; }
        public int? EventId { get; set; }
        public string EventDescription { get; set; }
        public string Mailbox { get; set; }
        public string RecipientEmail { get; set; }
    }

    public class MailboxItem
    {
        public int IdentityId { get; set; }
        public int StaffId { get; set; }
        public string Mailbox { get; set; }
    }
}