using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Web.PriorArt.Maintenance
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    [RoutePrefix("api")]
    public class PriorArtMaintenanceController : ApiController
    {
        readonly ICreateSourcePriorArt _createSourcePriorArt;
        readonly IMaintainSourcePriorArt _maintainSourcePriorArt;
        readonly IMaintainCitation _maintainCitation;

        public PriorArtMaintenanceController(ICreateSourcePriorArt createSourcePriorArt, IMaintainSourcePriorArt maintainSourcePriorArt, IMaintainCitation maintainCitation)
        {
            _createSourcePriorArt = createSourcePriorArt;
            _maintainSourcePriorArt = maintainSourcePriorArt;
            _maintainCitation = maintainCitation;
        }

        [HttpPost]
        [NoEnrichment]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("priorart/maintenance/{caseKey:int?}")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public async Task<PriorArtSaveResponse> SaveData(PriorArtSaveModel model, int priorArtType, int? caseKey = null)
        {
            var sourceDocument = model.CreateSource.SourceDocument;
            int? newlyCreatedId;
            if (!sourceDocument.SourceId.HasValue)
            {
                newlyCreatedId = await _createSourcePriorArt.CreateSource(model.CreateSource.IgnoreDuplicates, sourceDocument, caseKey);
                if (!newlyCreatedId.HasValue)
                {
                    return new PriorArtSaveResponse
                    {
                        MatchingSourceDocumentExists = true
                    };
                }

            }
            else
            {
                newlyCreatedId = await _maintainSourcePriorArt.MaintainSource(sourceDocument, priorArtType);
            }

            return new PriorArtSaveResponse
            {
                Id = newlyCreatedId,
                SavedSuccessfully = true
            };
        }

        [HttpDelete]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("priorart/maintenance/delete")]
        public async Task<bool> DeletePriorArt([FromUri] int priorArtId)
        {
            return await _maintainSourcePriorArt.DeletePriorArt(priorArtId);
        }

        [HttpDelete]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("priorart/maintenance/deletecitation")]
        public async Task<bool> DeleteCitation([FromUri] int searchPriorArtId, [FromUri] int citedPriorArtId)
        {
            return await _maintainCitation.DeleteCitation(searchPriorArtId, citedPriorArtId);
        }
    }

    public class PriorArtSaveResponse
    {
        public int? Id { get; set; }
        public bool SavedSuccessfully { get; set; }
        public bool MatchingSourceDocumentExists { get; set; }
    }

    public class PriorArtSaveModel
    {
        public CreateSourceSaveModel CreateSource { get; set; }
    }

    public class CreateSourceSaveModel
    {
        public bool IgnoreDuplicates { get; set; }
        public SourceDocumentSaveModel SourceDocument { get; set; }
    }

    public class SourceDocumentSaveModel
    {
        public int? SourceId { get; set; }
        public string Description { get; set; }
        public string ReferenceParts { get; set; }
        public string Abstract { get; set; }
        public string City { get; set; }
        public string Comments { get; set; }
        public string SubClasses { get; set; }
        public string Classes { get; set; }
        public string Title { get; set; }
        public KeyValuePair<string, string> IssuingJurisdiction { get; set; }
        public KeyValuePair<string, string> Country { get; set; }
        public TableCode SourceType { get; set; }
        public string Publication { get; set; }
        public DateTime? ReportIssued { get; set; }
        public DateTime? GrantedDate { get; set; }
        public DateTime? ApplicationFiledDate { get; set; }
        public DateTime? ReportReceived { get; set; }
        public string InventorName { get; set; }
        public string KindCode { get; set; }
        public string OfficialNumber { get; set; }
        public DateTime? PriorityDate { get; set; }
        public DateTime? PtoCitedDate { get; set; }
        public string Publisher { get; set; }
        public string Citation { get; set; }
        public int? TranslationType { get; set; }
        public DateTime? PublishedDate { get; set; }
    }
}