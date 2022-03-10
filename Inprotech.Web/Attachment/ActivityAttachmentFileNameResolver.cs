using System;
using System.Linq;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Attachment
{
    public interface IActivityAttachmentFileNameResolver
    {
        string Resolve(int activityKey, int? sequenceKey);
    }

    internal class ActivityAttachmentFileNameResolver : IActivityAttachmentFileNameResolver
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ActivityAttachmentFileNameResolver(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public string Resolve(int activityKey, int? sequenceKey)
        {
            var userId = _securityContext.User.Id;
            var hasTopicSecurity = _dbContext.GetTopicSecurity(userId, "2", false, DateTime.Now).Any(x => x.IsAvailable);
            if (!hasTopicSecurity)
            {
                return null;
            }

            var activityAttachments = _dbContext.Set<ActivityAttachment>();
            var activities = _dbContext.Set<Activity>();
            var query = from aa in activityAttachments
                        join a in activities on aa.ActivityId equals a.Id
                        where aa.ActivityId == activityKey
                        select aa;
            if (sequenceKey.HasValue)
            {
                query = query.Where(_ => _.SequenceNo == sequenceKey);
            }
            else
            {
                query = from aa in query
                        join aa2 in activityAttachments on aa.ActivityId equals aa2.ActivityId
                        where aa.SequenceNo == activityAttachments.Where(_ => _.ActivityId == aa.ActivityId).Select(_ => _.SequenceNo).DefaultIfEmpty().Min()
                        select aa;
            }

            var isExternalUser = _securityContext.User.IsExternalUser;
            if (isExternalUser)
            {
                query = query.Where(_ => _.PublicFlag == 1);
            }

            return query.Select(_ => _.FileName).FirstOrDefault();
        }
    }
}