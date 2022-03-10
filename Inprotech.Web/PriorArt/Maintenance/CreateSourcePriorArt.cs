using System;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.Maintenance
{
    public interface ICreateSourcePriorArt
    {
        Task<int?> CreateSource(bool ignoreDuplicates, SourceDocumentSaveModel sourceDocument, int? caseKey);
    }

    public class CreateSourcePriorArt : ICreateSourcePriorArt
    {
        readonly IDbContext _dbContext;
        readonly IEvidenceImporter _evidenceImporter;

        public CreateSourcePriorArt(IDbContext dbContext, IEvidenceImporter evidenceImporter)
        {
            _dbContext = dbContext;
            _evidenceImporter = evidenceImporter;
        }

        public async Task<int?> CreateSource(bool ignoreDuplicates, SourceDocumentSaveModel sourceDocument, int? caseKey)
        {
            if (sourceDocument.SourceType == null)
            {
                throw new ArgumentNullException(nameof(sourceDocument.SourceType));
            }

            if (AnyDuplicates(ignoreDuplicates, sourceDocument))
            {
                return null;
            }

            var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Add(new InprotechKaizen.Model.PriorArt.PriorArt
            {
                Description = string.IsNullOrWhiteSpace(sourceDocument.Description?.Trim()) ? null : sourceDocument.Description?.Trim(),
                Comments = sourceDocument.Comments,
                Publication = sourceDocument.Publication,
                Classes = sourceDocument.Classes,
                SubClasses = sourceDocument.SubClasses,
                ReportIssued = sourceDocument.ReportIssued,
                ReportReceived = sourceDocument.ReportReceived,
                IssuingCountryId = sourceDocument.IssuingJurisdiction.Key,
                SourceTypeId = sourceDocument.SourceType?.Id,
                IsIpDocument = false,
                IsSourceDocument = true
            });
            await _dbContext.SaveChangesAsync();

            if (caseKey.HasValue)
            {
                _evidenceImporter.AssociatePriorArtWithCase(priorArt, caseKey.Value);
            }

            return priorArt.Id;
        }

        public bool AnyDuplicates(bool ignoreDuplicates, SourceDocumentSaveModel sourceDocument)
        {
            var duplicates = !ignoreDuplicates && _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                .Any(_ => _.IsSourceDocument && _.IsIpDocument == false && _.SourceTypeId == sourceDocument.SourceType.Id &&
                                (_.IssuingCountryId == sourceDocument.IssuingJurisdiction.Key || (_.IssuingCountryId == null && sourceDocument.IssuingJurisdiction.Key == null)) && 
                                (_.Description.Trim() == sourceDocument.Description.Trim() || (_.Description.Trim() == null && sourceDocument.Description.Trim() == null)));

            return duplicates;
        }
    }
}