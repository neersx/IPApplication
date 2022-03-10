using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class LinkedCasesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IComponentResolver _componentResolver;

        public LinkedCasesController(IDbContext dbContext, ISiteConfiguration siteConfiguration, ITransactionRecordal transactionRecordal, IComponentResolver componentResolver)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _transactionRecordal = transactionRecordal;
            _componentResolver = componentResolver;
        }
        
        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/linkedCases/create")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.CaseKey")]
        [RequiresNameAuthorization(AccessPermissionLevel.Update, PropertyPath = "args.NameKey")]
        public async Task<dynamic> CreateAssociation(AssociateReferenceRequest args)
        {
            if (!args.CaseKey.HasValue && string.IsNullOrWhiteSpace(args.CaseFamilyKey) && !args.CaseListKey.HasValue && !args.NameKey.HasValue)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            using var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);
            var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
            if (args.CaseKey.HasValue)
            {
                var @case = _dbContext.Set<Case>().Single(v => v.Id == args.CaseKey.Value);
                _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.PriorArt));
            }

            var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Where(v => v.Id == args.SourceDocumentId);
            var caseSearchResults = _dbContext.Set<CaseSearchResult>().Where(_ => _.CaseId == args.CaseKey.Value && _.PriorArtId == args.SourceDocumentId);
            var nameResults = _dbContext.Set<NameSearchResult>().Where(_ => _.NameId == args.NameKey.Value && _.PriorArtId == args.SourceDocumentId);
            var caseListResults = _dbContext.Set<CaseListSearchResult>().Where(_ => _.CaseListId == args.CaseListKey && _.PriorArtId == args.SourceDocumentId);
            var caseFamilyResults = _dbContext.Set<FamilySearchResult>().Where(_ => _.FamilyId == args.CaseFamilyKey && _.PriorArtId == args.SourceDocumentId);
            var linkedCasesExist = (from s in priorArt
                                   join c in caseSearchResults on s.Id equals c.PriorArtId into c1
                                   from c in c1.DefaultIfEmpty()
                                   join f in caseFamilyResults on s.Id equals f.PriorArtId into f1
                                   from f in f1.DefaultIfEmpty()
                                   join cl in caseListResults on s.Id equals cl.PriorArtId into cl1
                                   from cl in cl1.DefaultIfEmpty()
                                   join nl in nameResults on s.Id equals nl.PriorArtId into nl1
                                   from nl in nl1.DefaultIfEmpty()
                                    select new
                                    {
                                       IsCaseExisting = c1.Any(),
                                       IsFamilyExisting = f1.Any(),
                                       IsCaseListExisting = cl1.Any(),
                                       IsNameExisting = nl1.Any()
                                    })
                                   .Distinct()
                                   .SingleOrDefault();

            if (linkedCasesExist != null && (linkedCasesExist.IsCaseExisting || linkedCasesExist.IsFamilyExisting || linkedCasesExist.IsCaseListExisting || linkedCasesExist.IsNameExisting))
            {
                return new
                {
                    IsSuccessful = false,
                    linkedCasesExist.IsFamilyExisting,
                    CaseReferenceExists = linkedCasesExist.IsCaseExisting,
                    linkedCasesExist.IsCaseListExisting,
                    linkedCasesExist.IsNameExisting
                };
            }

            if (args.CaseKey.HasValue)
            {
                _dbContext.Set<CaseSearchResult>()
                          .Add(new CaseSearchResult(args.CaseKey.GetValueOrDefault(),
                                                    args.SourceDocumentId,
                                                    false));
            }

            if (!string.IsNullOrWhiteSpace(args.CaseFamilyKey))
            {
                _dbContext.Set<FamilySearchResult>()
                          .Add(new FamilySearchResult
                          {
                              FamilyId = args.CaseFamilyKey,
                              PriorArtId = args.SourceDocumentId
                          });
            }

            if (args.CaseListKey.HasValue)
            {
                _dbContext.Set<CaseListSearchResult>()
                       .Add(new CaseListSearchResult
                       {
                           CaseListId = args.CaseListKey.Value,
                           PriorArtId = args.SourceDocumentId
                       });
            }

            if (args.NameKey.HasValue)
            {
                _dbContext.Set<NameSearchResult>()
                          .Add(new NameSearchResult
                          {
                              NameId = args.NameKey.Value,
                              PriorArtId = args.SourceDocumentId,
                              NameTypeCode = args.NameTypeKey
                          });
            }

            await _dbContext.SaveChangesAsync();
            txScope.Complete();
            _dbContext.SetCommandTimeOut(null);

            return new
            {
                IsSuccessful = true
            };
        }
    }

    public class AssociateReferenceRequest
    {
        public int SourceDocumentId { get; set; }
        public int? CaseKey { get; set; }
        [MaxLength(20)]
        public string CaseFamilyKey { get; set; }
        public int? NameKey { get; set; }
        [MaxLength(3)]
        public string NameTypeKey { get; set; }
        public int? CaseListKey { get; set; }
    }
}
