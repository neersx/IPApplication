using System;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DocumentGeneration;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Attachment
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/attachment/case")]
    public class CaseDocumentServiceController : ApiController
    {
        readonly ICaseNamesAdhocDocumentData _adhocDocumentData;
        readonly IDbContext _dbContext;
        readonly IDeliveryDestinationResolver _deliveryDestinationResolver;
        readonly IPdfFormFillService _pdfFormFillService;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseDocumentServiceController(IDbContext dbContext, ICaseNamesAdhocDocumentData adhocDocumentData, IDeliveryDestinationResolver deliveryDestinationResolver, IPdfFormFillService pdfFormFillService, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _adhocDocumentData = adhocDocumentData;
            _deliveryDestinationResolver = deliveryDestinationResolver;
            _pdfFormFillService = pdfFormFillService;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/document/{documentId:int}/data")]
        public async Task<AdhocDocumentDataModel> DocumentData(int caseId, int documentId, bool addAsAttachment)
        {
            return await _adhocDocumentData.Resolve(caseId, null, documentId, addAsAttachment);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/document/{documentId:int}/activity")]
        public async Task<dynamic> DocumentActivity(int caseId, int documentId)
        {
            var documentActivity = await _dbContext.Set<Document>().Select(_ => new
            {
                _.Id,
                _.ActivityType,
                _.ActivityCategory
            }).SingleAsync(d => d.Id == documentId);

            return new
            {
                documentActivity.ActivityType,
                documentActivity.ActivityCategory
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/document/{documentId:int}/delivery-destination")]
        public async Task<DeliveryDestination> DeliveryDestination(int caseId, int documentId)
        {
            return await _deliveryDestinationResolver.ResolveForCaseNames(caseId, null, (short) documentId);
        }

        [HttpPost]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/document/generate-pdf")]
        public async Task<DocumentGenerationResult> GeneratePdfDocument(int caseId, [FromBody] PdfGenerationModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var culture = _preferredCultureResolver.Resolve();
            var result = await _pdfFormFillService.GeneratePdfDocument(model, culture);
            return result;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/document/get-pdf")]
        public async Task<HttpResponseMessage> GetGeneratePdfDocument(int caseId, string fileKey)
        {
            if (string.IsNullOrWhiteSpace(fileKey)) throw new ArgumentNullException(fileKey);
            var response = await _pdfFormFillService.GetGeneratedPdfDocument(fileKey);

            return response;
        }
    }
}