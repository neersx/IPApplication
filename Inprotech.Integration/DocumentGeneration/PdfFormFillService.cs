using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Components.DocumentGeneration.Services;
using InprotechKaizen.Model.Components.DocumentGeneration.Services.Pdf;

namespace Inprotech.Integration.DocumentGeneration
{
    public interface IPdfFormFillService
    {
        Task<DocumentGenerationResult> GeneratePdfDocument(PdfGenerationModel model, string culture);
        Task<HttpResponseMessage> GetGeneratedPdfDocument(string fileKey);
    }

    public class PdfFormFillService : IPdfFormFillService
    {
        const string DefaultContentType = "application/pdf";
        const string DefaultFileExtension = "pdf";
        readonly IFormFieldsResolver _formFieldsResolver;
        readonly IPdfForm _pdfForm;
        readonly IRunDocItemsManager _runDocItemsManager;
        readonly IStorageServiceClient _storageServiceClient;

        public PdfFormFillService(IFormFieldsResolver formFieldsResolver, IRunDocItemsManager runDocItemsManager, IPdfForm pdfForm, IStorageServiceClient storageServiceClient)
        {
            _formFieldsResolver = formFieldsResolver;
            _runDocItemsManager = runDocItemsManager;
            _pdfForm = pdfForm;
            _storageServiceClient = storageServiceClient;
        }

        public async Task<HttpResponseMessage> GetGeneratedPdfDocument(string fileKey)
        {
            var doc = _pdfForm.GetCachedDocument(fileKey);
            var response = new HttpResponseMessage(HttpStatusCode.OK);
            if (doc?.Data != null)
            {
                response.Content = new ByteArrayContent(doc.Data);

                response.Content.Headers.ContentType = new MediaTypeHeaderValue(DefaultContentType);
                var fileName = doc.FileName;
                response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
                {
                    FileName = fileName
                };
                response.Headers.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true,
                    NoStore = true,
                    MaxAge = TimeSpan.Zero
                };
            }

            return response;
        }

        public async Task<DocumentGenerationResult> GeneratePdfDocument(PdfGenerationModel model, string culture)
        {
            if (string.IsNullOrWhiteSpace(model.Template)) throw new ArgumentNullException(nameof(model.Template));
            if (string.IsNullOrWhiteSpace(model.EntryPoint)) throw new ArgumentNullException(nameof(model.EntryPoint));

            var result = new DocumentGenerationResult();
            try
            {
                var formFields = await _formFieldsResolver.Resolve(model.DocumentId, culture);
                var itemProcessors = GetItemProcessors(formFields, model.EntryPoint).ToList();
                itemProcessors = _runDocItemsManager.Execute(itemProcessors).ToList();
                var formFileName = GetTemporaryFile(DefaultFileExtension);

                var resolvedFormTemplate = _pdfForm.EnsureExists(model.Template);

                await _pdfForm.Fill(formFileName, resolvedFormTemplate, itemProcessors);

                result.FileIdentifier = _pdfForm.CacheDocument(formFileName, string.IsNullOrWhiteSpace(model.SaveFileName) ? $"{model.DocumentName}.pdf" : model.SaveFileName);

                if (!string.IsNullOrWhiteSpace(model.SaveFileLocation))
                {
                    await UploadFileToAttachmentFolder(model, result.FileIdentifier);
                }
                result.Errors = ListItemProcessorInError(itemProcessors).Select(_ => new ValidationError(_.Fields, _.ErrorMessage, _.ErrorMessage));
            }
            finally
            {
                _pdfForm.CleanUp();
            }

            return result;
        }

        async Task UploadFileToAttachmentFolder(PdfGenerationModel model, string fileIdentifier)
        {
            var request = new HttpRequestMessage {Method = HttpMethod.Post};
            var content = new MultipartFormDataContent {new StringContent(model.SaveFileLocation)};
            var byteArrayContent = new ByteArrayContent(_pdfForm.GetCachedDocument(fileIdentifier, true).Data);
            byteArrayContent.Headers.Add("Content-Type", "application/octet-stream");
            var cdValue = new ContentDispositionHeaderValue("FileName") {FileName = model.SaveFileName};
            byteArrayContent.Headers.ContentDisposition = cdValue;
            content.Add(byteArrayContent);
            request.Content = content;

            var uploadResult = await _storageServiceClient.UploadFile(request);

            if (!uploadResult.IsSuccessStatusCode)
            {
                throw new Exception(uploadResult.ReasonPhrase);
            }
        }

        static IEnumerable<ItemProcessorInError> ListItemProcessorInError(IEnumerable<ItemProcessor> itemProcessors)
        {
            var itemProcessorsInError = new List<ItemProcessorInError>();

            foreach (var itemProcessor in itemProcessors.Where(i => i.Exception != null))
            {
                var exception = itemProcessor.Exception as ItemProcessorException;
                if (exception != null && exception.Reason == ItemProcessErrorReason.DocItemNullOrEmpty)
                {
                    continue;
                }

                var itemProcessorInError = new ItemProcessorInError();
                if (itemProcessor.Fields.Any())
                {
                    itemProcessorInError.Fields = string.Empty;

                    foreach (var field in itemProcessor.Fields)
                    {
                        if (!string.IsNullOrEmpty(itemProcessorInError.Fields))
                        {
                            itemProcessorInError.Fields += ", ";
                        }

                        itemProcessorInError.Fields += field.FieldName;
                    }
                }

                if (itemProcessor.ReferencedDataItem != null)
                {
                    itemProcessorInError.ItemName = itemProcessor.ReferencedDataItem.ItemName;
                }

                if (exception != null)
                {
                    itemProcessorInError.ErrorType = exception.Reason.ToString();
                }

                itemProcessorInError.ErrorMessage = itemProcessor.Exception.Message;
                itemProcessorsInError.Add(itemProcessorInError);
            }

            return itemProcessorsInError;
        }

        static string GetTemporaryFile(string fileExtension)
        {
            return Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + "." + fileExtension);
        }

        IEnumerable<ItemProcessor> GetItemProcessors(IEnumerable<FieldItem> formFields, string entryPoint)
        {
            var itemProcessors = new List<ItemProcessor>();
            var requestId = 0;
            foreach (var formField in formFields)
            {
                var itemProcessor = new ItemProcessor
                {
                    ID = $"{++requestId}",
                    Fields = new List<Field> {new Field {FieldName = formField.FieldName, FieldType = formField.FieldType}},
                    ReferencedDataItem = new ReferencedDataItem {ItemName = formField.ItemName},
                    Separator = formField.ResultSeparator,
                    Parameters = formField.ItemParameter,
                    EntryPointValue = entryPoint
                };
                itemProcessor.RowsReturnedMode = string.IsNullOrEmpty(itemProcessor.Separator)
                    ? RowsReturnedMode.Single
                    : RowsReturnedMode.Multiple;
                itemProcessors.Add(itemProcessor);
            }

            return itemProcessors;
        }
    }

    public class DocumentGenerationResult
    {
        public DocumentGenerationResult()
        {
            IsSuccess = true;
        }

        public bool IsSuccess { get; set; }
        public string FileIdentifier { get; set; }
        public IEnumerable<ValidationError> Errors { get; set; }
    }

    public class PdfGenerationModel
    {
        public int DocumentId { get; set; }
        public string DocumentName { get; set; }
        public string Template { get; set; }
        public string SaveFileLocation { get; set; }
        public string SaveFileName { get; set; }
        public string EntryPoint { get; set; }
    }
}