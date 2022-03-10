using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders
{
    public class PdfAttachmentSaveTypeBillDefinitionBuilder : IBillDefinitionBuilder
    {
        const string RequiredSiteControlNotSet =
            @"The '{0}' Site Control is not specified or could not be found. PDF file cannot be created and Attachment of the Debit/Credit Note PDF file to Cases and/or Names has failed.";

        readonly IBillDefinitions _billDefinitions;

        readonly ISiteControlReader _siteControlReader;
        string _billPdfDirectory;
        string _dnOriginalCopyText;

        bool _settingsLoaded;

        public PdfAttachmentSaveTypeBillDefinitionBuilder(ISiteControlReader siteControlReader, IBillDefinitions billDefinitions)
        {
            _siteControlReader = siteControlReader;
            _billDefinitions = billDefinitions;
        }

        bool HasOriginalCopyText => !string.IsNullOrWhiteSpace(_dnOriginalCopyText);

        public async Task EnsureValidSettings()
        {
            await ResolveSettings();

            if (!string.IsNullOrWhiteSpace(_billPdfDirectory))
            {
                return;
            }

            throw new ApplicationException(string.Format(RequiredSiteControlNotSet, SiteControls.BillPDFDirectory));
        }

        Task ResolveSettings()
        {
            if (!_settingsLoaded)
            {
                var settings = _siteControlReader.ReadMany<string>(SiteControls.BillPDFDirectory, SiteControls.DNOrigCopyText);

                _dnOriginalCopyText = settings.Get(SiteControls.DNOrigCopyText);
                _billPdfDirectory = settings.Get(SiteControls.BillPDFDirectory);

                _settingsLoaded = true;
            }

            return Task.CompletedTask;
        }

        public async Task<IEnumerable<ReportDefinition>> Build(BillGenerationRequest request,
                                                               params BillPrintDetail[] billPrintDetails)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (billPrintDetails == null) throw new ArgumentNullException(nameof(billPrintDetails));

            await ResolveSettings();

            var results = new List<ReportDefinition>();

            var shouldPrintCopyLabel = HasOriginalCopyText && billPrintDetails.FinalisedInvoicePrintType().Any();

            var details = shouldPrintCopyLabel
                ? WithReprintLabel(billPrintDetails)
                : billPrintDetails;

            foreach (var printDetail in details.InPrintOrder())
            {
                var fileName = string.Empty;

                switch (printDetail.BillPrintType)
                {
                    case BillPrintType.FinalisedInvoice:
                        request.IsFinalisedBill = true;

                        if (!request.ShouldSuppressPdf)
                        {
                            fileName = Path.Combine(_billPdfDirectory,
                                                    string.IsNullOrEmpty(printDetail.EntityCode)
                                                        ? $"{request.OpenItemNo}.pdf"
                                                        : $"{request.OpenItemNo}_{printDetail.EntityCode}.pdf");

                            request.FileName = fileName;
                        }

                        break;

                    case BillPrintType.FinalisedInvoiceWithReprintLabel:
                        request.IsFinalisedBill = true;
                        printDetail.ExcludeFromConcatenation = true;

                        if (!request.ShouldSuppressPdf)
                        {
                            fileName = Path.Combine(_billPdfDirectory,
                                                    string.IsNullOrEmpty(printDetail.EntityCode)
                                                        ? $"{request.OpenItemNo}.pdf"
                                                        : $"{request.OpenItemNo}_{printDetail.EntityCode}.pdf");

                            request.FileName = fileName;
                        }

                        break;
                }

                results.Add(_billDefinitions.From(request, printDetail, fileName));
            }

            return results;
        }

        IEnumerable<BillPrintDetail> WithReprintLabel(IEnumerable<BillPrintDetail> billPrintDetails)
        {
            /* If 'DN Orig Copy Text' contains a value, 
             * then the generated PDF file will always have the copy label printed on it 
             * (even the PDF file produced on the first print).*/

            var bills = new List<BillPrintDetail>(billPrintDetails);

            var finalisedBillPrintDetail =
                bills.Single(b => b.BillPrintType == BillPrintType.FinalisedInvoice);

            if (finalisedBillPrintDetail.ReprintLabel == null ||
                !finalisedBillPrintDetail.ReprintLabel.Equals(_dnOriginalCopyText))
            {
                finalisedBillPrintDetail.BillPrintType = BillPrintType.FinalisedInvoiceWithoutReprintLabel;

                bills.Add(new BillPrintDetail
                {
                    CopyNo = bills.Count,
                    BillPrintType = BillPrintType.FinalisedInvoiceWithReprintLabel,
                    OpenItemNo = finalisedBillPrintDetail.OpenItemNo,
                    EntityCode = finalisedBillPrintDetail.EntityCode,
                    BillTemplate = finalisedBillPrintDetail.BillTemplate,
                    ReprintLabel = _dnOriginalCopyText,
                    CopyLabel = finalisedBillPrintDetail.CopyLabel,
                    CopyToName = finalisedBillPrintDetail.CopyToName,
                    CopyToAttention = finalisedBillPrintDetail.CopyToAttention,
                    CopyToAddress = finalisedBillPrintDetail.CopyToAddress,
                    IsPdfModifiable = finalisedBillPrintDetail.IsPdfModifiable
                });
            }

            return bills;
        }
    }
}