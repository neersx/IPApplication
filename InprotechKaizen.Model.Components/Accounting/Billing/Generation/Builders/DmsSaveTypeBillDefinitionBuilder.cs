using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders
{
    public class DmsSaveTypeBillDefinitionBuilder : IBillDefinitionBuilder
    {
        string _docMgmtDirectory;
        bool _billSuppressPdfCopies;
        bool _settingsLoaded;

        const string RequiredSiteControlNotSet =
            "The '{0}' Site Control is not specified or could not be found. PDF files cannot be created.";

        readonly IBillDefinitions _billDefinitions;
        readonly ISiteControlReader _siteControlReader;
        
        public DmsSaveTypeBillDefinitionBuilder(ISiteControlReader siteControlReader, IBillDefinitions billDefinitions)
        {
            _siteControlReader = siteControlReader;
            _billDefinitions = billDefinitions;
        }

        public async Task<IEnumerable<ReportDefinition>> Build(BillGenerationRequest request, params BillPrintDetail[] billPrintDetails)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (billPrintDetails == null) throw new ArgumentNullException(nameof(billPrintDetails));

            await ResolveSettings();

            var results = new List<ReportDefinition>();
            var details = billPrintDetails.ToArray();
            var copyToInvoiceOrdinal = 0;
            var firmInvoiceCopyOrdinal = 0;
            var firmInvoiceCopyCount = details.CustomerRequestedInvoiceCopiesPrintType().Count();

            foreach (var printDetail in details.InPrintOrder())
            {
                var fileName = string.Empty;

                switch (printDetail.BillPrintType)
                {
                    case BillPrintType.FinalisedInvoice:
                        request.IsFinalisedBill = true;
                        fileName = Path.Combine(_docMgmtDirectory, $"{request.OpenItemNo}.pdf");
                        break;

                    case BillPrintType.CopyToInvoice:
                        fileName = Path.Combine(_docMgmtDirectory, $"{request.OpenItemNo}_cc{++copyToInvoiceOrdinal}.pdf");
                        break;

                    case BillPrintType.CustomerRequestedInvoiceCopies:
                        //Only one copy will be generated as at present all Bill Copies are identical.
                        if (!_billSuppressPdfCopies && firmInvoiceCopyCount > 0)
                        {
                            fileName = Path.Combine(_docMgmtDirectory, $"{request.OpenItemNo}_crc{firmInvoiceCopyCount}.pdf");
                            firmInvoiceCopyCount = 0;
                        }

                        break;

                    case BillPrintType.FirmInvoiceCopy:
                        if (!_billSuppressPdfCopies)
                        {
                            fileName = Path.Combine(_docMgmtDirectory, $"{request.OpenItemNo}_fc{++firmInvoiceCopyOrdinal}.pdf");
                        }

                        break;
                }

                results.Add(_billDefinitions.From(request, printDetail, fileName));
            }

            return results;
        }

        public async Task EnsureValidSettings()
        {
            await ResolveSettings();

            if (!string.IsNullOrWhiteSpace(_docMgmtDirectory))
            {
                return;
            }

            throw new ApplicationException(string.Format(RequiredSiteControlNotSet, SiteControls.DocMgmtDirectory));
        }

        Task ResolveSettings()
        {
            if (!_settingsLoaded)
            {
                _docMgmtDirectory = _siteControlReader.Read<string>(SiteControls.DocMgmtDirectory);
                _billSuppressPdfCopies = _siteControlReader.Read<bool>(SiteControls.BillSuppressPDFCopies);

                _settingsLoaded = true;
            }
            
            return Task.CompletedTask;
        }
    }
}
