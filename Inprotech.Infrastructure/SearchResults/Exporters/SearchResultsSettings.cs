using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class SearchResultsSettings
    {
        public string ApplicationName { get; set; }

        public CultureInfo Culture { get; set; }

        public string DateFormat { get; set; }

        public string TimeFormat { get; set; }

        public string Author { get; set; }

        public string ReportTitle { get; set; }

        public string ReportFileName { get; set; }

        public int? ExportLimitedToNbRecords { get; set; }

        public int MaxColumnsForExport { get; set; }

        public ExportConfig LayoutSettings { get; set; }

        public Dictionary<string, string> Warnings { get; set; }

        public Dictionary<ReportExportFormat, FontSetting> FontSettings { get; set; }
        public string LocalCurrencyCode { get; set; }
    }

    public class FontSetting
    {
        public string FontFamily { get;set; }
        public dynamic FontSize { get; set; }
    }

    public static class SearchResultsSettingsExtensions
    {
        public static string WorksheetTitle(this SearchResultsSettings settings)
        {
            return !string.IsNullOrEmpty(settings.ReportTitle) ? settings.ReportTitle : settings.ReportFileName;
        }

        public static void LoadImages(this SearchResultsSettings settings)
        {
            settings.LayoutSettings.Pdf.CompanyLogoImage = ImageAsByte(settings.LayoutSettings.Pdf.CompanyLogo);
            settings.LayoutSettings.Pdf.IconCheckboxCheckedImage = ImageAsByte(settings.LayoutSettings.Pdf.IconCheckboxChecked);
            settings.LayoutSettings.Pdf.IconCheckboxUncheckedImage = ImageAsByte(settings.LayoutSettings.Pdf.IconCheckboxUnchecked);
            settings.LayoutSettings.Word.CompanyLogoImage = ImageAsByte(settings.LayoutSettings.Word.CompanyLogo);
        }

        static byte[] ImageAsByte(string imagePath)
        {
            if (!string.IsNullOrEmpty(imagePath) && File.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, imagePath)))
            {
                var image = System.Drawing.Image.FromFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, imagePath));

                using (var ms = new MemoryStream())
                {
                    image.Save(ms, image.RawFormat);
                    return ms.ToArray();
                }
            }

            return new byte[0];
        }
    }
}
