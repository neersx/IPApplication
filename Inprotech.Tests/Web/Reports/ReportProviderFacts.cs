using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Reports;
using InprotechKaizen.Model.Components.Integration.ReportingServices;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using NSubstitute.ReturnsExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Reports
{
    public class ReportProviderFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnProviderGetReportProviderInfo()
        {
            var f = new ReportProviderFixture(Db);
            f.ReportingServicesSettingsResolver.Resolve().Returns(new ReportingServicesSetting
            {
                ReportServerBaseUrl = "http://localhost/reportserver",
                RootFolder = "inprotech"
            });

            SetupData(ReportProviderType.MsReportingServices);
            var results = await f.Subject.GetReportProviderInfo();

            Assert.Equal(ReportProviderType.MsReportingServices.ToString(), results.Name);
            Assert.Equal(ReportProviderType.MsReportingServices, results.Provider);
            Assert.Equal(ReportExportFormat.Pdf, results.DefaultExportFormat);
            Assert.Equal(5, results.ExportFormats.Count());
            Assert.Equal(ReportExportFormat.Csv, results.ExportFormats.First().ExportFormatKey);
            Assert.Equal(ReportExportFormat.Word, results.ExportFormats.Last().ExportFormatKey);
        }

        [Fact]
        public async Task ShouldReturnDefaultProviderGetDefaultProviderInfo()
        {
            var f = new ReportProviderFixture(Db);
            SetupData((int) ReportProviderType.Default);

            var results = await f.Subject.GetDefaultProviderInfo();

            Assert.Equal(ReportProviderType.Default.ToString(), results.Name);
            Assert.Equal(ReportProviderType.Default, results.Provider);
            Assert.Equal(ReportExportFormat.Pdf, results.DefaultExportFormat);
            Assert.Equal(5, results.ExportFormats.Count());
            Assert.Equal(ReportExportFormat.Csv, results.ExportFormats.First().ExportFormatKey);
            Assert.Equal(ReportExportFormat.Xml, results.ExportFormats.Last().ExportFormatKey);
        }

        void SetupData(ReportProviderType reportType)
        {
            var reportToolKey = reportType == ReportProviderType.Default ? null : (int?) reportType;

            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Csv, TableType = (short) TableTypes.EntitySize, Description = ReportExportFormat.Csv.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Excel, TableType = (short) TableTypes.EntitySize, Description = ReportExportFormat.Excel.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Mhtml, TableType = (short) TableTypes.AccountType, Description = ReportExportFormat.Mhtml.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Pdf, TableType = (short) TableTypes.AccountType, Description = ReportExportFormat.Pdf.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Xml, TableType = (short) TableTypes.AccountType, Description = ReportExportFormat.Xml.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Word, TableType = (short) TableTypes.AccountType, Description = ReportExportFormat.Word.ToString()}.Build().In(Db);
            new TableCodeBuilder {TableCode = (int) ReportExportFormat.Qrp, TableType = (short) TableTypes.AccountType, Description = ReportExportFormat.Qrp.ToString()}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Csv, ReportTool = reportToolKey, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Excel, ReportTool = reportToolKey, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Mhtml, ReportTool = reportToolKey, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Pdf, ReportTool = reportToolKey, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Xml, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Word, ReportTool = (int) ReportProviderType.MsReportingServices, UsedByWorkbench = true}.Build().In(Db);
            new ReportToolExportFormatBuilder {ExportFormat = (int) ReportExportFormat.Qrp, ReportTool = (int) ReportProviderType.MsReportingServices, UsedByWorkbench = false}.Build().In(Db);
        }

        [Fact]
        public async Task ShouldReturnNullGetReportProviderInfo()
        {
            var f = new ReportProviderFixture(Db);
            f.ReportingServicesSettingsResolver.Resolve().ReturnsNull();
            var result = await f.Subject.GetReportProviderInfo();
            Assert.Null(result);
        }
    }

    public class ReportProviderFixture : IFixture<ReportProvider>
    {
        public ReportProviderFixture(InMemoryDbContext db)
        {
            ReportingServicesSettingsResolver = Substitute.For<IReportingServicesSettingsResolver>();
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new ReportProvider(db, preferredCultureResolver, ReportingServicesSettingsResolver);
        }

        public IReportingServicesSettingsResolver ReportingServicesSettingsResolver { get; set; }
        
        public ReportProvider Subject { get; }
    }
}