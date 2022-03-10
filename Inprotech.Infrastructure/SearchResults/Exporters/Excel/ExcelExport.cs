using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Aspose.Cells;
using Aspose.Cells.Drawing;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Excel
{
    internal sealed class ExcelExport : Export
    {
        public ExcelExport(SearchResultsSettings settings, SearchResults exportData, IImageSettings imageSettings, IUserColumnUrlResolver userColumnUrlResolver)
            : base(settings, exportData, imageSettings, userColumnUrlResolver)
        {
        }

        public override string ContentType => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

        public override string FileNameExtension => "xlsx";

        public override OpenType OpenType => OpenType.Inline;

        public override void Execute(Stream stream)
        {
            var exportSection = Settings.LayoutSettings;

            var imageDimensions = ExportUtils.GetImageDimensions(exportSection.Excel.ImageMaxDimension);
            var maxImageHeight = imageDimensions.Height;
            var maxImageWidth = imageDimensions.Width;

            if (exportSection.Excel.ImageReSizeMode == ExportConfig.ExcelConfig.ReSizeMode.NoResize)
            {
                maxImageHeight = 0;
                maxImageWidth = 0;
            }

            var culture = Settings.Culture;
            var dateFormat = Settings.DateFormat;
            var timeFormat = Settings.TimeFormat;

            if (timeFormat.IndexOf("tt", StringComparison.Ordinal) > 0)
            {
                timeFormat = timeFormat.Substring(0, timeFormat.IndexOf("tt", StringComparison.Ordinal));
                timeFormat = timeFormat + culture.DateTimeFormat.AMDesignator + "/" + culture.DateTimeFormat.PMDesignator;
            }
            else if (timeFormat.IndexOf("t", StringComparison.Ordinal) > 0)
            {
                timeFormat = timeFormat.Replace("t", culture.DateTimeFormat.AMDesignator);
            }

            var dateTimeFormat = $"{dateFormat} {timeFormat}";
            var numberFormat = CultureInfo.CreateSpecificCulture(culture.ToString()).NumberFormat;

            var workbook = new Workbook();
            workbook.Worksheets.Clear();

            workbook.Worksheets.BuiltInDocumentProperties.NameOfApplication = Settings.ApplicationName;
            workbook.Worksheets.BuiltInDocumentProperties.Author = Settings.Author;
            workbook.Worksheets.BuiltInDocumentProperties.Title = Settings.WorksheetTitle();

            workbook.Worksheets.Add();

            var sheet = workbook.Worksheets[0];
            sheet.ResolveName(Settings.ReportTitle);

            sheet.PageSetup.Orientation = exportSection.Excel.PageOrientation == ExportConfig.ExcelConfig.PageOrientationType.Landscape ? PageOrientationType.Landscape : PageOrientationType.Portrait;
            sheet.PageSetup.PaperSize = PaperSizeConvertor.ForExcel(exportSection.Excel.PaperSize);
            sheet.PageSetup.Zoom = 100;

            var titleColor = ColorTranslator.FromHtml(exportSection.Excel.TitleColor);
            var titleBgColor = ColorTranslator.FromHtml(exportSection.Excel.TitleBackgroundColor);
            var rowBgColor = ColorTranslator.FromHtml(exportSection.Excel.RowBackgroundColor);
            var rowAlternateBgColor = ColorTranslator.FromHtml(exportSection.Excel.RowAlternateBackgroundColor);
            var columnHeaderBgColor = ColorTranslator.FromHtml(exportSection.Excel.ColumnHeaderBackgroundColor);
            var borderColor = ColorTranslator.FromHtml(exportSection.Excel.BorderColor);
            workbook.ChangePalette(titleColor, 55);
            workbook.ChangePalette(titleBgColor, 54);
            workbook.ChangePalette(rowBgColor, 53);
            workbook.ChangePalette(rowAlternateBgColor, 52);
            workbook.ChangePalette(borderColor, 51);

            var fontSettings = Settings.FontSettings[ReportExportFormat.Excel];

            #region styles

            var titleStyle = workbook.Styles[workbook.Styles.Add()];
            titleStyle.Name = "TitleStyle";
            titleStyle.Font.IsBold = true;
            titleStyle.Font.Name = fontSettings.FontFamily;
            titleStyle.Font.Size = (int) fontSettings.FontSize + 2;
            titleStyle.Font.Color = titleColor;
            titleStyle.ForegroundColor = titleBgColor;
            titleStyle.VerticalAlignment = TextAlignmentType.Center;
            titleStyle.HorizontalAlignment = TextAlignmentType.Left;

            var columnHeaderStyle = workbook.Styles[workbook.Styles.Add()];
            columnHeaderStyle.Name = "ColumnHeaderStyle";
            columnHeaderStyle.Font.IsBold = true;
            columnHeaderStyle.Font.Name = fontSettings.FontFamily;
            columnHeaderStyle.Font.Size = (int) fontSettings.FontSize + 1;
            columnHeaderStyle.Font.Color = titleColor;
            columnHeaderStyle.ForegroundColor = columnHeaderBgColor;
            columnHeaderStyle.Pattern = BackgroundType.Solid;
            columnHeaderStyle.VerticalAlignment = TextAlignmentType.Center;
            columnHeaderStyle.Borders[BorderType.TopBorder].Color = borderColor;
            columnHeaderStyle.Borders[BorderType.RightBorder].Color = borderColor;
            columnHeaderStyle.Borders[BorderType.BottomBorder].Color = borderColor;
            columnHeaderStyle.Borders[BorderType.LeftBorder].Color = borderColor;
            columnHeaderStyle.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
            columnHeaderStyle.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
            columnHeaderStyle.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
            columnHeaderStyle.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;

            var cellStyle = workbook.Styles[workbook.Styles.Add()];
            cellStyle.Name = "CellStyle";
            cellStyle.Font.Name = fontSettings.FontFamily;
            cellStyle.Font.Size = (int) fontSettings.FontSize;
            cellStyle.Pattern = BackgroundType.Solid;
            cellStyle.VerticalAlignment = TextAlignmentType.Center;
            cellStyle.Borders[BorderType.TopBorder].Color = borderColor;
            cellStyle.Borders[BorderType.RightBorder].Color = borderColor;
            cellStyle.Borders[BorderType.BottomBorder].Color = borderColor;
            cellStyle.Borders[BorderType.LeftBorder].Color = borderColor;
            cellStyle.Borders[BorderType.TopBorder].LineStyle = CellBorderType.Thin;
            cellStyle.Borders[BorderType.RightBorder].LineStyle = CellBorderType.Thin;
            cellStyle.Borders[BorderType.BottomBorder].LineStyle = CellBorderType.Thin;
            cellStyle.Borders[BorderType.LeftBorder].LineStyle = CellBorderType.Thin;

            #endregion

            var rowIndex = 1;
            var colIndex = 0;
            var cells = sheet.Cells;
            cells.StandardWidth = 16;

            #region ReportTitle

            if (!string.IsNullOrEmpty(Settings.ReportTitle))
            {
                cells.Merge(rowIndex, 0, 1, ExportData.Columns.Count());
                cells[rowIndex, 0].PutValue(Settings.ReportTitle);
                cells[rowIndex, 0].SetStyle(titleStyle);
                rowIndex++;
            }

            #endregion

            #region Columns/Rows truncate warnings

            if (ExportData.Columns.Count() > Settings.MaxColumnsForExport)
            {
                TruncateWarnings(cells, rowIndex, titleStyle, fontSettings, true);
                rowIndex++;
            }

            if (Settings.ExportLimitedToNbRecords.HasValue)
            {
                TruncateWarnings(cells, rowIndex, titleStyle, fontSettings);
                rowIndex++;
            }

            #endregion

            #region Report Additional Info

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchBelongingTo))
            {
                rowIndex++;
                cells[rowIndex, 0].PutValue(ExportData.AdditionalInfo.SearchBelongingTo);
                cells[rowIndex, 0].SetStyle(titleStyle);
                rowIndex++;
            }

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchDateRange))
            {
                cells[rowIndex, 0].PutValue(ExportData.AdditionalInfo.SearchDateRange);
                cells[rowIndex, 0].SetStyle(titleStyle);
                rowIndex++;
                rowIndex++;
            }

            #endregion

            #region Column Headers

            cells.SetRowHeight(rowIndex, 18);
            foreach (var column in ExportData.Columns)
            {
                cells[rowIndex, colIndex].PutValue(column.Title);

                switch (column.Format)
                {
                    case ColumnFormats.Time:
                    case ColumnFormats.Date:
                    case ColumnFormats.DateTime:
                    case ColumnFormats.Boolean:
                    case ColumnFormats.Hours:
                    case ColumnFormats.HoursWithSeconds:
                    case ColumnFormats.HoursWithMinutes:
                        columnHeaderStyle.HorizontalAlignment = TextAlignmentType.Center;
                        break;
                    case ColumnFormats.Currency:
                    case ColumnFormats.LocalCurrency:
                    case ColumnFormats.Decimal:
                    case ColumnFormats.Percentage:
                    case ColumnFormats.Integer:
                        columnHeaderStyle.HorizontalAlignment = TextAlignmentType.Right;
                        break;
                    default:
                        columnHeaderStyle.HorizontalAlignment = TextAlignmentType.Left;
                        break;
                }

                cells[rowIndex, colIndex].SetStyle(columnHeaderStyle, true);
                colIndex++;
            }

            rowIndex++;

            #endregion

            #region Rows

            var useStdStyle = false;
            int? minColumnWidth = null;
            var mustResizeColumnWidth = false;
            foreach (var row in ExportData.Rows)
            {
                int? minRowHeight = null;
                var mustResizeRowHeight = false;
                useStdStyle = !useStdStyle;
                var values = row;
                colIndex = 0;

                foreach (var column in ExportData.Columns)
                {
                    cellStyle.IsTextWrapped = false;
                    cellStyle.Custom = string.Empty;
                    object value = null;
                    cellStyle.Font.Color = Color.Black;
                    cellStyle.Font.Underline = FontUnderlineType.None;
                    cellStyle.IsTextWrapped = false;
                    cellStyle.Font.IsBold = false;
                    if (values.ContainsKey(column.Name))
                    {
                        value = values[column.Name];
                        var isConverted = false;

                        if (!isConverted)
                        {
                            switch (column.Format)
                            {
                                case ColumnFormats.Time:
                                    if (value != null)
                                    {
                                        value = Convert.ToDateTime(((DateTime) value).ToString(timeFormat));
                                    }

                                    cellStyle.Number = (int) CellDisplayFormat.Time;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.Url:
                                    if (value != null)
                                    {
                                        cellStyle.Font.Color = Color.Blue;
                                        cellStyle.Font.Underline = FontUnderlineType.Single;
                                        cellStyle.IsTextWrapped = true;
                                        CreateHyperlink(sheet, rowIndex, colIndex, value);
                                        value = null;
                                    }

                                    break;
                                case ColumnFormats.Date:
                                    if (value != null)
                                    {
                                        if (DateTime.TryParse(Convert.ToDateTime(value).ToString(dateFormat), out var formattedDate))
                                        {
                                            value = formattedDate;
                                        } 
                                    }

                                    cellStyle.Number = (int) CellDisplayFormat.DateTime;
                                    cellStyle.Custom = dateFormat;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    if (column.ColumnItemId == "DueDate"
                                            || column.ColumnItemId == "ReminderDate")
                                    {
                                        if (values.ContainsKey("IsDueDateToday") && (bool)values["IsDueDateToday"])
                                        {
                                            cellStyle.Font.IsBold = true;
                                        }
                                        if (values.ContainsKey("IsDueDatePast") && (bool)values["IsDueDatePast"])
                                        {
                                            cellStyle.Font.IsBold = true;
                                            cellStyle.Font.Color = Color.Red;
                                        }
                                    }
                                    break;
                                case ColumnFormats.DateTime:
                                    value = (DateTime?) value;
                                    cellStyle.Number = (int) CellDisplayFormat.DateTime;
                                    cellStyle.Custom = dateTimeFormat;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.Hours:
                                    if (value != null)
                                    {
                                        value = new MinutesConverter().Convert(value);
                                    }

                                    cellStyle.Number = (int) CellDisplayFormat.Hours;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.HoursWithSeconds:
                                    if (value != null)
                                    {
                                        value = new SecondsConverter().Convert(value);
                                    }

                                    cellStyle.Number = (int) CellDisplayFormat.Hours;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.HoursWithMinutes:
                                    if (value != null)
                                    {
                                        value = new SecondsConverter().Convert(value, false);
                                    }

                                    cellStyle.Number = (int) CellDisplayFormat.Hours;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.Currency:
                                case ColumnFormats.LocalCurrency:
                                    cellStyle.Number = (int) CellDisplayFormat.General;
                                    if (value != null)
                                    {
                                        var currencySymbol = string.Empty;
                                        if (!string.IsNullOrEmpty(column.CurrencyCodeColumnName))
                                        {
                                            if (values.ContainsKey(column.CurrencyCodeColumnName) && values[column.CurrencyCodeColumnName] != null)
                                            {
                                                currencySymbol = (string) values[column.CurrencyCodeColumnName];
                                            }
                                        }

                                        if (string.IsNullOrEmpty(currencySymbol) && !string.IsNullOrWhiteSpace(Settings.LocalCurrencyCode))
                                            currencySymbol = Settings.LocalCurrencyCode;

                                        numberFormat.CurrencySymbol = currencySymbol;
                                        if (!string.IsNullOrEmpty(currencySymbol))
                                        {
                                            cellStyle.Number = 8;
                                            cellStyle.Custom = string.Format("\"{0}\" #{1}##0{2}00_);[Red](\"{0}\" #{1}##0{2}00)", currencySymbol, numberFormat.CurrencyGroupSeparator, numberFormat.CurrencyDecimalSeparator);
                                        }
                                        else
                                        {
                                            cellStyle.Number = 40;
                                        }
                                    }

                                    cellStyle.HorizontalAlignment = TextAlignmentType.Right;
                                    break;
                                case ColumnFormats.Boolean:
                                    cellStyle.Number = (int) CellDisplayFormat.General;
                                    var checkBoxIdx = sheet.CheckBoxes.Add(rowIndex, colIndex, 13, 13);
                                    sheet.CheckBoxes[checkBoxIdx].CheckedValue = value != null && (bool) value ? CheckValueType.Checked : CheckValueType.UnChecked;
                                    value = null;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                case ColumnFormats.Decimal:
                                    cellStyle.Number = (int) CellDisplayFormat.Decimal;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Right;
                                    break;
                                case ColumnFormats.Percentage:
                                    cellStyle.Number = (int) CellDisplayFormat.Percentage;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Right;
                                    break;
                                case ColumnFormats.Integer:
                                    cellStyle.Number = (int) CellDisplayFormat.Integer;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Right;
                                    break;
                                case ColumnFormats.ImageKey:
                                    cellStyle.Number = (int) CellDisplayFormat.General;
                                    if (value != null)
                                    {
                                        var imageData = ImageSettings.FindImageByKey(Convert.ToInt32(value));
                                        if (imageData != null)
                                        {
                                            var imageHeight = maxImageHeight;
                                            var imageWidth = maxImageWidth;
                                            Image image;
                                            if (exportSection.CompressImage)
                                            {
                                                image = ExportUtils.ResizeImage(imageData.Data, imageWidth,
                                                                                imageHeight);
                                                if (image != null)
                                                {
                                                    imageHeight = image.Height;
                                                    imageWidth = image.Width;
                                                }
                                            }
                                            else
                                            {
                                                using (var imageStream = new MemoryStream(imageData.Data))
                                                {
                                                    image = Image.FromStream(imageStream);
                                                    ExportUtils.MaintainAspectRatio(ref imageWidth, ref imageHeight, image);
                                                }
                                            }

                                            if (image != null)
                                            {
                                                if (!minRowHeight.HasValue)
                                                {
                                                    minRowHeight = imageHeight + 4;
                                                    mustResizeRowHeight = true;
                                                }
                                                else
                                                {
                                                    if (minRowHeight < imageHeight + 4)
                                                    {
                                                        minRowHeight = imageHeight + 4;
                                                        mustResizeRowHeight = true;
                                                    }
                                                }

                                                if (!minColumnWidth.HasValue)
                                                {
                                                    minColumnWidth = imageWidth + 4;
                                                    mustResizeColumnWidth = true;
                                                }
                                                else
                                                {
                                                    if (minColumnWidth < imageWidth + 4)
                                                    {
                                                        minColumnWidth = imageWidth + 4;
                                                        mustResizeColumnWidth = true;
                                                    }
                                                }

                                                using (var imageStream = new MemoryStream())
                                                {
                                                    image.Save(imageStream, ImageFormat.Png);
                                                    var pictureIndex = sheet.Pictures.Add(rowIndex, colIndex, imageStream);
                                                    sheet.Pictures[pictureIndex].Placement = PlacementType.Move;
                                                    if (!exportSection.CompressImage)
                                                    {
                                                        sheet.Pictures[pictureIndex].Height = imageHeight;
                                                        sheet.Pictures[pictureIndex].Width = imageWidth;
                                                    }

                                                    if (!(maxImageWidth == 0 || maxImageWidth == 0 || exportSection.Excel.ImageReSizeMode == ExportConfig.ExcelConfig.ReSizeMode.NoResize))
                                                    {
                                                        sheet.Pictures[pictureIndex].UpperDeltaX = 2;
                                                        sheet.Pictures[pictureIndex].UpperDeltaY = 2;
                                                        sheet.Pictures[pictureIndex].Top = 2;
                                                        sheet.Pictures[pictureIndex].Left = 2;
                                                    }
                                                }

                                                image.Dispose();
                                            }

                                            value = null;
                                        }
                                    }

                                    cellStyle.HorizontalAlignment = TextAlignmentType.Center;
                                    break;
                                default:
                                    cellStyle.Number = (int) CellDisplayFormat.General;
                                    cellStyle.HorizontalAlignment = TextAlignmentType.Left;
                                    cellStyle.IsTextWrapped = true;
                                    break;
                            }
                        }
                    }

                    if (mustResizeRowHeight && minRowHeight.HasValue)
                    {
                        cells.SetRowHeightPixel(rowIndex, minRowHeight.Value);
                    }

                    if (mustResizeColumnWidth && minColumnWidth.HasValue && column.Format == ColumnFormats.ImageKey)
                    {
                        cells.SetColumnWidthPixel(colIndex, minColumnWidth.Value);
                    }

                    if (value != null)
                    {
                        if (column.Format == ColumnFormats.FormattedText || column.Format == ColumnFormats.Text)
                        {
                            // more than 26000 chars in a cell throws stack overflow exception
                            // when using sheet.autofitrow method, so by setting column width
                            // in such cases is the fix to this issue
                            if ((value as string).Length > 20000)
                            {
                                cells.SetColumnWidth(colIndex, 75);
                            }

                            cellStyle.VerticalAlignment = TextAlignmentType.Top;
                        }

                        switch (column.Format)
                        {
                            case ColumnFormats.FormattedText:
                                cells[rowIndex, colIndex].HtmlString = RichTextFormater.EnhanceRichText(value.SanitizeExcelData().ToString());
                                break;
                            case ColumnFormats.Text:
                            case ColumnFormats.String:
                                cells[rowIndex, colIndex].PutValue(value.SanitizeExcelData());
                                break;
                            default:
                                cells[rowIndex, colIndex].PutValue(value);
                                break;
                        }
                    }

                    cellStyle.ForegroundColor = useStdStyle ? rowBgColor : rowAlternateBgColor;
                    cells[rowIndex, colIndex].SetStyle(cellStyle);
                    colIndex++;
                    if (colIndex > Settings.MaxColumnsForExport)
                    {
                        //Excel can't have more than 256 columns
                        break;
                    }
                }

                sheet.AutoFitRow(rowIndex);
                if (minRowHeight.HasValue)
                {
                    if (cells.GetRowHeightPixel(rowIndex) < minRowHeight.Value)
                    {
                        cells.SetRowHeightPixel(rowIndex, minRowHeight.Value);
                    }
                }

                rowIndex++;
            }

            #endregion

            using (CultureInfoHelper.SetDefault())
            {
                workbook.Save(stream, SaveFormat.Xlsx);
            }
            stream.Seek(0, SeekOrigin.Begin);
        }

        void CreateHyperlink(dynamic sheet, int rowIndex, int colIndex, object value)
        {
            var link = UserColumnUrlResolver.Resolve(Convert.ToString(value));
            if (!string.IsNullOrEmpty(link.DisplayText))
            {
                int linkIndex = sheet.Hyperlinks.Add(rowIndex, colIndex, 1, 1, link.Url);
                var link1 = sheet.Hyperlinks[linkIndex];
                link1.TextToDisplay = link.DisplayText;
            }
            else
            {
                int linkIndex = sheet.Hyperlinks.Add(rowIndex, colIndex, 1, 1, Convert.ToString(value));
                var link1 = sheet.Hyperlinks[linkIndex];
                link1.TextToDisplay = Convert.ToString(value);
            }
        }

        void TruncateWarnings(Cells cells, int rowIndex, Style titleStyle, FontSetting fontSettings, bool forColumn = false)
        {
            cells.Merge(rowIndex, 0, 1, ExportData.Columns.Count());
            var truncateWarning = string.Format(Settings.Warnings[forColumn ? "ColumnsTruncatedWarning" : "RowsTruncatedWarning"],
                                                forColumn ? Settings.MaxColumnsForExport : Settings.ExportLimitedToNbRecords);
            cells[rowIndex, 0].PutValue(truncateWarning);
            titleStyle.Font.Size = (int) fontSettings.FontSize;
            titleStyle.Font.IsBold = false;
            titleStyle.Font.IsItalic = true;
            cells[rowIndex, 0].SetStyle(titleStyle);
        }
    }

    public static class ExcelExportExtensions
    {
        const int MaxWorksheetNameLength = 31;

        public static Worksheet ResolveName(this Worksheet worksheet, string reportTitle)
        {
            var workSheetName = reportTitle.Replace("/", "_")
                                           .Replace("\"", "_")
                                           .Replace("\"", "_")
                                           .Replace("\'", "_");

            workSheetName = Regex.Replace(workSheetName, @"[\[\]\\\:\|\?\*\><\&]", "_");

            worksheet.Name = workSheetName.Length > MaxWorksheetNameLength
                ? workSheetName.Substring(0, 28) + "..."
                : workSheetName;

            return worksheet;
        }

        public static object SanitizeExcelData(this object colValue)
        {
            var re = new Regex("^[-+=@]");
            if (colValue != null && re.IsMatch(colValue.ToString().Trim()))
            {
                return $"''{colValue}";
            }

            return colValue;
        }
    }
}