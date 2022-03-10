using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Formatting.Exports;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public interface IBillDefinitions
    {
        ReportDefinition From(BillGenerationRequest request, BillPrintDetail billPrintDetail, string fileName);
    }

    public class BillDefinitions : IBillDefinitions
    {
        public ReportDefinition From(BillGenerationRequest request, BillPrintDetail billPrintDetail, string fileName)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (billPrintDetail == null) throw new ArgumentNullException(nameof(billPrintDetail));

            return new ReportDefinition
            {
                ReportPath = string.Format(KnownParameters.ReportPath, billPrintDetail.BillTemplate),
                ReportExportFormat = ReportExportFormat.Pdf,
                Parameters = new Dictionary<string, string>
                {
                    { KnownParameters.ItemEntityId, $"{request.ItemEntityId}" },
                    { KnownParameters.OpenItemNo, request.OpenItemNo },
                    { KnownParameters.CopyNo, $"{billPrintDetail.CopyNo}"},
                    { KnownParameters.BillPrintType, $"{(int) billPrintDetail.BillPrintType}" },
                    { KnownParameters.ReprintLabel, billPrintDetail.ReprintLabel },
                    { KnownParameters.CopyLabel, billPrintDetail.CopyLabel },
                    { KnownParameters.CopyToName, billPrintDetail.CopyToName },
                    { KnownParameters.CopyToAttention, billPrintDetail.CopyToAttention },
                    { KnownParameters.CopyToAddress, billPrintDetail.CopyToAddress },
                },
                ShouldMakeContentModifiable = billPrintDetail.IsPdfModifiable,
                ShouldExcludeFromConcatenation = billPrintDetail.ExcludeFromConcatenation,
                FileName = fileName
            };
        }              
    }

    public class KnownParameters
    {
        public const string ReportPath = "Billing/Standard/{0}";
        public const string ItemEntityId = "EntityNo";
        public const string OpenItemNo = "OpenItemNo";
        public const string CopyNo = "CopyNo";
        public const string BillPrintType = "BillPrintType";
        public const string ReprintLabel = "ReprintLabel";
        public const string CopyLabel = "CopyLabel";
        public const string CopyToName = "CopyToName";
        public const string CopyToAttention = "CopyToAttention";
        public const string CopyToAddress = "CopyToAddress";
    }
}
