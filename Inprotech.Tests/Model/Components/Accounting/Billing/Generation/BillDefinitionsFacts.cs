using Inprotech.Infrastructure.Formatting.Exports;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Generation
{
    public class BillDefinitionsFacts
    {
        [Theory]
        [InlineData(BillPrintType.FinalisedInvoice)]
        [InlineData(BillPrintType.CopyToInvoice)]
        [InlineData(BillPrintType.CustomerRequestedInvoiceCopies)]
        [InlineData(BillPrintType.DraftInvoice)]
        [InlineData(BillPrintType.FinalisedInvoiceWithReprintLabel)]
        [InlineData(BillPrintType.FinalisedInvoiceWithoutReprintLabel)]
        [InlineData(BillPrintType.FirmInvoiceCopy)]
        public void ShouldReturnReportDefinitionFromPrintDetails(BillPrintType printType)
        {
            var billPrintDetail = new BillPrintDetail
            {
                BillTemplate = Fixture.String(),
                ReprintLabel = Fixture.String(),
                CopyLabel = Fixture.String(),
                CopyToName = Fixture.String(),
                CopyToAttention = Fixture.String(),
                CopyToAddress = Fixture.String(),
                CopyNo = Fixture.Integer(),
                BillPrintType = printType
            };

            var subject = new BillDefinitions();

            var r = subject.From(new BillGenerationRequest(), billPrintDetail, Fixture.String());

            Assert.Equal($"Billing/Standard/{billPrintDetail.BillTemplate}", r.ReportPath);

            Assert.Equal($"{billPrintDetail.CopyNo}", r.Parameters[KnownParameters.CopyNo]);
            Assert.Equal($"{(int) printType}", r.Parameters[KnownParameters.BillPrintType]);
            Assert.Equal(billPrintDetail.ReprintLabel, r.Parameters[KnownParameters.ReprintLabel]);
            Assert.Equal(billPrintDetail.CopyLabel, r.Parameters[KnownParameters.CopyLabel]);
            Assert.Equal(billPrintDetail.CopyToName, r.Parameters[KnownParameters.CopyToName]);
            Assert.Equal(billPrintDetail.CopyToAttention, r.Parameters[KnownParameters.CopyToAttention]);
            Assert.Equal(billPrintDetail.CopyToAddress, r.Parameters[KnownParameters.CopyToAddress]);

            Assert.Equal(billPrintDetail.IsPdfModifiable, r.ShouldMakeContentModifiable);
            Assert.Equal(billPrintDetail.ExcludeFromConcatenation, r.ShouldExcludeFromConcatenation);
        }

        [Fact]
        public void ShouldReturnReportDefinitionFromBillGenerationRequest()
        {
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String()
            };

            var subject = new BillDefinitions();

            var r = subject.From(request, new BillPrintDetail(), Fixture.String());

            Assert.Equal(request.OpenItemNo, r.Parameters[KnownParameters.OpenItemNo]);
        }

        [Fact]
        public void ShouldReturnReportDefinitionFileNameAsProvided()
        {
            var fileName = Fixture.String();

            var subject = new BillDefinitions();

            var r = subject.From(new BillGenerationRequest(), new BillPrintDetail(), fileName);

            Assert.Equal(fileName, r.FileName);
        }

        [Fact]
        public void ShouldReturnReportDefinitionWithPdfExportFormat()
        {
            var subject = new BillDefinitions();

            var r = subject.From(new BillGenerationRequest(), new BillPrintDetail(), Fixture.String());

            Assert.Equal(ReportExportFormat.Pdf, r.ReportExportFormat);
        }
    }
}
