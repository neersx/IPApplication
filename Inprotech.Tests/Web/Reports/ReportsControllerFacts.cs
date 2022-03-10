using System.Collections.Generic;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Reports;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Reports
{
    public class ReportsControllerFacts
    {
        [Fact]
        public async Task ShouldReturnContentIdGenerateBillingWorkSheet()
        {
            var f = new ReportsControllerFixture();
            var contentId = Fixture.Integer();
            var criteria = new JObject
            {
                ["connectionId"] = Fixture.String(),
                ["reportName"] = "billingWorksheet",
                ["items"] = JsonConvert.SerializeObject(new[]
                {
                    new BillingWorksheetItem {CaseKey = 113, EntityKey = -283575757},
                    new BillingWorksheetItem {CaseKey = 114, EntityKey = -283575757}
                }),
                ["reportExportFormat"] = ReportExportFormat.Excel.ToString(),
                ["xmlFilterCriteria"] = @"<Search><Filtering><wp_ListWorkInProgress><FilterCriteria><EntityKey Operator='0'>-283575757</EntityKey><BelongsTo><StaffKey Operator='0' IsCurrentUser='1' /><ActingAs><IsWipStaff>0</IsWipStaff><AssociatedName>1</AssociatedName></ActingAs></BelongsTo><Debtor IsRenewalDebtor='1' /><ResponsibleName><NameKey>42</NameKey><IsInstructor>1</IsInstructor><IsDebtor>1</IsDebtor></ResponsibleName><WipStatus><IsActive>1</IsActive><IsLocked>1</IsLocked></WipStatus><RenewalWip><IsRenewal>1</IsRenewal><IsNonRenewal>1</IsNonRenewal></RenewalWip></FilterCriteria><AggregateFilterCriteria /></wp_ListWorkInProgress></Filtering></Search>"
            };

            f.ExportContentService.GenerateContentId((string) criteria["connectionId"], (string) criteria["reportName"]).Returns(contentId);

            f.SecurityContext.User.Returns(new User {NameId = 45});
            
            var result = await f.Subject.GenerateBillingWorkSheet(criteria);

            Assert.Equal(contentId, result);
        }

        [Fact]
        public async Task ShouldReturnFalseGenerateBillingWorkSheet()
        {
            var f = new ReportsControllerFixture();

            var result = await f.Subject.GenerateBillingWorkSheet(null);
            
            Assert.False(result > 0);
        }

        [Fact]
        public async Task ShouldReturnReportProviderInfo()
        {
            var f = new ReportsControllerFixture();
            var data = new ProviderInfo
            {
                Name = Fixture.RandomString(10), 
                DefaultExportFormat = ReportExportFormat.Pdf, 
                ExportFormats = new List<ExportFormatData>(), 
                Provider = ReportProviderType.Default
            };

            f.ReportManager.GetReportProviderInfo().Returns(data);
            var results = await f.Subject.GetReportProviderInfo();

            Assert.Equal(data.Name, results.Name);
            Assert.Equal(data.DefaultExportFormat, results.DefaultExportFormat);
            Assert.Equal(data.Provider, results.Provider);
        }
    }

    public class ReportsControllerFixture : IFixture<ReportsController>
    {
        public ReportsControllerFixture()
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            ReportManager = Substitute.For<IReportProvider>();
            ExportContentService = Substitute.For<IExportContentService>();
            ReportsManager = Substitute.For<IIndex<string, IReportsManager>>();
            Bus = Substitute.For<IBus>();
            Logger = Substitute.For<ILogger<ReportsController>>();
            Subject = new ReportsController(ReportManager, ExportContentService, Bus, Logger, ReportsManager);
        }

        public ISecurityContext SecurityContext { get; set; }
        public IReportProvider ReportManager { get; set; }
        public IExportContentService ExportContentService { get; set; }
        public IIndex<string, IReportsManager> ReportsManager { get; set; }
        public IBus Bus { get; set; }
        public ILogger<ReportsController> Logger { get; set; }
        public ReportsController Subject { get; }
    }
}