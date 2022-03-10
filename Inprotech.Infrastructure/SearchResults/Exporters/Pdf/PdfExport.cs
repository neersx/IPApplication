using System;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using Aspose.Pdf.Generator;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;
using HeaderFooter = Aspose.Pdf.Generator.HeaderFooter;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Pdf
{
    internal sealed class PdfExport : Export
    {
        public PdfExport(SearchResultsSettings settings, SearchResults exportData, IImageSettings imageSettings, IUserColumnUrlResolver userColumnUrlResolver)
            : base(settings, exportData, imageSettings, userColumnUrlResolver)
        {
        }

        public override string ContentType => "application/pdf";

        public override string FileNameExtension => "pdf";

        public override OpenType OpenType => OpenType.Inline;

        public override void Execute(Stream stream)
        {
            var exportSection = Settings.LayoutSettings;

            var imageDimensions = ExportUtils.GetImageDimensions(exportSection.Word.ImageMaxDimension);
            var maxImageHeight = imageDimensions.Height;
            var maxImageWidth = imageDimensions.Width;

            if (exportSection.Pdf.ImageReSizeMode == ExportConfig.PdfConfig.ReSizeMode.NoResize)
            {
                maxImageHeight = 0;
                maxImageWidth = 0;
            }

            var culture = Settings.Culture;
            var dateFormat = Settings.DateFormat;
            var timeFormat = Settings.TimeFormat;
            var dateTimeFormat = $"{dateFormat} {timeFormat}";
            var numberFormat = CultureInfo.CreateSpecificCulture(culture.ToString()).NumberFormat;

            var applicationPath = AppDomain.CurrentDomain.BaseDirectory;
            var isIconCheckValid = !string.IsNullOrEmpty(exportSection.Pdf.IconCheckboxChecked) && File.Exists(Path.Combine(applicationPath, exportSection.Pdf.IconCheckboxChecked));
            var isIconUncheckDefined = !string.IsNullOrEmpty(exportSection.Pdf.IconCheckboxUnchecked);
            var isIconUncheckValid = isIconUncheckDefined && File.Exists(Path.Combine(applicationPath, exportSection.Pdf.IconCheckboxUnchecked));

            var titleColor = new Color(exportSection.Pdf.TitleColor);
            var titleBgColor = new Color(exportSection.Pdf.TitleBackgroundColor);
            var rowBgColor = new Color(exportSection.Pdf.RowBackgroundColor);
            var rowAlternateBgColor = new Color(exportSection.Pdf.RowAlternateBackgroundColor);

            var margins = new MarginInfo
            {
                Top = exportSection.Pdf.MarginTop,
                Bottom = exportSection.Pdf.MarginBottom,
                Left = exportSection.Pdf.MarginLeft,
                Right = exportSection.Pdf.MarginRight
            };

            var pdf = new Aspose.Pdf.Generator.Pdf
            {
                Author = Settings.Author,
                Creator = Settings.ApplicationName,
                IsTruetypeFontMapCached = true,
                TruetypeFontMapPath = Path.GetTempPath(),
                Title = Settings.WorksheetTitle(),
                DestinationType = DestinationType.FitWidth,
                IsLandscape = true,
                OpenType = Aspose.Pdf.Generator.OpenType.Auto
            };

            var section = pdf.Sections.Add();
            section.PageInfo.Margin = margins;

            #region Header

            //the header to be added
            var header = new HeaderFooter(section)
            {
                Margin =
                {
                    Top = 10f,
                    Bottom = 5f
                }
            };
            //Set the header of odd & even pages of the PDF document
            section.OddHeader = header;
            section.EvenHeader = header;

            #region Set Company Logo

            var isLogoDisplayed = false;
            var msLogo = new MemoryStream(exportSection.Pdf.CompanyLogoImage);
            var msChecked = new MemoryStream(exportSection.Pdf.IconCheckboxCheckedImage);
            var msUnchecked = new MemoryStream(exportSection.Pdf.IconCheckboxUncheckedImage);
            if (exportSection.Pdf.DisplayLogo && !string.IsNullOrEmpty(exportSection.Pdf.CompanyLogo))
            {
                isLogoDisplayed = true;
                var logoImage = ExportUtils.ByteArrayToImage(exportSection.Pdf.CompanyLogoImage);
                var imgLogo = new Image(header)
                                {
                                    ImageInfo = new ImageInfo
                                    {
                                        ImageStream = msLogo,
                                        ImageFileType = GetFileType(logoImage.RawFormat)
                                    }
                                };

                const int maxHeight = 57;
                const int maxWidth = 185;
                int newHeight;
                var newWidth = maxWidth;

                using (var fullSizeImage = logoImage)
                {
                    if (fullSizeImage.Width <= maxWidth)
                    {
                        newWidth = fullSizeImage.Width;
                    }

                    newHeight = fullSizeImage.Height * newWidth / fullSizeImage.Width;
                    if (newHeight > maxHeight)
                    {
                        newWidth = newWidth * maxHeight / newHeight;
                        newHeight = maxHeight;
                    }
                }

                imgLogo.ImageInfo.FixWidth = newWidth;
                imgLogo.ImageInfo.FixHeight = newHeight;
                header.Paragraphs.Add(imgLogo);
            }

            #endregion

            #region Report Title

            if (!string.IsNullOrEmpty(Settings.ReportTitle))
            {
                header.Paragraphs.Add(new Text(header, Settings.ReportTitle)
                {
                    TextInfo =
                    {
                        Alignment = AlignmentType.Left,
                        IsUnicode = true,
                        FontName = exportSection.Pdf.FontName,
                        FontSize = 10f,
                        IsTrueTypeFontBold = true,
                        Color = titleColor,
                        BackgroundColor = titleBgColor
                    }
                });
            }

            if (Settings.ExportLimitedToNbRecords.HasValue)
            {
                header.Paragraphs.Add(new Text(header, string.Format(Settings.Warnings["RowsTruncatedWarning"], Settings.ExportLimitedToNbRecords))
                {
                    TextInfo =
                    {
                        Alignment = AlignmentType.Center,
                        IsUnicode = true,
                        FontName = exportSection.Pdf.FontName,
                        FontSize = 8f,
                        IsTrueTypeFontItalic = true,
                        Color = titleColor
                    }
                });
            }

            #endregion

            #region Additional Info

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchBelongingTo))
            {
                header.Paragraphs.Add(new Text(header, ExportData.AdditionalInfo?.SearchBelongingTo)
                {
                    TextInfo =
                    {
                        Alignment = AlignmentType.Left,
                        IsUnicode = true,
                        FontName = exportSection.Pdf.FontName,
                        FontSize = 10f,
                        IsTrueTypeFontBold = true,
                        Color = titleColor,
                        BackgroundColor = titleBgColor
                    },
                    Margin =
                    {
                        Top = 5f
                    }
                });
            }

            if (!string.IsNullOrEmpty(ExportData.AdditionalInfo?.SearchDateRange))
            {
                header.Paragraphs.Add(new Text(header, ExportData.AdditionalInfo?.SearchDateRange)
                {
                    TextInfo =
                    {
                        Alignment = AlignmentType.Left,
                        IsUnicode = true,
                        FontName = exportSection.Pdf.FontName,
                        FontSize = 10f,
                        IsTrueTypeFontBold = true,
                        Color = titleColor,
                        BackgroundColor = titleBgColor
                    },
                    Margin =
                    {
                        Bottom = 5f
                    }
                });
            }

            #endregion

            if (isLogoDisplayed && exportSection.Pdf.DisplayLogoOnFirstPageOnly)
            {
                header.IsFirstPageOnly = true;

                var headerNextPage = new HeaderFooter(section)
                {
                    Margin =
                    {
                        Top = 10f,
                        Bottom = 5f
                    },
                    IsSubsequentPagesOnly = true
                };
                section.AdditionalEvenHeader = headerNextPage;
                section.AdditionalOddHeader = headerNextPage;

                if (!string.IsNullOrEmpty(Settings.ReportTitle))
                {
                    var titleText = new Text(headerNextPage, Settings.ReportTitle)
                    {
                        TextInfo =
                        {
                            Alignment = AlignmentType.Center,
                            IsUnicode = true,
                            FontName = exportSection.Pdf.FontName,
                            FontSize = 10f,
                            IsTrueTypeFontBold = true,
                            Color = titleColor
                        }
                    };
                    headerNextPage.Paragraphs.Add(titleText);
                }
            }

            #endregion

            #region Footer

            var footer = new HeaderFooter(section)
            {
                Margin =
                {
                    Top = 5f,
                    Bottom = 0f
                }
            };

            section.OddFooter = footer;
            section.EvenFooter = footer;

            var footerTable = new Table();
            footer.Paragraphs.Add(footerTable);
            footerTable.ColumnAdjustment = ColumnAdjustmentType.AutoFitToWindow;

            var rowFooter = footerTable.Rows.Add();

            var cellDate = rowFooter.Cells.Add();
            cellDate.Alignment = AlignmentType.Left;
            cellDate.Paragraphs.Add(new Text(
                                             DateTime.Now.ToString(dateFormat) + " " + DateTime.Now.ToString(timeFormat))
            {
                TextInfo =
                {
                    FontName = exportSection.Pdf.FontName,
                    FontSize = 8f,
                    Alignment = AlignmentType.Left
                }
            });

            var cellPageNumber = rowFooter.Cells.Add();
            cellPageNumber.Alignment = AlignmentType.Right;
            cellPageNumber.Paragraphs.Add(new Text("$p / $P")
            {
                TextInfo =
                {
                    FontName = exportSection.Pdf.FontName,
                    FontSize = 8f,
                    Alignment = AlignmentType.Right
                }
            });

            #endregion

            var table = new Table
            {
                ColumnAdjustment = ColumnAdjustmentType.AutoFitToWindow,
                DefaultCellTextInfo = {FontSize = 8f, FontName = exportSection.Pdf.FontName},
                RepeatingRows = 1,
                DefaultCellBorder =
                    new BorderInfo((int) BorderSide.All, 0.1f, new Color(exportSection.Pdf.BorderColor)),
                Border = new BorderInfo((int) BorderSide.All, 1f, new Color(exportSection.Pdf.BorderColor)),
                DefaultCellPadding = new MarginInfo
                {
                    Top = 2f,
                    Left = 2f,
                    Right = 2f,
                    Bottom = 2f
                }
            };

            section.Paragraphs.Add(table);

            #region Column Headers

            var headerRow = table.Rows.Add();
            headerRow.IsBroken = true;
            foreach (var column in ExportData.Columns)
            {
                var cell = headerRow.Cells.Add();

                switch (column.Format)
                {
                    case ColumnFormats.Time:
                    case ColumnFormats.Date:
                    case ColumnFormats.DateTime:
                    case ColumnFormats.Boolean:
                    case ColumnFormats.Hours:
                    case ColumnFormats.HoursWithSeconds:
                    case ColumnFormats.HoursWithMinutes:
                        cell.Alignment = AlignmentType.Center;
                        break;
                    case ColumnFormats.Currency:
                    case ColumnFormats.LocalCurrency:
                    case ColumnFormats.Decimal:
                    case ColumnFormats.Percentage:
                    case ColumnFormats.Integer:
                        cell.Alignment = AlignmentType.Right;
                        break;
                    default:
                        cell.Alignment = AlignmentType.Left;
                        break;
                }

                cell.Paragraphs.Add(new Text(column.Title));
            }

            headerRow.DefaultCellTextInfo.FontName = exportSection.Pdf.FontName;
            headerRow.DefaultCellTextInfo.FontSize = 8f;
            headerRow.DefaultCellTextInfo.IsTrueTypeFontBold = true;
            headerRow.DefaultCellTextInfo.Color = titleColor;
            headerRow.BackgroundColor = new Color(exportSection.Pdf.ColumnHeaderBackgroundColor);

            #endregion

            #region Rows

            var useStdStyle = false;
            foreach (var row in ExportData.Rows)
            {
                useStdStyle = !useStdStyle;
                var contentRow = table.Rows.Add();
                var values = row;

                foreach (var column in ExportData.Columns)
                {
                    var contentCell = contentRow.Cells.Add();
                    var contentText = new Text();

                    if (!values.ContainsKey(column.Name)) continue;

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

                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                break;
                            case ColumnFormats.Url:
                                if (value != null)
                                {
                                    CreateHyperlink(contentCell, contentText, value, exportSection);
                                }

                                stringValue = null;
                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                break;
                            case ColumnFormats.Date:
                                if (value != null)
                                {
                                    stringValue = ((DateTime) value).ToString(dateFormat);
                                }

                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                if (column.ColumnItemId == "DueDate"
                                    || column.ColumnItemId == "ReminderDate")
                                {
                                    if (values.ContainsKey("IsDueDateToday") && (bool)values["IsDueDateToday"])
                                    {
                                        contentText.TextInfo.IsTrueTypeFontBold = true;
                                    }
                                    if (values.ContainsKey("IsDueDatePast") && (bool)values["IsDueDatePast"])
                                    {
                                        contentText.TextInfo.IsTrueTypeFontBold = true;
                                        contentText.TextInfo.Color = new Color("Red");
                                    }
                                }
                                break;
                            case ColumnFormats.DateTime:
                                if (value != null)
                                {
                                    stringValue = ((DateTime) value).ToString(dateTimeFormat);
                                }

                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                break;
                            case ColumnFormats.Hours:
                                if (value != null)
                                {
                                    stringValue = new MinutesConverter().Convert(value);
                                }

                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                break;
                            case ColumnFormats.HoursWithSeconds:
                                if (value != null)
                                {
                                    stringValue = new SecondsConverter().Convert(value);
                                }
                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                break;
                            case ColumnFormats.HoursWithMinutes:
                                if (value != null)
                                {
                                    stringValue = new SecondsConverter().Convert(value, false);
                                }
                                contentText.TextInfo.Alignment = AlignmentType.Center;
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

                                contentText.TextInfo.Alignment = AlignmentType.Right;
                                break;
                            case ColumnFormats.Boolean:
                                contentText.TextInfo.Alignment = AlignmentType.Center;
                                if (value != null)
                                {
                                    if (Convert.ToBoolean(value))
                                    {
                                        if (isIconCheckValid)
                                        {
                                            var checkedImage = ExportUtils.ByteArrayToImage(exportSection.Pdf.IconCheckboxCheckedImage);
                                            var imgCheck = new Image(section)
                                            {
                                                ImageInfo = new ImageInfo
                                                {
                                                    ImageStream = msChecked,
                                                    ImageFileType = GetFileType(checkedImage.RawFormat)
                                                },
                                                FixedHeight = 13f,
                                                FixedWidth = 13f
                                            };
                                            contentCell.Alignment = AlignmentType.Center;
                                            contentCell.Paragraphs.Add(imgCheck);
                                            stringValue = null;
                                        }
                                    }
                                    else
                                    {
                                        if (isIconUncheckValid)
                                        {
                                            var uncheckedImage = ExportUtils.ByteArrayToImage(exportSection.Pdf.IconCheckboxUncheckedImage);
                                            var imgUnCheck = new Image(section)
                                            {
                                                ImageInfo = new ImageInfo
                                                {
                                                    ImageStream = msUnchecked,
                                                    ImageFileType = GetFileType(uncheckedImage.RawFormat)
                                                },
                                                FixedHeight = 13f,
                                                FixedWidth = 13f
                                            };
                                            contentCell.Alignment = AlignmentType.Center;
                                            contentCell.Paragraphs.Add(imgUnCheck);
                                            stringValue = null;
                                        }
                                        else if (!isIconUncheckDefined)
                                        {
                                            stringValue = null;
                                        }
                                    }
                                }

                                break;
                            case ColumnFormats.Decimal:
                            case ColumnFormats.Percentage:
                            case ColumnFormats.Integer:
                                contentText.TextInfo.Alignment = AlignmentType.Right;
                                break;
                            case ColumnFormats.FormattedText:
                                if (value != null)
                                {
                                    if (RichTextFormater.TryEnhanceRichTextIfRequired(value.ToString(), out var formattedText))
                                    {
                                        var text2 = new Text(formattedText)
                                        {
                                            IsHtmlTagSupported = true,
                                            TextInfo = {IsUnicode = true}
                                        };
                                        contentCell.Paragraphs.Add(text2);
                                    }
                                    else
                                    {
                                        contentText.Segments.Add(formattedText);
                                        contentText.TextInfo.IsUnicode = true;
                                        contentText.TextInfo.FontName = exportSection.Pdf.FontName;
                                        contentText.TextInfo.FontSize = 8f;
                                        contentCell.Paragraphs.Add(contentText);
                                    }
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
                                        System.Drawing.Image resizedImage;
                                        if (exportSection.CompressImage)
                                        {
                                            resizedImage = ExportUtils.ResizeImage(imageData.Data, imageWidth, imageHeight);
                                        }
                                        else
                                        {
                                            using (var imageStream = new MemoryStream(imageData.Data))
                                            {
                                                resizedImage = System.Drawing.Image.FromStream(imageStream);
                                            }
                                        }

                                        if (resizedImage != null)
                                        {
                                            var image = new Image(section)
                                            {
                                                ImageInfo =
                                                {
                                                    SystemImage = resizedImage
                                                }
                                            };
                                            if (!exportSection.CompressImage)
                                            {
                                                ExportUtils.MaintainAspectRatio(ref imageWidth, ref imageHeight, resizedImage);
                                                image.ImageInfo.FixHeight = imageHeight;
                                                image.ImageInfo.FixWidth = imageWidth;
                                            }

                                            contentCell.Alignment = AlignmentType.Center;
                                            contentCell.Paragraphs.Add(image);
                                        }
                                    }
                                }

                                break;
                            default:
                                contentText.TextInfo.Alignment = AlignmentType.Left;
                                break;
                        }
                    }

                    if (stringValue != null)
                    {
                        contentText.Segments.Add(stringValue);
                        contentText.TextInfo.IsUnicode = true;
                        contentText.TextInfo.FontName = exportSection.Pdf.FontName;
                        contentText.TextInfo.FontSize = 8f;
                        contentCell.Paragraphs.Add(contentText);
                    }
                }

                contentRow.BackgroundColor = useStdStyle ? rowBgColor : rowAlternateBgColor;
            }

            #endregion

            pdf.SetUnicode();
            pdf.Save(stream);
            msLogo.Close();
            msChecked.Close();
            msUnchecked.Close();
            stream.Seek(0, SeekOrigin.Begin);
        }

        void CreateHyperlink(dynamic contentCell, dynamic contentText, object value, dynamic exportSection)
        {
            var link = UserColumnUrlResolver.Resolve(Convert.ToString(value));
            if (!string.IsNullOrEmpty(link.DisplayText))
            {
                var segment = contentText.Segments.Add(link.DisplayText);
                segment.Hyperlink = new Hyperlink();
                segment.Hyperlink.LinkType = HyperlinkType.Web;
                segment.Hyperlink.Url = link.Url;
                contentText.TextInfo.FontName = exportSection.Pdf.FontName;
                contentText.TextInfo.FontSize = 8f;
                contentText.TextInfo.Color = new Color("Blue");
                contentText.TextInfo.IsUnderline = true;
                contentCell.Paragraphs.Add(contentText);
            }
            else
            {
                var segment = contentText.Segments.Add(Convert.ToString(value));
                segment.Hyperlink = new Hyperlink(); 
                segment.Hyperlink.LinkType = HyperlinkType.Web;
                segment.Hyperlink.Url = Convert.ToString(value);
                contentText.TextInfo.FontName = exportSection.Pdf.FontName;
                contentText.TextInfo.FontSize = 8f;
                contentText.TextInfo.Color = new Color("Blue");
                contentText.TextInfo.IsUnderline = true;
                contentCell.Paragraphs.Add(contentText);
            }
        }

        ImageFileType GetFileType(ImageFormat imageFormat)
        {
            if (ImageFormat.Jpeg.Equals(imageFormat))
            {
                return ImageFileType.Jpeg;
            }

            if (ImageFormat.Png.Equals(imageFormat))
            {
                return ImageFileType.Png;
            }

            if (ImageFormat.Gif.Equals(imageFormat))
            {
                return ImageFileType.Gif;
            }

            return ImageFileType.Unknown;
        }
    }
}