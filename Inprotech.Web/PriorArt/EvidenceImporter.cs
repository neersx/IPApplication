using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    public interface IEvidenceImporter
    {
        void ImportMatch(ImportEvidenceModel model, Match match);

        void AssociatePriorArtWithCase(InprotechKaizen.Model.PriorArt.PriorArt priorArt, int caseKey);
    }

    public class EvidenceImporter : IEvidenceImporter
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IComponentResolver _componentResolver;

        public EvidenceImporter(IDbContext dbContext, ISiteConfiguration siteConfiguration, ITransactionRecordal transactionRecordal, IComponentResolver componentResolver)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _transactionRecordal = transactionRecordal;
            _componentResolver = componentResolver;
        }

        public void ImportMatch(ImportEvidenceModel model, Match match)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (match == null) throw new ArgumentNullException(nameof(match));

            var country = _dbContext.Set<Country>().Single(ct => ct.Id == model.Country);
            var pa = CreatePriorArt(country, model.OfficialNumber, match, model.Source);

            var sourceId = model.SourceDocumentId;
            var sourceDocument = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(s => s.Id == sourceId);
            sourceDocument?.CitedPriorArt.Add(pa);
            _dbContext.SaveChanges();

            if (!model.CaseKey.HasValue) return;
            AssociatePriorArtWithCase(pa, model.CaseKey.Value);
        }

        public void AssociatePriorArtWithCase(InprotechKaizen.Model.PriorArt.PriorArt priorArt, int caseKey)
        {
            using var txScope = _dbContext.BeginTransaction();
            var reasonNo = _siteConfiguration.TransactionReason ? _siteConfiguration.ReasonInternalChange : null;
            var @case = _dbContext.Set<Case>().Single(v => v.Id == caseKey);
            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, _componentResolver.Resolve(KnownComponents.PriorArt));

            var caseSearchResult = new CaseSearchResult(caseKey, priorArt.Id, true);
            _dbContext.Set<CaseSearchResult>().Add(caseSearchResult);
            _dbContext.SaveChanges();

            txScope.Complete();
        }

        InprotechKaizen.Model.PriorArt.PriorArt CreatePriorArt(
            Country country,
            string officialNumber,
            Match evidence,
            string importedFrom)
        {
            var priorArtToImport = new InprotechKaizen.Model.PriorArt.PriorArt(officialNumber, country, evidence.Kind)
                                   {
                                       Title = evidence.Title,
                                       Abstract = evidence.Abstract,
                                       Citation = evidence.Citation,
                                       Name = evidence.Name,
                                       ApplicationFiledDate = evidence.ApplicationDate,
                                       PublishedDate = evidence.PublishedDate,
                                       GrantedDate = evidence.GrantedDate,
                                       PriorityDate = evidence.PriorityDate,
                                       PtoCitedDate = evidence.PtoCitedDate,
                                       IsIpDocument = true,
                                       ImportedFrom = importedFrom,
                                       CorrelationId = evidence.Id,
                                       Comments = evidence.Comments,
                                       Translation = evidence.Translation,
                                       RefDocumentParts = evidence.RefDocumentParts,
                                       Description = evidence.Description
                                   };

            _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Add(priorArtToImport);
            return priorArtToImport;
        }
    }
}