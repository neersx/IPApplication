using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Generation.Builders
{
    public class DefaultBuilderFacts
    {
        static DefaultBuilder CreateSubject(Dictionary<BillPrintDetail, ReportDefinition> returnMap)
        {
            var billDefinitions = Substitute.For<IBillDefinitions>();

            foreach (var r in returnMap)
            {
                billDefinitions.From(Arg.Any<BillGenerationRequest>(), r.Key, Arg.Any<string>())
                                .Returns(x =>
                                {
                                    // set print type for easy identification
                                    r.Value.ReportPath = r.Key.BillPrintType.ToString();
                                    r.Value.FileName = x[2] as string;
                                    return r.Value;
                                });
            }

            return new DefaultBuilder(billDefinitions);
        }
        
        [Fact]
        public async Task ShouldReturnBillDefinitionsForEachBillPrintDetails()
        {
            var request = new BillGenerationRequest();
            var detail1 = new BillPrintDetail { BillPrintType = BillPrintType.DraftInvoice };
            var detail2 = new BillPrintDetail { BillPrintType = BillPrintType.FinalisedInvoice };
            var reportDefinition1 = new ReportDefinition();
            var reportDefinition2 = new ReportDefinition();

            var subject = CreateSubject(new Dictionary<BillPrintDetail, ReportDefinition>
            {
                { detail1, reportDefinition1 },
                { detail2, reportDefinition2 }
            });

            var r = (await subject.Build(request, detail1, detail2)).ToArray();
            
            Assert.Contains(reportDefinition1, r);
            Assert.Contains(reportDefinition2, r);
        }

        [Fact]
        public async Task ShouldGroupBillsByPrintType()
        {
            var request = new BillGenerationRequest();
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

            var subject = CreateSubject(new Dictionary<BillPrintDetail, ReportDefinition>
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
