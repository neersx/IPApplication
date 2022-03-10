using System;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using Aspose.Words;
using Aspose.Words.Drawing;
using Aspose.Words.Tables;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Word
{
    internal sealed class WordExport : Export
    {
        public WordExport(SearchResultsSettings settings, SearchResults exportData, IImageSettings imageSettings, IUserColumnUrlResolver userColumnUrlResolver)
            : base(settings, exportData, imageSettings, userColumnUrlResolver)
        {
        }

        public override string ContentType => "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

        public override string FileNameExtension => "docx";

        public override OpenType OpenType => OpenType.Inline;

        public override void Execute(Stream stream)
        {
            var exportSection = Settings.LayoutSettings;

            var imageDimensions = ExportUtils.GetImageDimensions(exportSection.Word.ImageMaxDimension);
            var maxImageHeight = imageDimensions.Height;
            var maxImageWidth = imageDimensions.Width;

            if (exportSection.Word.ImageReSizeMode == ExportConfig.WordConfig.ReSizeMode.NoResize)
            {
                maxImageHeight = 0;
                maxImageWidth = 0;
            }

            var culture = Settings.Culture;
            var dateFormat = Settings.DateFormat;
            var timeFormat = Settings.TimeFormat;
            var dateTimeFormat = $"{dateFormat} {timeFormat}";
            var numberFormat = CultureInfo.CreateSpecificCulture(culture.ToString()).NumberFormat;

            var titleColor = ColorTranslator.FromHtml(exportSection.Word.TitleColor);
            var titleBgColor = ColorTranslator.FromHtml(exportSection.Word.TitleBackgroundColor);
            var rowBgColor = ColorTranslator.FromHtml(exportSection.Word.RowBackgroundColor);
            var rowAlternateBgColor = ColorTranslator.FromHtml(exportSection.Word.RowAlternateBackgroundColor);
            var columnHeaderBgColor = ColorTranslator.FromHtml(exportSection.Word.ColumnHeaderBackgroundColor);
            var borderColor = ColorTranslator.FromHtml(exportSection.Word.BorderColor);

            var document = new Document();
            document.BuiltInDocumentProperties.NameOfApplication = Settings.ApplicationName;
            document.BuiltInDocumentProperties.Author = Settings.Author;
            document.BuiltInDocumentProperties.Title = Settings.WorksheetTitle();

            #region Styles

            var titleStyle = document.Styles.Add(StyleType.Paragraph, "TitleStyle");
            titleStyle.Font.Bold = true;
            titleStyle.Font.Name = "Arial";
            titleStyle.Font.Size = 10;
            titleStyle.Font.Color = titleColor;
            titleStyle.ParagraphFormat.Alignment = ParagraphAlignment.Left;
            titleStyle.ParagraphFormat.Shading.ForegroundPatternColor = titleBgColor;
            titleStyle.ParagraphFormat.Shading.Texture = TextureIndex.TextureSolid;

            var exportLimitStyle = document.Styles.Add(StyleType.Paragraph, "ExportLimitStyle");
            exportLimitStyle.Font.Italic = true;
            exportLimitStyle.Font.Name = "Arial";
            exportLimitStyle.Font.Size = 8;
            exportLimitStyle.Font.Color = titleColor;
            exportLimitStyle.ParagraphFormat.Alignment = ParagraphAlignment.Center;

            var columnHeaderStyle = document.Styles.Add(StyleType.Paragraph, "ColumnHeaderStyle");
            columnHeaderStyle.Font.Bold = true;
            columnHeaderStyle.Font.Name = "Arial";
            columnHeaderStyle.Font.Size = 9;
            columnHeaderStyle.Font.Color = titleColor;
            columnHeaderStyle.ParagraphFormat.Alignment = ParagraphAlignment.Center;

            var cellStyle = document.Styles.Add(StyleType.Paragraph, "CellStyle");
            cellStyle.Font.Bold = false;
            cellStyle.Font.Name = "Arial";
            cellStyle.Font.Size = 8;
            cellStyle.Font.Color = titleColor;
            cellStyle.ParagraphFormat.Alignment = ParagraphAlignment.Center;

            #endregion

            var builder = new DocumentBuilder(document);

            builder.PageSetup.Orientation = exportSection.Word.PageOrientation == ExportConfig.WordConfig.PageOrientationType.Landscape ? Orientation.Landscape : Orientation.Portrait;
            builder.PageSetup.PaperSize = PaperSizeConvertor.ForWord(exportSection.Word.PaperSize);

            builder.PageSetup.TopMargin = ConvertUtil.MillimeterToPoint(exportSection.Word.MarginTop);
            builder.PageSetup.RightMargin = ConvertUtil.MillimeterToPoint(exportSection.Word.MarginRight);
            builder.PageSetup.BottomMargin = ConvertUtil.MillimeterToPoint(exportSection.Word.MarginBottom);
            builder.PageSetup.LeftMargin = ConvertUtil.MillimeterToPoint(exportSection.Word.MarginLeft);
            builder.MoveToDocumentStart();

            #region Report Title

            if (!string.IsNullOrEmpty(Settings.ReportTitle))
            {
                builder.ParagraphFormat.Style = titleStyle;
                builder.Writeln(Settings.ReportTitle);
            }

            if (Settings.ExportLimitedToNbRecords.HasValue)
            {
                builder.ParagraphFormat.Style = exportLimitStyle;
                builder.Writeln(string.Format(Settings.Warnings["RowsTruncatedWarning"], Settings.ExportLimitedToNbRecords));
            }

            #endregion

            #region Report Additional Info

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchBelongingTo))
            {
                builder.Writeln();
                builder.ParagraphFormat.Style = titleStyle;
                builder.Writeln(ExportData.AdditionalInfo?.SearchBelongingTo);
            }

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchDateRange))
            {
                builder.ParagraphFormat.Style = titleStyle;
                builder.Writeln(ExportData.AdditionalInfo?.SearchDateRange);
            }

            #endregion

            builder.Writeln();

            var table = builder.StartTable();
            builder.RowFormat.Borders[BorderType.Top].Color = borderColor;
            builder.RowFormat.Borders[BorderType.Top].LineStyle = LineStyle.Single;
            builder.RowFormat.Borders[BorderType.Top].LineWidth = 1f;
            builder.RowFormat.Borders[BorderType.Right].Color = borderColor;
            builder.RowFormat.Borders[BorderType.Right].LineStyle = LineStyle.Single;
            builder.RowFormat.Borders[BorderType.Right].LineWidth = 1f;
            builder.RowFormat.Borders[BorderType.Bottom].Color = borderColor;
            builder.RowFormat.Borders[BorderType.Bottom].LineStyle = LineStyle.Single;
            builder.RowFormat.Borders[BorderType.Bottom].LineWidth = 1f;
            builder.RowFormat.Borders[BorderType.Left].Color = borderColor;
            builder.RowFormat.Borders[BorderType.Left].LineStyle = LineStyle.Single;
            builder.RowFormat.Borders[BorderType.Left].LineWidth = 1f;
            builder.RowFormat.AllowAutoFit = true;
            builder.RowFormat.AllowBreakAcrossPages = false;
            builder.CellFormat.VerticalAlignment = CellVerticalAlignment.Center;
            builder.CellFormat.Borders[BorderType.Top].Color = borderColor;
            builder.CellFormat.Borders[BorderType.Top].LineStyle = LineStyle.Single;
            builder.CellFormat.Borders[BorderType.Top].LineWidth = 1f;
            builder.CellFormat.Borders[BorderType.Right].Color = borderColor;
            builder.CellFormat.Borders[BorderType.Right].LineStyle = LineStyle.Single;
            builder.CellFormat.Borders[BorderType.Right].LineWidth = 1f;
            builder.CellFormat.Borders[BorderType.Bottom].Color = borderColor;
            builder.CellFormat.Borders[BorderType.Bottom].LineStyle = LineStyle.Single;
            builder.CellFormat.Borders[BorderType.Bottom].LineWidth = 1f;
            builder.CellFormat.Borders[BorderType.Left].Color = borderColor;
            builder.CellFormat.Borders[BorderType.Left].LineStyle = LineStyle.Single;
            builder.CellFormat.Borders[BorderType.Left].LineWidth = 1f;

            #region Column Headers

            foreach (var column in ExportData.Columns)
            {
                builder.InsertCell();
                builder.RowFormat.HeadingFormat = true;
                builder.ParagraphFormat.Style = columnHeaderStyle;
                builder.CellFormat.Shading.ForegroundPatternColor = columnHeaderBgColor;
                builder.CellFormat.Shading.Texture = TextureIndex.TextureSolid;

                switch (column.Format)
                {
                    case ColumnFormats.Time:
                    case ColumnFormats.Date:
                    case ColumnFormats.DateTime:
                    case ColumnFormats.Boolean:
                    case ColumnFormats.Hours:
                    case ColumnFormats.HoursWithSeconds:
                    case ColumnFormats.HoursWithMinutes:
                        builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                        break;
                    case ColumnFormats.Currency:
                    case ColumnFormats.LocalCurrency:
                    case ColumnFormats.Decimal:
                    case ColumnFormats.Percentage:
                    case ColumnFormats.Integer:
                        builder.ParagraphFormat.Alignment = ParagraphAlignment.Right;
                        break;
                    default:
                        builder.ParagraphFormat.Alignment = ParagraphAlignment.Left;
                        break;
                }

                builder.Write(column.Title);
            }

            builder.EndRow();

            #endregion

            #region Rows

            var useStdStyle = false;
            foreach (var row in ExportData.Rows)
            {
                useStdStyle = !useStdStyle;
                var values = row;

                foreach (var column in ExportData.Columns)
                {
                    builder.InsertCell();
                    builder.RowFormat.HeadingFormat = false;
                    builder.ParagraphFormat.Style = cellStyle;
                    builder.CellFormat.Shading.ForegroundPatternColor = useStdStyle ? rowBgColor : rowAlternateBgColor;
                    builder.CellFormat.Shading.Texture = TextureIndex.TextureSolid;
                    builder.Font.Color = Color.Black;
                    builder.Font.Bold = false;

                    if (values.ContainsKey(column.Name))
                    {
                        var value = values[column.Name];
                        string stringValue = null;
                        if (value != null)
                        {
                            stringValue = value.ToString();
                        }

                        var isConverted = false;

                        if (!isConverted)
                        {
                            switch (column.Format)
                            {
                                case ColumnFormats.Time:
                                    if (value != null)
                                    {
                                        stringValue = ((DateTime) value).ToString(timeFormat);
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.Url:
                                    if (value != null)
                                    {
                                        CreateHyperlink(builder, value);
                                        stringValue = null;
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.Date:
                                    if (value != null)
                                    {
                                        stringValue = ((DateTime) value).ToString(dateFormat);
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    if (column.ColumnItemId == "DueDate"
                                        || column.ColumnItemId == "ReminderDate")
                                    {
                                        if (values.ContainsKey("IsDueDateToday") && (bool)values["IsDueDateToday"])
                                        {
                                            builder.Font.Bold = true;
                                        }
                                        if (values.ContainsKey("IsDueDatePast") && (bool)values["IsDueDatePast"])
                                        {
                                            builder.Font.Bold = true;
                                            builder.Font.Color = Color.Red;
                                        }
                                    }
                                    break;
                                case ColumnFormats.DateTime:
                                    if (value != null)
                                    {
                                        stringValue = ((DateTime) value).ToString(dateTimeFormat);
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.Hours:
                                    if (value != null)
                                    {
                                        stringValue = new MinutesConverter().Convert(value);
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.HoursWithSeconds:
                                    if (value != null)
                                    {
                                        stringValue = new SecondsConverter().Convert(value);
                                    }
                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.HoursWithMinutes:
                                    if (value != null)
                                    {
                                        stringValue = new SecondsConverter().Convert(value, false);
                                    }
                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                case ColumnFormats.Currency:
                                case ColumnFormats.LocalCurrency:
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
                                        stringValue = string.Format(numberFormat, "{0:c}", value);
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Right;
                                    break;
                                case ColumnFormats.Boolean:
                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    if (value != null)
                                    {
                                        stringValue = null;
                                        builder.InsertCheckBox(string.Empty, Convert.ToBoolean(value), 13);
                                    }

                                    break;
                                case ColumnFormats.Decimal:
                                case ColumnFormats.Percentage:
                                case ColumnFormats.Integer:
                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Right;
                                    break;
                                case ColumnFormats.FormattedText:
                                    if (value != null)
                                    {
                                        builder.InsertHtml(RichTextFormater.EnhanceRichText(value.ToString()));
                                    }

                                    stringValue = null;
                                    break;
                                case ColumnFormats.ImageKey:
                                    stringValue = null;
                                    if (value != null)
                                    {
                                        var imageData = ImageSettings.FindImageByKey(Convert.ToInt32(value));
                                        if (imageData != null)
                                        {
                                            var imageHeight = maxImageHeight;
                                            var imageWidth = maxImageWidth;
                                            if (exportSection.CompressImage)
                                            {
                                                var image = ExportUtils.ResizeImage(imageData.Data, imageWidth, imageHeight);
                                                if (image != null)
                                                {
                                                    builder.InsertImage(image);
                                                }
                                            }
                                            else
                                            {
                                                using (var imageStream = new MemoryStream(imageData.Data))
                                                {
                                                    var image = Image.FromStream(imageStream);
                                                    ExportUtils.MaintainAspectRatio(ref imageWidth, ref imageHeight, image);
                                                    builder.InsertImage(image, imageWidth, imageHeight);
                                                }
                                            }
                                        }
                                    }

                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Center;
                                    break;
                                default:
                                    builder.ParagraphFormat.Alignment = ParagraphAlignment.Left;
                                    break;
                            }
                        }

                        if (stringValue != null)
                        {
                            builder.Write(stringValue);
                        }
                    }
                }

                builder.EndRow();
            }

            builder.EndTable();

            #endregion

            #region Page Orientation

            var tableWidth = table.FirstRow.Cells.Cast<Cell>().Sum(cell => cell.CellFormat.Width + cell.CellFormat.LeftPadding + cell.CellFormat.RightPadding + 2f);
            var pageWidth = builder.PageSetup.PageWidth - builder.PageSetup.LeftMargin - builder.PageSetup.RightMargin;
            if (tableWidth > pageWidth)
            {
                builder.PageSetup.Orientation = Orientation.Landscape;
                pageWidth = builder.PageSetup.PageWidth - builder.PageSetup.LeftMargin - builder.PageSetup.RightMargin;
            }
            else
            {
                var cellNumber = table.FirstRow.Cells.Count;
                var neededWidth = (pageWidth - tableWidth) / cellNumber;
                for (var i = 0; i < table.Rows.Count; i++)
                {
                    foreach (var node in table.Rows[i].Cells)
                    {
                        var cell = (Cell) node;
                        cell.CellFormat.Width += neededWidth;
                    }
                }
            }

            #endregion

            #region Header

            if (exportSection.Word.DisplayLogo && !string.IsNullOrEmpty(exportSection.Word.CompanyLogo))
            {
                builder.PageSetup.DifferentFirstPageHeaderFooter = exportSection.Word.DisplayLogoOnFirstPageOnly;
                builder.MoveToHeaderFooter(exportSection.Word.DisplayLogoOnFirstPageOnly
                                               ? HeaderFooterType.HeaderFirst
                                               : HeaderFooterType.HeaderPrimary);

                using (var fullSizeImage = ExportUtils.ByteArrayToImage(exportSection.Word.CompanyLogoImage))
                {
                    const int maxHeight = 57;
                    const int maxWidth = 185;
                    var newWidth = maxWidth;

                    if (fullSizeImage.Width <= maxWidth)
                    {
                        newWidth = fullSizeImage.Width;
                    }

                    var newHeight = fullSizeImage.Height * newWidth / fullSizeImage.Width;
                    if (newHeight > maxHeight)
                    {
                        newWidth = newWidth * maxHeight / newHeight;
                        newHeight = maxHeight;
                    }

                    builder.InsertImage(fullSizeImage, RelativeHorizontalPosition.Page, 10, RelativeVerticalPosition.Page, 10, newWidth, newHeight, WrapType.Through);
                    builder.PageSetup.HeaderDistance = newHeight;
                }
            }

            #endregion

            #region Footer

            if (exportSection.Word.DisplayLogoOnFirstPageOnly)
            {
                builder.MoveToHeaderFooter(HeaderFooterType.FooterFirst);
                builder.StartTable();
                builder.RowFormat.Borders.ClearFormatting();
                builder.InsertCell();
                builder.CellFormat.Borders.ClearFormatting();
                builder.CellFormat.Shading.ClearFormatting();
                builder.CellFormat.Width = pageWidth / 2;
                builder.ParagraphFormat.Style = cellStyle;
                builder.Write(DateTime.Now.ToString(dateFormat) + " " + DateTime.Now.ToString(timeFormat));
                builder.ParagraphFormat.Alignment = ParagraphAlignment.Left;

                builder.InsertCell();
                builder.CellFormat.Borders.ClearFormatting();
                builder.CellFormat.Shading.ClearFormatting();
                builder.CellFormat.Width = pageWidth / 2;
                builder.ParagraphFormat.Style = cellStyle;
                builder.InsertField("PAGE", string.Empty);
                builder.Write(" / ");
                builder.InsertField("NUMPAGES", string.Empty);
                builder.ParagraphFormat.Alignment = ParagraphAlignment.Right;
                builder.EndTable();
            }

            builder.MoveToHeaderFooter(HeaderFooterType.FooterPrimary);
            builder.StartTable();
            builder.RowFormat.Borders.ClearFormatting();
            builder.InsertCell();
            builder.CellFormat.Borders.ClearFormatting();
            builder.CellFormat.Shading.ClearFormatting();
            builder.CellFormat.Width = pageWidth / 2;
            builder.ParagraphFormat.Style = cellStyle;
            builder.Write(DateTime.Now.ToString(dateFormat) + " " + DateTime.Now.ToString(timeFormat));
            builder.ParagraphFormat.Alignment = ParagraphAlignment.Left;

            builder.InsertCell();
            builder.CellFormat.Borders.ClearFormatting();
            builder.CellFormat.Shading.ClearFormatting();
            builder.CellFormat.Width = pageWidth / 2;
            builder.ParagraphFormat.Style = cellStyle;
            builder.InsertField("PAGE", string.Empty);
            builder.Write(" / ");
            builder.InsertField("NUMPAGES", string.Empty);
            builder.ParagraphFormat.Alignment = ParagraphAlignment.Right;
            builder.EndTable();

            builder.PageSetup.FooterDistance = 20f;

            #endregion

            document.Save(stream, SaveFormat.Docx);
            stream.Seek(0, SeekOrigin.Begin);
        }

        void CreateHyperlink(dynamic builder, object value)
        {
            builder.Font.Color = Color.Blue;
            builder.Font.Underline = Underline.Single;
            var link = UserColumnUrlResolver.Resolve(Convert.ToString(value));
            if (!string.IsNullOrEmpty(link.DisplayText))
            {
                builder.InsertHyperlink(link.DisplayText, link.Url, false);
            }
            else
            {
                builder.InsertHyperlink(Convert.ToString(value), Convert.ToString(value), false);
            }

            builder.Font.Color = Color.Black;
            builder.Font.Underline = Underline.None;
        }
    }
}