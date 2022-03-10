using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Generation.Builders
{
    public class DmsSaveTypeBillDefinitionBuilderFacts
    {
        static DmsSaveTypeBillDefinitionBuilder CreateSubject(
            string scDocMgmtDirectory, bool scSuppressPdfCopies,
            Dictionary<BillPrintDetail, ReportDefinition> returnMap)
        {
            var billDefinitions = Substitute.For<IBillDefinitions>();
            var siteControlReader = Substitute.For<ISiteControlReader>();

            foreach (var r in returnMap)
            {
                billDefinitions.From(Arg.Any<BillGenerationRequest>(), r.Key, Arg.Any<string>())
                               .Returns(x =>
                               {
                                   // set print type for easy identification
                                   r.Value.ReportPath = r.Key.BillPrintType.ToString();
                                   r.Value.FileName = string.IsNullOrWhiteSpace((string)x[2]) ? null : (string)x[2];
                                   return r.Value;
                               });
            }

            siteControlReader.Read<string>(SiteControls.DocMgmtDirectory).Returns(scDocMgmtDirectory);
            siteControlReader.Read<bool>(SiteControls.BillSuppressPDFCopies).Returns(scSuppressPdfCopies);

            return new DmsSaveTypeBillDefinitionBuilder(siteControlReader, billDefinitions);
        }

        [Fact]
        public async Task ShouldReturnBillDefinitionsForEachBillPrintDetails()
        {
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };
            var detail1 = new BillPrintDetail { BillPrintType = BillPrintType.DraftInvoice };
            var detail2 = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            var reportDefinition1 = new ReportDefinition();
            var reportDefinition2 = new ReportDefinition();

            var subject = CreateSubject(
                                        Fixture.String(), Fixture.Boolean(),
                                        new Dictionary<BillPrintDetail, ReportDefinition>
                                        {
                                            { detail1, reportDefinition1 },
                                            { detail2, reportDefinition2 }
                                        });

            var r = (await subject.Build(request, detail1, detail2)).ToArray();

            Assert.Contains(reportDefinition1, r);
            Assert.Contains(reportDefinition2, r);
        }

        [Fact]
        public async Task ShouldReturnOpenItemNoAsFileNameForFinalisedBill()
        {
            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };
            var detail = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            var reportDefinition = new ReportDefinition();

            var subject = CreateSubject(
                                        path, Fixture.Boolean(),
                                        new Dictionary<BillPrintDetail, ReportDefinition>
                                        {
                                            { detail, reportDefinition }
                                        });

            var r = (await subject.Build(request, detail)).Single();

            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}.pdf"), r.FileName);
        }

        [Theory]
        [InlineData(1)]
        [InlineData(5)]
        public async Task ShouldReturnOpenItemNoAsFileNameForCopyToInvoiceAndIncrementsDigitAccordingly(int numberOfCopies)
        {
            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };

            var detailsMap = Enumerable.Range(1, numberOfCopies)
                                       .Select(_ => new BillPrintDetail
                                       {
                                           BillPrintType = BillPrintType.CopyToInvoice
                                       }).ToDictionary(k => k, _ => new ReportDefinition());

            var subject = CreateSubject(path, Fixture.Boolean(), detailsMap);

            var r = (await subject.Build(request, detailsMap.Keys.ToArray())).Last();

            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}_cc{numberOfCopies}.pdf"), r.FileName);
        }

        [Theory]
        [InlineData(1, "_crc1.pdf")]
        [InlineData(5, "_crc5.pdf")]
        public async Task ShouldReturnSingleCopyOnlyForCustomerRequestedCopy(int numberOfCopies, string fileNameEndsWith)
        {
            const bool scBillSuppressPdfCopies = false;

            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };

            var detailsMap = Enumerable.Range(1, numberOfCopies)
                                       .Select(_ => new BillPrintDetail
                                       {
                                           BillPrintType = BillPrintType.CustomerRequestedInvoiceCopies
                                       }).ToDictionary(k => k, _ => new ReportDefinition());

            var subject = CreateSubject(path, scBillSuppressPdfCopies, detailsMap);

            var r = (await subject.Build(request, detailsMap.Keys.ToArray()))
                .Single(_ => !string.IsNullOrEmpty(_.FileName));

            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}{fileNameEndsWith}"), r.FileName);
        }

        [Theory]
        [InlineData(5, "_fc5.pdf")]
        [InlineData(6, "_fc6.pdf")]
        public async Task ShouldReturnFirmInvoiceCopyFileNameIncrementally(int numberOfCopies, string fileNameEndsWith)
        {
            const bool scBillSuppressPdfCopies = false;

            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };

            var detailsMap = Enumerable.Range(1, numberOfCopies)
                                       .Select(_ => new BillPrintDetail
                                       {
                                           BillPrintType = BillPrintType.FirmInvoiceCopy
                                       }).ToDictionary(k => k, _ => new ReportDefinition());

            var subject = CreateSubject(path, scBillSuppressPdfCopies, detailsMap);

            var r = (await subject.Build(request, detailsMap.Keys.ToArray())).Last();

            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}{fileNameEndsWith}"), r.FileName);
        }

        [Theory]
        [InlineData(BillPrintType.CustomerRequestedInvoiceCopies)]
        [InlineData(BillPrintType.FirmInvoiceCopy)]
        public async Task ShouldNotSetFileNameWhenSuppressed(BillPrintType printType)
        {
            const bool scBillSuppressPdfCopies = true;

            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };

            var detail = new BillPrintDetail { BillPrintType = printType };
            var reportDefinition = new ReportDefinition();

            var subject = CreateSubject(path, scBillSuppressPdfCopies,
                                        new Dictionary<BillPrintDetail, ReportDefinition>
                                        {
                                            { detail, reportDefinition }
                                        });

            var _ = await subject.Build(request, detail);

            Assert.Null(reportDefinition.FileName);
        }

        [Fact]
        public async Task ShouldGroupBillsByPrintType()
        {
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };
            var detail1 = new BillPrintDetail { BillPrintType = BillPrintType.DraftInvoice };
            var detail2 = new BillPrintDetail { BillPrintType = BillPrintType.CopyToInvoice };
            var detail3 = new BillPrintDetail { BillPrintType = BillPrintType.DraftInvoice };
            var detail4 = new BillPrintDetail { BillPrintType = BillPrintType.CustomerRequestedInvoiceCopies };
            var detail5 = new BillPrintDetail { BillPrintType = BillPrintType.CopyToInvoice };
            var detail6 = new BillPrintDetail { BillPrintType = BillPrintType.FirmInvoiceCopy };
            var reportDefinition1 = new ReportDefinition();
            var reportDefinition2 = new ReportDefinition();
            var reportDefinition3 = new ReportDefinition();
            var reportDefinition4 = new ReportDefinition();
            var reportDefinition5 = new ReportDefinition();
            var reportDefinition6 = new ReportDefinition();

            var subject = CreateSubject(
                                        Fixture.String(), Fixture.Boolean(),
                                        new Dictionary<BillPrintDetail, ReportDefinition>
                                        {
                                            { detail1, reportDefinition1 },
                                            { detail2, reportDefinition2 },
                                            { detail3, reportDefinition3 },
                                            { detail4, reportDefinition4 },
                                            { detail5, reportDefinition5 },
                                            { detail6, reportDefinition6 }
                                        });

            var r = (await subject.Build(request, detail1, detail2, detail3, detail4, detail5, detail6)).ToArray();

            Assert.Equal(reportDefinition6, r[0]); // BillPrintType.FirmInvoiceCopy
            Assert.Equal(reportDefinition4, r[1]); // BillPrintType.CustomerRequestedInvoiceCopies
            Assert.Equal(reportDefinition2, r[2]); // BillPrintType.CopyToInvoice
            Assert.Equal(reportDefinition5, r[3]); // BillPrintType.CopyToInvoice
            Assert.Equal(reportDefinition1, r[4]); // BillPrintType.DraftInvoice
            Assert.Equal(reportDefinition3, r[5]); // BillPrintType.DraftInvoice
        }
    }
}
