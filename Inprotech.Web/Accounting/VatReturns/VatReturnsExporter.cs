using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Text;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IVatReturnsExporter
    {
        void ReturnVatPdf(Stream stream, string pdfId, string filename);
        string ExportVatReturnToPdf(dynamic vatData, dynamic submitResponse, bool isFullFilled);
    }

    public class VatReturnsExporter : IVatReturnsExporter
    {
        const string StoragePath = "vat";
        const string PdfTemplatePath = @"assets\PDFTemplates\";
        readonly ICryptoService _cryptoService;
        readonly IFileSystem _fileSystem;
        readonly Func<Guid> _guidFactory;
        readonly IPdfDocument _pdfDocument;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IStaticTranslator _staticTranslator;

        public VatReturnsExporter(IStaticTranslator staticTranslator, IPreferredCultureResolver preferredCultureResolver, IFileSystem fileSystem, ICryptoService cryptoService, Func<Guid> guidFactory, ISecurityContext securityContext, IPdfDocument pdfDocument)
        {
            _cryptoService = cryptoService;
            _fileSystem = fileSystem;
            _guidFactory = guidFactory;
            _staticTranslator = staticTranslator;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _pdfDocument = pdfDocument;
        }

        public void ReturnVatPdf(Stream stream, string pdfId, string filename)
        {
            if (pdfId == null) throw new ArgumentNullException(nameof(pdfId));
            if (!Guid.TryParse(pdfId, out var storageId)) throw new Exception("Bad argument for stored file");

            var file = GetFilePath(storageId);
            var pdf = $"{filename}.pdf";
            var fileContent = _cryptoService.Decrypt(ReadFile(file, Encoding.UTF8));
            
            _pdfDocument.Generate(stream, pdf, fileContent);
        }

        public string ExportVatReturnToPdf(dynamic vatData, dynamic submitResponse, bool isFullFilled)
        {
            var cultureResolver = _preferredCultureResolver.ResolveAll().ToArray();
            var template = GetTemplateContent();
            var htmlString = template
                             .Replace("##LabelVatDatePeriod##", _staticTranslator.Translate("accounting.vatSubmitter.vatDatePeriod", cultureResolver))
                             .Replace("##vatFromDate##", vatData.FromDate)
                             .Replace("##LabelVatToPeriod##", _staticTranslator.Translate("accounting.vatSubmitter.vatToPeriod", cultureResolver))
                             .Replace("##vatToDate##", vatData.ToDate)
                             .Replace("##LabelVatDatePeriodTaxCode##", vatData.selectedEntitiesNames == string.Empty ? _staticTranslator.Translate("accounting.vatSubmitter.vatDatePeriodTaxCode", cultureResolver) : _staticTranslator.Translate("accounting.vatSubmitter.vatDatePeriodTaxCodeGroup", cultureResolver) )
                             .Replace("##LabelVatBox1##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox1", cultureResolver))
                             .Replace("##LabelVatBox2##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox2", cultureResolver))
                             .Replace("##LabelVatBox3##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox3", cultureResolver))
                             .Replace("##LabelVatBox4##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox4", cultureResolver))
                             .Replace("##LabelVatBox5##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox5", cultureResolver))
                             .Replace("##LabelVatBox6##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox6", cultureResolver))
                             .Replace("##LabelVatBox7##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox7", cultureResolver))
                             .Replace("##LabelVatBox8##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox8", cultureResolver))
                             .Replace("##LabelVatBox9##", _staticTranslator.Translate("accounting.vatSubmitter.vatBox9", cultureResolver))
                             .Replace("##BoxVal1##", vatData.VatValues[0])
                             .Replace("##BoxVal2##", vatData.VatValues[1])
                             .Replace("##BoxVal3##", vatData.VatValues[2])
                             .Replace("##BoxVal4##", vatData.VatValues[3])
                             .Replace("##BoxVal5##", vatData.VatValues[4])
                             .Replace("##BoxVal6##", vatData.VatValues[5])
                             .Replace("##BoxVal7##", vatData.VatValues[6])
                             .Replace("##BoxVal8##", vatData.VatValues[7])
                             .Replace("##BoxVal9##", vatData.VatValues[8]);

            htmlString = htmlString.Replace("{{entity}}", vatData.EntityName)
                                   .Replace("##entityName##", vatData.selectedEntitiesNames == string.Empty ? vatData.EntityName : _staticTranslator.Translate("accounting.vatSubmitter.vatDatePeriodTaxCodeGroup", cultureResolver))
                                   .Replace("{{code}}", vatData.VatNo)
                                   .Replace("##hasMultipleEntities##", vatData.selectedEntitiesNames != string.Empty ? "block" : "none")
                                   .Replace("##LabelMultipleEntities##", vatData.selectedEntitiesNames);

            if (submitResponse.IsSuccessful)
            {
                htmlString = htmlString.Replace("##failureResponse##", "none")
                                       .Replace("##vatSubmittedResponseError##", "none")
                                       .Replace("##successResponse##", "block")
                                       .Replace("##LabelProcessingDate##", _staticTranslator.Translate("accounting.vatSubmitter.processingDate", cultureResolver))
                                       .Replace("##LabelPaymentIndicator##", _staticTranslator.Translate("accounting.vatSubmitter.paymentIndicator", cultureResolver))
                                       .Replace("##LabelFormBundleNumber##", _staticTranslator.Translate("accounting.vatSubmitter.formBundleNumber", cultureResolver))
                                       .Replace("##LabelChargeRefNumber##", _staticTranslator.Translate("accounting.vatSubmitter.chargeRefNumber", cultureResolver))
                                       .Replace("##ProcessingDate##", isFullFilled ? submitResponse.ProcessingDate.ToString() : submitResponse.Data.processingDate.ToString())
                                       .Replace("##PaymentIndicator##", isFullFilled ? submitResponse.PaymentIndicator.ToString() : submitResponse.Data.paymentIndicator.ToString())
                                       .Replace("##FormBundleNumber##", isFullFilled ? submitResponse.FormBundleNumber.ToString() : submitResponse.Data.formBundleNumber.ToString())
                                       .Replace("##ChargeRefNumber##", isFullFilled ? submitResponse.ChargeRefNumber.ToString() : !object.ReferenceEquals(null, submitResponse.Data.chargeRefNumber) ? submitResponse.Data.chargeRefNumber.ToString() : string.Empty);

                htmlString = htmlString.Replace("##LabelSubmitSuccessful##", isFullFilled ? _staticTranslator.Translate("accounting.vatFulfilled.vatIsFulfilled", cultureResolver) : _staticTranslator.Translate("accounting.vatSubmitter.submitSuccessful", cultureResolver));
            }
            else
            {
                htmlString = htmlString.Replace("##failureResponse##", "block")
                                       .Replace("##vatSubmittedResponseError##", "none")
                                       .Replace("##successResponse##", "none");

                if (isFullFilled)
                {
                    htmlString = htmlString.Replace("##submitFailedDetails##", _staticTranslator.Translate("accounting.vatSubmitter.submitFailed", cultureResolver))
                                           .Replace("##responseErrorAndMessage##", submitResponse.code.ToString() + ": " + submitResponse.message.ToString());

                    var errorListString = string.Empty;
                    foreach (var err in submitResponse.errors) errorListString += "<li>" + err.code + ": " + err.message + "</li>";

                    htmlString = htmlString.Replace("##liErrorText##", errorListString);
                }
                else
                {
                    if (!object.ReferenceEquals(null, submitResponse.Data))
                    {
                        htmlString = htmlString.Replace("##submitFailedDetails##", _staticTranslator.Translate("accounting.vatSubmitter.submitFailed", cultureResolver))
                                               .Replace("##responseErrorAndMessage##", submitResponse.Data.code.ToString() + ": " + submitResponse.Data.message.ToString());

                        var errorListString = string.Empty;
                        foreach (var err in submitResponse.Data.errors) errorListString += "<li>" + err.code + ": " + err.message + "</li>";

                        htmlString = htmlString.Replace("##liErrorText##", errorListString);
                    }
                }
            }

            var fileId = _guidFactory();
            var filePath = GetFilePath(fileId);
            var encryptedString = _cryptoService.Encrypt(htmlString);
            _fileSystem.WriteAllText(filePath, encryptedString);
            return fileId.ToString();
        }

        string GetFilePath(Guid fileId)
        {
            return Path.Combine(_fileSystem.AbsolutePath(StoragePath), $"{fileId}-{_securityContext.User.Id}.dat");
        }

        string GetTemplateContent()
        {
            var templatePath = Path.GetFullPath(Path.Combine(".", PdfTemplatePath, "HMRC_VAT_Template.html"));
            return ReadFile(templatePath, Encoding.Default);
        }

        [SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        string ReadFile(string path, Encoding encoding)
        {
            using (var fs = _fileSystem.OpenRead(path))
            using (var sr = new StreamReader(fs, encoding))
            {
                return sr.ReadToEnd();
            }
        }
    }
}