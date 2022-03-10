using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SearchResults.Exporters
{
    public class SearchResultsExportFacts : FactBase
    {
        [Fact]
        public async Task SearchResultsExport()
        {
            var f = new SearchResultsExportFixture();
            var titleFixture = Fixture.String("Case Title");

            var searchExportRequest = new ExportRequest
            {
                ExportFormat = ReportExportFormat.Excel,
                SearchPresentation = new SearchPresentation(),
                Rows = new List<Dictionary<string, object>>
                {
                    new Dictionary<string, object>
                    {
                        {"CaseReference_11", "1234/a"}, {"RowKey", 1}, {"Integer_22", "10"}
                    }
                },
                Columns = new List<Column>
                {
                    new Column("CaseReference_11", "Case Ref.", "String"),
                    new Column("Integer_22", "Days", "Integer")
                }
            };

            var settings = new SearchResultsSettings
                    {
                        ApplicationName = string.Empty,
                        Author = "Abc",
                        Culture = new System.Globalization.CultureInfo("en-GB"),
                        LayoutSettings = new ExportConfig
                        {
                            Excel = new ExportConfig.ExcelConfig
                            {
                                TitleColor = "#FFFFFF",
                                TitleBackgroundColor = "#FFFFFF",
                                RowBackgroundColor = "#FFFFFF",
                                RowAlternateBackgroundColor = "#FFFFFF",
                                ColumnHeaderBackgroundColor = "#FFFFFF",
                                BorderColor = "#FFFFFF",
                                ImageMaxDimension = "48X48"
                            }
                        },
                        DateFormat = "dd-MMM-yyyy",
                        TimeFormat = "HH:mm:ss",
                        FontSettings = new Dictionary<ReportExportFormat, FontSetting>
                                        {
                                            {
                                                ReportExportFormat.Excel, new FontSetting
                                                {
                                                    FontSize = 8,
                                                    FontFamily = "Arial"
                                                }
                                            }
                                        },
                        Warnings = new Dictionary<string, string>
                        {
                            {"RowsTruncatedWarning", "Warning for truncated rows"},
                            {"ColumnsTruncatedWarning", "Warning for truncated columns"}
                        },
                        ReportTitle = titleFixture,
                        ReportFileName = titleFixture.Replace(" ", string.Empty)
                    };

            var r = await f.Subject.Export(searchExportRequest, settings);

            f.ImageSettings.Received(1).Load(searchExportRequest.SearchPresentation, searchExportRequest.Rows);

            Assert.Equal(titleFixture.Replace(" ", string.Empty) + ".xlsx", r.FileName);
            Assert.Equal("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", r.ContentType);
            Assert.NotNull(r.Content);
        }

        public class SearchResultsExportFixture : IFixture<ISearchResultsExport>
        {
            public SearchResultsExportFixture()
            {  
                ImageSettings = Substitute.For<IImageSettings>();
                UserColumnUrlResolver = Substitute.For<IUserColumnUrlResolver>();

                Subject = new SearchResultsExport(ImageSettings, UserColumnUrlResolver);
            }
            
            public IImageSettings ImageSettings { get; }
            public IUserColumnUrlResolver UserColumnUrlResolver { get; }
            public ISearchResultsExport Subject { get; }
        }
    }
}
