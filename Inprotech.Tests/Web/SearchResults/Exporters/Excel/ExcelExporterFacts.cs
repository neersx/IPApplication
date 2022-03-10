using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using Aspose.Cells;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using NSubstitute;
using Xunit;
using ExportColumn = Inprotech.Infrastructure.SearchResults.Exporters.Column;
using FontSetting = Inprotech.Infrastructure.SearchResults.Exporters.FontSetting;

namespace Inprotech.Tests.Web.SearchResults.Exporters.Excel
{
    public class ExcelExporterFacts
    {
        readonly IImageSettings _imageSettings = Substitute.For<IImageSettings>();
        readonly IUserColumnUrlResolver _userColumnUrlResolver = Substitute.For<IUserColumnUrlResolver>();
        static DateTime DateTime => new DateTime(2013, 12, 2, 22, 11, 30);

        SearchResultsSettings SearchResultsSettings()
        {
            var layoutSettings = new ExportConfig
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
            };

            var exportSettings = new SearchResultsSettings
            {
                ApplicationName = string.Empty,
                Author = "Abc",
                Culture = new CultureInfo("en-GB"),
                LayoutSettings = layoutSettings,
                DateFormat = "dd-MMM-yyyy",
                ReportFileName = "CaseList",
                ReportTitle = "CaseList",
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
                MaxColumnsForExport = 255
            };

            return exportSettings;
        }

        Inprotech.Infrastructure.SearchResults.Exporters.SearchResults SearchResults()
        {
            var columns = new List<ExportColumn>
            {
                new ExportColumn("CaseReference_11", "Case Ref.", "String"),
                new ExportColumn("Integer_22", "Days", "Integer"),
                new ExportColumn("Date_33", "Today", "Date"),
                new ExportColumn("Time_44", "Time", "Time"),
                new ExportColumn("Currency_55", "Amount", "Currency"),
                new ExportColumn("Percentage_66", "Percent", "Percentage"),
                new ExportColumn("DateTime_77", "Date & Time", "Date/Time"),
                new ExportColumn("FormattedText_77", "Formatted Text", "Formatted Text"),
                new ExportColumn("UserColumnUrl_Url", "Display URL", "Url"),
                new ExportColumn("UserColumnUrl_Name", "Display Name", "Url")
            };

            var rows = new List<Dictionary<string, object>>();
            var first = new Dictionary<string, object>
            {
                {"CaseReference_11", "1234/a"}, {"RowKey", 1}, {"Integer_22", "10"},
                {"Date_33", DateTime}, {"Time_44", DateTime}, {"Currency_55", "100"},
                {"Percentage_66", "90"}, {"DateTime_77", DateTime}, {"FormattedText_77", "<b>Formatted</b>"},
                {"UserColumnUrl_Url", "www.google.com"}, {"UserColumnUrl_Name", "[Case 123/ A link|www.google.com]"}
            };
            rows.Add(first);

            var second = new Dictionary<string, object>
            {
                {"CaseReference_11", "1234/b"}, {"RowKey", 2}, {"Integer_22", "20"},
                {"Date_33", DateTime}, {"Time_44", DateTime}, {"Currency_55", "90"},
                {"Percentage_66", "90"}, {"DateTime_77", DateTime}
            };
            rows.Add(second);

            var searchResults = new Inprotech.Infrastructure.SearchResults.Exporters.SearchResults
            {
                Columns = columns,
                Rows = rows
            };

            return searchResults;
        }

        [Theory]
        [InlineData("=1234", true)]
        [InlineData("+1234", true)]
        [InlineData("-1234", true)]
        [InlineData("@1234", true)]
        [InlineData("1234=+-@", false)]
        public void ShouldSanitizeDataBeforeExport(string caseRef, bool isSanitized)
        {
            var columns = new List<ExportColumn>
            {
                new ExportColumn("CaseReference", "Case Ref.", "String"),
                new ExportColumn("Currency", "Amount", "Currency")
            };
            var rows = new List<Dictionary<string, object>>();
            var first = new Dictionary<string, object>
            {
                {"CaseReference", caseRef},
                {"Currency", "+300"}
            };
            rows.Add(first);

            var searchResults = new Inprotech.Infrastructure.SearchResults.Exporters.SearchResults
            {
                Columns = columns,
                Rows = rows
            };

            var output = new MemoryStream();

            new ExcelExport(SearchResultsSettings(), searchResults, _imageSettings, _userColumnUrlResolver).Execute(output);

            var firstWorksheet = new Workbook(output).Worksheets[0];

            Assert.Equal(firstWorksheet.Cells[3, 0].Value.ToString().StartsWith("'"), isSanitized);
            Assert.Equal("+300", firstWorksheet.Cells[3, 1].Value);
        }

        [Fact]
        public void ShouldAddAdditionalInfoInExport()
        {
            var output = new MemoryStream();
            var exportData = SearchResults();
            exportData.AdditionalInfo = new ExportAdditionalInfo
            {
                SearchBelongingTo = "Abc"
            };
            _userColumnUrlResolver.Resolve(Arg.Any<string>()).Returns(new UserColumnUrl {DisplayText = string.Empty, Url = "www.google.com"});
            new ExcelExport(SearchResultsSettings(), exportData, _imageSettings, _userColumnUrlResolver).Execute(output);
            var firstWorksheet = new Workbook(output).Worksheets[0];

            Assert.Equal("Abc", firstWorksheet.Cells[3, 0].Value);
        }

        [Fact]
        public void ShouldAddExportLimitMessageForTruncatedColumns()
        {
            var output = new MemoryStream();
            var settings = SearchResultsSettings();

            settings.MaxColumnsForExport = 7;
            settings.Warnings = new Dictionary<string, string>
            {
                {
                    "ColumnsTruncatedWarning",
                    "The search results include a large number of columns. Only the first {0} columns will be exported."
                }
            };

            new ExcelExport(settings, SearchResults(), _imageSettings, _userColumnUrlResolver).Execute(output);

            var firstWorksheet = new Workbook(output).Worksheets[0];

            Assert.Equal("CaseList", firstWorksheet.Cells[1, 0].Value);
            Assert.Equal("The search results include a large number of columns. Only the first 7 columns will be exported.", firstWorksheet.Cells[2, 0].Value);
        }

        [Fact]
        public void ShouldAddExportLimitMessageForTruncatedRows()
        {
            var output = new MemoryStream();
            var settings = SearchResultsSettings();
            settings.ExportLimitedToNbRecords = 1;
            settings.Warnings = new Dictionary<string, string>
            {
                {
                    "RowsTruncatedWarning",
                    "This is a large search result.  Only the first {0} rows will be exported."
                }
            };
            _userColumnUrlResolver.Resolve(Arg.Any<string>()).Returns(new UserColumnUrl {DisplayText = string.Empty, Url = "www.google.com"});
            new ExcelExport(settings, SearchResults(), _imageSettings, _userColumnUrlResolver).Execute(output);
            var firstWorksheet = new Workbook(output).Worksheets[0];

            Assert.Equal("CaseList", firstWorksheet.Cells[1, 0].Value);
            Assert.Equal("This is a large search result.  Only the first 1 rows will be exported.", firstWorksheet.Cells[2, 0].Value);
        }

        [Fact]
        public void ShouldExportDataInOrderReturned()
        {
            var output = new MemoryStream();
            _userColumnUrlResolver.Resolve(Arg.Any<string>()).Returns(new UserColumnUrl {DisplayText = string.Empty, Url = "www.google.com"});
            new ExcelExport(SearchResultsSettings(), SearchResults(), _imageSettings, _userColumnUrlResolver).Execute(output);

            var firstWorksheet = new Workbook(output).Worksheets[0];

            Assert.Equal("CaseList", firstWorksheet.Cells[1, 0].Value);
            Assert.Equal("Case Ref.", firstWorksheet.Cells[2, 0].Value);
            Assert.Equal("Days", firstWorksheet.Cells[2, 1].Value);
            Assert.Equal("Today", firstWorksheet.Cells[2, 2].Value);
            Assert.Equal("Time", firstWorksheet.Cells[2, 3].Value);
            Assert.Equal("Amount", firstWorksheet.Cells[2, 4].Value);
            Assert.Equal("Percent", firstWorksheet.Cells[2, 5].Value);
            Assert.Equal("Date & Time", firstWorksheet.Cells[2, 6].Value);
            Assert.Equal("Formatted Text", firstWorksheet.Cells[2, 7].Value);
            Assert.Equal("Display URL", firstWorksheet.Cells[2, 8].Value);

            Assert.Equal("1234/a", firstWorksheet.Cells[3, 0].Value);
            Assert.Equal("10", firstWorksheet.Cells[3, 1].Value);
            Assert.Equal("02-Dec-2013", firstWorksheet.Cells[3, 2].StringValue);
            Assert.Equal("22:11:30", firstWorksheet.Cells[3, 3].StringValue);
            Assert.Equal("100", firstWorksheet.Cells[3, 4].Value);
            Assert.Equal("90", firstWorksheet.Cells[3, 5].Value);
            Assert.Equal("02-Dec-2013 22:11:30", firstWorksheet.Cells[3, 6].StringValue);
            Assert.Equal("Formatted", firstWorksheet.Cells[3, 7].StringValue);
            Assert.Equal("www.google.com", firstWorksheet.Cells[3, 8].StringValue);
        }
    }
}