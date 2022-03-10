using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.Maintenance
{
    public interface IMaintainSourcePriorArt
    {
        Task<int> MaintainSource(SourceDocumentSaveModel sourceDocument, int priorArtType);
        Task<bool> DeletePriorArt(int sourceId);
    }

    public class MaintainSourcePriorArt : IMaintainSourcePriorArt
    {
        readonly IDbContext _dbContext;

        public MaintainSourcePriorArt(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<int> MaintainSource(SourceDocumentSaveModel sourceDocument, int priorArtType)
        {
            if (sourceDocument.SourceType == null)
            {
                throw new ArgumentNullException(nameof(sourceDocument.SourceType));
            }

            if (sourceDocument.SourceId == null)
            {
                throw new ArgumentNullException(nameof(sourceDocument.SourceId));
            }

            var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().First(_ => _.Id == sourceDocument.SourceId.Value);
            priorArt.Description = string.IsNullOrWhiteSpace(sourceDocument.Description?.Trim()) ? null : sourceDocument.Description?.Trim();
            priorArt.Comments = sourceDocument.Comments;
            priorArt.Abstract = sourceDocument.Abstract;
            priorArt.City = sourceDocument.City;
            priorArt.Publication = sourceDocument.Publication;
            priorArt.Classes = sourceDocument.Classes;
            priorArt.Kind = sourceDocument.KindCode;
            priorArt.Name = sourceDocument.InventorName;
            priorArt.Publisher = sourceDocument.Publisher;
            priorArt.PublishedDate = sourceDocument.PublishedDate;
            priorArt.Citation = sourceDocument.Citation;
            priorArt.Translation = sourceDocument.TranslationType;
            priorArt.RefDocumentParts = sourceDocument.ReferenceParts;
            priorArt.SubClasses = sourceDocument.SubClasses;
            priorArt.ReportIssued = sourceDocument.ReportIssued;
            priorArt.ReportReceived = sourceDocument.ReportReceived;
            priorArt.GrantedDate = sourceDocument.GrantedDate;
            priorArt.ApplicationFiledDate = sourceDocument.ApplicationFiledDate;
            priorArt.IssuingCountryId = sourceDocument.IssuingJurisdiction.Key;
            priorArt.CountryId = sourceDocument.Country.Key;
            priorArt.Title = sourceDocument.Title;
            priorArt.OfficialNumber = sourceDocument.OfficialNumber;
            priorArt.PriorityDate = sourceDocument.PriorityDate;
            priorArt.PtoCitedDate = sourceDocument.PtoCitedDate;
            switch (priorArtType)
            {
                case PriorArtTypes.Source:
                case PriorArtTypes.NewSource:
                    priorArt.SourceTypeId = sourceDocument.SourceType?.Id;
                    priorArt.OfficialNumber = string.Empty;
                    priorArt.ApplicationFiledDate = null;
                    priorArt.GrantedDate = null;
                    priorArt.PriorityDate = null;
                    priorArt.PtoCitedDate = null;
                    priorArt.IsIpDocument = false;
                    priorArt.IsSourceDocument = true;

                    break;
                case PriorArtTypes.Ipo:
                    if (!priorArt.IsIpDocument ?? false)
                    {
                        priorArt.City = null;
                        priorArt.Publisher = null;
                        priorArt.IsIpDocument = true;
                        priorArt.IsSourceDocument = false;
                    }

                    break;
                case PriorArtTypes.Literature:
                    if (priorArt.IsIpDocument ?? false)
                    {
                        priorArt.OfficialNumber = string.Empty;
                        priorArt.ApplicationFiledDate = null;
                        priorArt.GrantedDate = null;
                        priorArt.PriorityDate = null;
                        priorArt.PtoCitedDate = null;
                        priorArt.IsIpDocument = false;
                        priorArt.IsSourceDocument = false;
                        priorArt.Kind = null;
                    }

                    break;

            }

            await _dbContext.SaveChangesAsync();

            return priorArt.Id;
        }

        public async Task<bool> DeletePriorArt(int priorArtId)
        {
            var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(_ => _.Id == priorArtId);
            if (priorArt == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }
            _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Remove(priorArt);
            await _dbContext.SaveChangesAsync();
            return true;
        }
    }
}