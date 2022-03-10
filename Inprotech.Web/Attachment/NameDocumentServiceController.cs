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
    [RoutePrefix("api/attachment/name")]
    public class NameDocumentServiceController : ApiController
    {
        readonly ICaseNamesAdhocDocumentData _adhocDocumentData;
        readonly IDbContext _dbContext;
        readonly IDeliveryDestinationResolver _deliveryDestinationResolver;
        readonly IPdfFormFillService _pdfFormFillService;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NameDocumentServiceController(IDbContext dbContext, ICaseNamesAdhocDocumentData adhocDocumentData, IDeliveryDestinationResolver destinationResolver, IPdfFormFillService pdfFormFillService, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _adhocDocumentData = adhocDocumentData;
            _deliveryDestinationResolver = destinationResolver;
            _pdfFormFillService = pdfFormFillService;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/document/{documentId:int}/data")]
        public async Task<AdhocDocumentDataModel> DocumentData(int nameId, int documentId, bool addAsAttachment)
        {
            return await _adhocDocumentData.Resolve(null, nameId, documentId, addAsAttachment);
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/document/{documentId:int}/delivery-destination")]
        public async Task<DeliveryDestination> DeliveryDestination(int nameId, int documentId)
        {
            return await _deliveryDestinationResolver.ResolveForCaseNames(null, nameId, (short) documentId);
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/document/{documentId:int}/activity")]
        public async Task<dynamic> DocumentActivity(int nameId, int documentId)
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

        [HttpPost]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/document/generate-pdf")]
        public async Task<DocumentGenerationResult> GeneratePdfDocument(int nameId, [FromBody] PdfGenerationModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var culture = _preferredCultureResolver.Resolve();
            var result = await _pdfFormFillService.GeneratePdfDocument(model, culture);
            return result;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/document/get-pdf")]
        public async Task<HttpResponseMessage> GetGeneratePdfDocument(int nameId, string fileKey)
        {
            if (string.IsNullOrWhiteSpace(fileKey)) throw new ArgumentNullException(fileKey);
            var response = await _pdfFormFillService.GetGeneratedPdfDocument(fileKey);

            return response;
        }
    }
}