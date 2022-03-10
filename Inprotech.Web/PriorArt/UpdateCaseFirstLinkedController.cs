using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Modify)]
    public class UpdateCaseFirstLinkedController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _getDate;

        public UpdateCaseFirstLinkedController(IDbContext dbContext, Func<DateTime> getDate)
        {
            _dbContext = dbContext;
            _getDate = getDate;
        }

        [HttpPost]
        [Route("api/priorart/linkedCases/updateFirstLinkedCaseViewData")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.CaseKeys")]
        public async Task<dynamic> GetUpdateFirstLinkedCaseViewData(UpdateCasesFirstLinkedViewRequest args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));
            if (args.SourceDocumentId == null || !args.CaseKeys.Any()) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var caseToLink = _dbContext.Set<CaseSearchResult>()
                                       .Where(_ => _.PriorArtId == args.SourceDocumentId && args.CaseKeys.Contains(_.CaseId) && (!_.CaseFirstLinkedTo.HasValue || !_.CaseFirstLinkedTo.Value))
                                       .Select(_ => new
                                       {
                                           Id = _.CaseId,
                                           CaseReference = _.Case.Irn,
                                           Title = DbFuncs.GetTranslation(_.Case.Title, null, _.Case.TitleTId, null)
                                       }).FirstOrDefault();

            if (caseToLink == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var caseSearchResults = await _dbContext.Set<CaseSearchResult>()
                                                    .Where(_ => _.PriorArtId == args.SourceDocumentId)
                                                    .Select(_ => new
                                                    {
                                                        Id = _.CaseId,
                                                        CaseReference = _.Case.Irn,
                                                        Title = DbFuncs.GetTranslation(_.Case.Title, null, _.Case.TitleTId, null),
                                                        IsCaseFirstLinked = _.CaseFirstLinkedTo
                                                    }).ToArrayAsync();

            return new
            {
                CurrentlyLinkedCases = caseSearchResults.Where(_ => _.IsCaseFirstLinked.GetValueOrDefault()).GroupBy(_ => _.Id).Select(_ => new {_.First().Id, _.First().CaseReference, _.First().Title, _.First().IsCaseFirstLinked}),
                NewLinkedCases = caseToLink
            };
        }

        [HttpPost]
        [Route("api/priorart/linkedCases/updateFirstLinkedCase")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.CaseKeys")]
        public async Task UpdateFirstLinkedCases(UpdateCasesFirstLinkedViewRequest args)
        {
            if (args == null) throw new ArgumentNullException(nameof(args));
            if (args.SourceDocumentId == null || !args.CaseKeys.Any()) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (args.CaseKeys.Length > 1) throw new HttpException((int)HttpStatusCode.BadRequest, "Unable to accept multiple cases");

            var now = _getDate();
            var caseKeyToUpdate = args.CaseKeys.Single();

            var linkedCases = await _dbContext.Set<CaseSearchResult>().Where(_ => _.PriorArtId == args.SourceDocumentId).ToArrayAsync();
            foreach (var linkedCase in linkedCases)
            {
                if (linkedCase.CaseId == caseKeyToUpdate)
                {
                    linkedCase.CaseFirstLinkedTo = true;
                    linkedCase.UpdateDate = now;
                }
                else if (!args.KeepCurrent && linkedCase.CaseFirstLinkedTo.GetValueOrDefault())
                {
                    linkedCase.CaseFirstLinkedTo = false;   
                    linkedCase.UpdateDate = now;
                }
            }

            await _dbContext.SaveChangesAsync();
        }
    }

    public class UpdateCasesFirstLinkedViewRequest : SearchRequest
    {
        public int[] CaseKeys { get; set; }
        public bool KeepCurrent { get; set; }
    }
}