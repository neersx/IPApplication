using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Attachment
{
    public interface IActivityAttachmentAccessResolver
    {
        Task<bool> CheckAccessForExternalUser(int activityId, int sequence);
    }

    public class ActivityAttachmentAccessResolver : IActivityAttachmentAccessResolver
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ICaseAuthorization _caseAuthorization;
        readonly INameAuthorization _nameAuthorization;
        public ActivityAttachmentAccessResolver(IDbContext dbContext, ISecurityContext securityContext, ICaseAuthorization caseAuthorization, INameAuthorization nameAuthorization)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _caseAuthorization = caseAuthorization;
            _nameAuthorization = nameAuthorization;
        }

        public async Task<bool> CheckAccessForExternalUser(int activityId, int sequence)
        {
            if (!_securityContext.User.IsExternalUser)
                return true;

            var attachment = _dbContext.Set<ActivityAttachment>()
                                       .SingleOrDefault(a => a.ActivityId == activityId && a.SequenceNo == sequence && a.PublicFlag == 1);
            if (attachment == null)
                return false;

            var activity = _dbContext.Set<Activity>()
                                     .Single(a => a.Id == activityId);
            if (activity.CaseId != null)
                return !(await _caseAuthorization.Authorize(activity.CaseId.Value, AccessPermissionLevel.Select)).IsUnauthorized;

            return activity.ContactNameId == null || !(await _nameAuthorization.Authorize(activity.ContactNameId.Value, AccessPermissionLevel.Select)).IsUnauthorized;
        }
    }
}
