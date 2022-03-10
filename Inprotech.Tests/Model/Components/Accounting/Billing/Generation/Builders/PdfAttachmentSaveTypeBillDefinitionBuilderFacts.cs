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
    public class PdfAttachmentSaveTypeBillDefinitionBuilderFacts
    {
        static PdfAttachmentSaveTypeBillDefinitionBuilder CreateSubject(
            string scBillPdfDirectory, string scDnOrigCopyText)
        {
            var billDefinitions = Substitute.For<IBillDefinitions>();
            var siteControlReader = Substitute.For<ISiteControlReader>();

            billDefinitions.From(Arg.Any<BillGenerationRequest>(), Arg.Any<BillPrintDetail>(), Arg.Any<string>())
                           .Returns(x =>
                           {
                               var billPrintDetail = (BillPrintDetail)x[1];
                               var fileName = string.IsNullOrWhiteSpace((string)x[2]) ? null : (string)x[2];

                               return new ReportDefinition
                               {
                                   FileName = fileName,
                                   ShouldMakeContentModifiable = billPrintDetail.IsPdfModifiable,
                                   ShouldExcludeFromConcatenation = billPrintDetail.ExcludeFromConcatenation,
                                   Parameters = new Dictionary<string, string>()
                                   {
                                       { "BillPrintType", billPrintDetail.BillPrintType.ToString() },
                                       { "ReprintLabel", billPrintDetail.ReprintLabel },
                                   }
                               };
                           });
            
            siteControlReader.ReadMany<string>(SiteControls.BillPDFDirectory, SiteControls.DNOrigCopyText)
                             .Returns(new Dictionary<string, string>
                             {
                                 { SiteControls.BillPDFDirectory, scBillPdfDirectory },
                                 { SiteControls.DNOrigCopyText, scDnOrigCopyText }
                             });

            return new PdfAttachmentSaveTypeBillDefinitionBuilder(siteControlReader, billDefinitions);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldReturnReportDefinitionForEachPrintDetail(bool asModifiablePdf)
        {
            var path = Fixture.String();
            var request = new BillGenerationRequest { OpenItemNo = Fixture.String() };
            var detail1 = new BillPrintDetail { BillPrintType = BillPrintType.CopyToInvoice, IsPdfModifiable = asModifiablePdf };
            var detail2 = new BillPrintDetail { BillPrintType = BillPrintType.DraftInvoice, IsPdfModifiable = asModifiablePdf };
            var subject = CreateSubject(path, "~~~copy~~~");

            var r = await subject.Build(request, detail1, detail2);
            
            Assert.Collection(r, 
                              _ =>
                              {
                                  Assert.Equal(detail1.BillPrintType.ToString(), _.Parameters["BillPrintType"]);
                                  Assert.Equal(detail1.IsPdfModifiable, _.ShouldMakeContentModifiable);
                              },
                              _ =>
                              {
                                  Assert.Equal(detail2.BillPrintType.ToString(), _.Parameters["BillPrintType"]);
                                  Assert.Equal(detail2.IsPdfModifiable, _.ShouldMakeContentModifiable);
                              });
        }
        
        [Theory]
        [InlineData(null)]
        [InlineData("~~~copy~~~")]
        public async Task ShouldSuppressPdfGenerationIfIndicated(string scDnOriginalCopyText)
        {
            var path = Fixture.String();
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String(),
                ShouldSuppressPdf = true
            };

            var detail1 = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoiceWithReprintLabel };
            var detail2 = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            
            var subject = CreateSubject(path, scDnOriginalCopyText);

            var r = await subject.Build(request, detail1, detail2);
        
            Assert.All(r, x => Assert.Null(x.FileName));
        }
        
        [Theory]
        [InlineData(BillPrintType.FinalisedInvoiceWithReprintLabel)]
        [InlineData(BillPrintType.FinalisedInvoice)]
        public async Task ShouldAssignFileNameUsingOpenItemNoForFinalisedBills(BillPrintType billPrintType)
        {
            const string scDnOriginalCopyText = null;

            var path = Fixture.String();
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String(),
                ShouldSuppressPdf = false
            };

            var detail = new BillPrintDetail { BillPrintType = billPrintType };
            
            var subject = CreateSubject(path, scDnOriginalCopyText);

            var r = await subject.Build(request, detail);
            
            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}.pdf"), r.Single().FileName);
        }

        [Fact]
        public async Task ShouldMarkRequestAsFinalisedForFinalisedBills()
        {
            const string scDnOriginalCopyText = null;

            var path = Fixture.String();
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String(),
                ShouldSuppressPdf = false
            };

            var detail = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            
            var subject = CreateSubject(path, scDnOriginalCopyText);

            var _ = await subject.Build(request, detail);
            
            Assert.True(request.IsFinalisedBill);
        }
        
        [Theory]
        [InlineData(BillPrintType.FinalisedInvoiceWithReprintLabel)]
        [InlineData(BillPrintType.FinalisedInvoice)]
        public async Task ShouldAssignFileNameUsingOpenItemNoAndEntityCodeIfProvidedForFinalisedBills(BillPrintType billPrintType)
        {
            const string scDnOriginalCopyText = null;

            var path = Fixture.String();
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String(),
                ShouldSuppressPdf = false
            };

            var detail = new BillPrintDetail { BillPrintType = billPrintType, EntityCode = Fixture.String() };
            
            var subject = CreateSubject(path, scDnOriginalCopyText);

            var r = await subject.Build(request, detail);
            
            Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}_{detail.EntityCode}.pdf"), r.Single().FileName);
        }

        [Fact]
        public async Task ShouldMarkFinaliseBillReprintedIfDnOrigCopyTextIsSet()
        {
            const string scDnOriginalCopyText = "~~~copy~~~";

            var path = Fixture.String();
            var request = new BillGenerationRequest
            {
                OpenItemNo = Fixture.String(),
                ShouldSuppressPdf = false
            };

            var detail = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            
            var subject = CreateSubject(path, scDnOriginalCopyText);

            var r = await subject.Build(request, detail);
            
            Assert.Collection(r,
                              _ =>
                              {
                                  Assert.Equal("FinalisedInvoiceWithReprintLabel", _.Parameters["BillPrintType"]);
                                  Assert.Equal(scDnOriginalCopyText, _.Parameters["ReprintLabel"]);
                                  Assert.Equal(Path.Combine(path, $"{request.OpenItemNo}.pdf"), _.FileName);
                                  Assert.True(_.ShouldExcludeFromConcatenation);
                              },
                              _ =>
                              {
                                  Assert.Equal("FinalisedInvoiceWithoutReprintLabel", _.Parameters["BillPrintType"]);
                                  Assert.Null(_.Parameters["ReprintLabel"]);
                                  Assert.False(_.ShouldExcludeFromConcatenation);
                                  Assert.Null(_.FileName);
                              });

            Assert.True(request.IsFinalisedBill);
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

            var subject = CreateSubject(
                                        Fixture.String(), "~~~copy~~~");

            var r = await subject.Build(request, detail1, detail2, detail3, detail4, detail5, detail6);

            Assert.Collection(r, 
                              x => Assert.Equal("FirmInvoiceCopy", x.Parameters["BillPrintType"]),
                              x => Assert.Equal("CustomerRequestedInvoiceCopies", x.Parameters["BillPrintType"]),
                              x => Assert.Equal("CopyToInvoice", x.Parameters["BillPrintType"]),
                              x => Assert.Equal("CopyToInvoice", x.Parameters["BillPrintType"]),
                              x => Assert.Equal("DraftInvoice", x.Parameters["BillPrintType"]),
                              x => Assert.Equal("DraftInvoice", x.Parameters["BillPrintType"]));
        }
    }
}
