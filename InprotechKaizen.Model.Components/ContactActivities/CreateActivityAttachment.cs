using System;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.ContactActivities
{
    public interface ICreateActivityAttachment
    {
        Task<Activity> Exec(
            int userIdentityId,
            int? caseId,
            int? nameId,
            int activityTypeId,
            int activityCategoryId,
            DateTime? activityDateTime = null,
            string summary = null,
            string attachmentName = null,
            string fileName = null,
            string attachmentDescription = null,
            bool isPublic = false,
            int? attachmentTypeId = null,
            int? priorArtId = null,
            int? eventId = null,
            short? cycle = null,
            int? languageId = null,
            int? pageCount = null);
    }

    public class CreateActivityAttachment : ICreateActivityAttachment
    {
        readonly IDbContext _dbContext;
        
        public CreateActivityAttachment(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<Activity> Exec(
            int userIdentityId,
            int? caseId,
            int? nameId,
            int activityTypeId,
            int activityCategoryId,
            DateTime? activityDateTime = null,
            string summary = null,
            string attachmentName = null,
            string fileName = null,
            string attachmentDescription = null,
            bool isPublic = false,
            int? attachmentTypeId = null,
            int? priorArtId = null,
            int? eventId = null,
            short? cycle = null,
            int? languageId = null,
            int? pageCount = null)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand(StoredProcedures.InsertActivityAttachment);

            var activityKeyParam = new SqlParameter("@pnActivityKey", SqlDbType.Int)
                                   {
                                       Direction = ParameterDirection.Output
                                   };
            var sequenceKeyParam = new SqlParameter("@pnSequenceKey", SqlDbType.Int)
                                   {
                                       Direction = ParameterDirection.Output
                                   };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               activityKeyParam,
                                               sequenceKeyParam,
                                               new SqlParameter("@pnUserIdentityId", userIdentityId),
                                               new SqlParameter("@pnCaseKey", caseId),
                                               new SqlParameter("@pnNameKey", nameId),
                                               new SqlParameter("@pnPriorArtKey", priorArtId),
                                               new SqlParameter("@pnEventKey", eventId),
                                               new SqlParameter("@pnEventCycle", cycle),
                                               new SqlParameter("@pnActivityTypeKey", activityTypeId),
                                               new SqlParameter("@pnActivityCategoryKey", activityCategoryId),
                                               new SqlParameter("@pdtActivityDate", activityDateTime),
                                               new SqlParameter("@psActivitySummary", summary),
                                               new SqlParameter("@psAttachmentName", attachmentName),
                                               new SqlParameter("@psFileName", fileName),
                                               new SqlParameter("@psAttachmentDescription", attachmentDescription),
                                               new SqlParameter("@pbIsPublic", isPublic),
                                               new SqlParameter("@pnAttachmentTypeKey", attachmentTypeId),
                                               new SqlParameter("@pnLanguageKey", languageId),
                                               new SqlParameter("@pnPageCount", pageCount)
                                           });

            await sqlCommand.ExecuteNonQueryAsync();

            var activityKey = (int)activityKeyParam.Value;

            return await _dbContext.Set<Activity>().SingleAsync(a => a.Id == activityKey);
        }
    }
}