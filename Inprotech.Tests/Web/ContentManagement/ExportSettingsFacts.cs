using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;
using QueryContext = Inprotech.Infrastructure.Web.QueryContext;

namespace Inprotech.Tests.Web.ContentManagement
{
     public class ExportSettingsLoaderFacts
    {
        public class ExportSettingsLoaderFixture : IFixture<ExportSettingsLoader>
        {
            public ISecurityContext SecurityContext { get; set; }
            public ISiteDateFormat SiteDateFormat { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ISiteControlReader SiteControlReader { get; set; }
            public IExportHelperService ExportHelperService { get; set; }
            public IStaticTranslator StaticTranslator { get; set; }

            public ExportSettingsLoaderFixture()
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SiteDateFormat = Substitute.For<ISiteDateFormat>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                ExportHelperService = Substitute.For<IExportHelperService>();
                StaticTranslator = Substitute.For<IStaticTranslator>();

                Subject = new ExportSettingsLoader(SecurityContext, SiteDateFormat, PreferredCultureResolver, SiteControlReader, ExportHelperService, StaticTranslator);
            }
            public ExportSettingsLoader Subject { get; }
        }

        public class GetExportLimitMethod : FactBase
        {
            public const int MaxRowsForExcel = 65536;

            [Fact]
            public void GetsTheExportLimitFromTheSiteControl()
            {
                var j = new ExportSettingsLoaderFixture();
                j.SiteControlReader.Read<int?>(SiteControls.ExportLimit)
                 .Returns(1000);

                var r = j.Subject.GetExportLimitorDefault(ReportExportFormat.Excel);

                Assert.Equal(1000, r);
            }

            [Fact]
            public void GetsMaxExcelExportLimitIfSiteControlReturnsNull()
            {
                var j = new ExportSettingsLoaderFixture();
                j.SiteControlReader.Read<int?>(SiteControls.ExportLimit)
                 .Returns((int?)null);

                var r = j.Subject.GetExportLimitorDefault(ReportExportFormat.Excel);

                Assert.Equal(MaxRowsForExcel, r);
            }

            [Fact]
            public void GetsMaxExcelExportLimitIfSiteControlReturnsLargeValue()
            {
                var j = new ExportSettingsLoaderFixture();
                j.SiteControlReader.Read<int?>(SiteControls.ExportLimit)
                 .Returns(100000);

                var r = j.Subject.GetExportLimitorDefault(ReportExportFormat.Excel);

                Assert.Equal(MaxRowsForExcel, r);
            }
        }

        public class LoadMethod : FactBase
        {
            [Fact]
            public void LoadExportSettings()
            {
                var j = new ExportSettingsLoaderFixture();
                var dateFormat = Fixture.String();
                var userName = Fixture.String();
                var fName = Fixture.String();
                var lName = Fixture.String();

                j.SecurityContext.User.Returns(new UserBuilder(Db) {UserName = userName, Name = new NameBuilder(Db) {FirstName = fName, LastName = lName}.Build()}.Build());
                j.SiteDateFormat.Resolve().ReturnsForAnyArgs(dateFormat);
                j.PreferredCultureResolver.Resolve().Returns("en");
                j.StaticTranslator.Translate("searchResults.warning.truncatedRows", Arg.Any<IEnumerable<string>>()).Returns("Truncated Warning for rows");
                j.StaticTranslator.Translate("searchResults.warning.truncatedColumns", Arg.Any<IEnumerable<string>>()).Returns("Truncated Warning for columns");
                j.ExportHelperService.LayoutSettings.Returns(new ExportConfig
                {
                    Pdf = new ExportConfig.PdfConfig
                    {
                        TitleColor = "#FFFFFF",
                        TitleBackgroundColor = "#FFFFFF",
                        RowBackgroundColor = "#FFFFFF",
                        RowAlternateBackgroundColor = "#FFFFFF",
                        ColumnHeaderBackgroundColor = "#FFFFFF",
                        BorderColor = "#FFFFFF",
                        CompanyLogo = Fixture.String(),
                        IconCheckboxChecked = Fixture.String(),
                        IconCheckboxUnchecked = Fixture.String()
                    },
                    Word = new ExportConfig.WordConfig
                    {
                        TitleColor = "#FFFFFF",
                        TitleBackgroundColor = "#FFFFFF",
                        RowBackgroundColor = "#FFFFFF",
                        RowAlternateBackgroundColor = "#FFFFFF",
                        ColumnHeaderBackgroundColor = "#FFFFFF",
                        BorderColor = "#FFFFFF",
                        CompanyLogo = Fixture.String()
                    }
                });

                var r = j.Subject.Load(Fixture.String(), QueryContext.CaseSearch);

                Assert.Equal(KnownGlobalSettings.ApplicationName, r.ApplicationName);
                Assert.Equal("en", r.Culture.Name);
                Assert.Equal($"{lName}, {fName}", r.Author);
                Assert.Equal(dateFormat, r.DateFormat);
                Assert.Equal("Truncated Warning for rows", r.Warnings["RowsTruncatedWarning"]);
                Assert.Equal("Truncated Warning for columns", r.Warnings["ColumnsTruncatedWarning"]);
                Assert.Equal("Arial", r.FontSettings[ReportExportFormat.Excel].FontFamily);
                Assert.Equal(8, r.FontSettings[ReportExportFormat.Excel].FontSize);
            }
        }
    }
}
