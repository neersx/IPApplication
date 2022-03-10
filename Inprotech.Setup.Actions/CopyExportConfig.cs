using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Setup.Actions.Export;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Newtonsoft.Json;
using Formatting = Newtonsoft.Json.Formatting;

namespace Inprotech.Setup.Actions
{
    public class CopyExportConfig : ISetupAction
    {
        public string Description => "Copy Inprotech.Export.config";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var iisPath = ctx.PairedIisApp.PhysicalPath;
            var instancePath = ctx.InstancePath;

            var sourcePath = Path.Combine(iisPath, "bin\\Inprotech.Export.config");
            var destPath = Path.Combine(instancePath, "Inprotech.Server\\Inprotech.Export.json");

            eventStream.PublishInformation($"Copying config from {sourcePath} to {destPath}");

            var config = ExportConfig.Load(XElement.Load(sourcePath));
            var json = JsonConvert.SerializeObject(config, Formatting.Indented);

            File.WriteAllText(destPath, json);
        }
    }

    public class ExportConfig
    {
        /* keep this file same as ExportSection.cs in Infrastructure */
        public class Config
        {
            public string TitleColor { get; set; }
            public string TitleBackgroundColor { get; set; }
            public string RowBackgroundColor { get; set; }
            public string RowAlternateBackgroundColor { get; set; }
            public string ColumnHeaderBackgroundColor { get; set; }
            public string BorderColor { get; set; }
            public string ImageMaxDimension { get; set; }
        }

        public class ExcelConfig : Config
        {
            public enum PageOrientationType
            {
                Landscape,
                Portrait
            }

            public enum ReSizeMode
            {
                Default = 0,
                NoResize = 1
            }

            public PageOrientationType PageOrientation { get; set; }
            public PaperSize PaperSize { get; set; }
            public ReSizeMode ImageReSizeMode { get; set; }
        }

        public class WordConfig : Config
        {
            public enum PageOrientationType
            {
                Landscape,
                Portrait
            }

            public enum ReSizeMode
            {
                Default = 0,
                NoResize = 1
            }

            public PageOrientationType PageOrientation { get; set; }
            public PaperSize PaperSize { get; set; }
            public ReSizeMode ImageReSizeMode { get; set; }
            public float MarginTop { get; set; }
            public float MarginRight { get; set; }
            public float MarginBottom { get; set; }
            public float MarginLeft { get; set; }
            public string CompanyLogo { get; set; }
            public bool DisplayLogo { get; set; }
            public bool DisplayLogoOnFirstPageOnly { get; set; }
        }

        public class PdfConfig : Config
        {
            public enum ReSizeMode
            {
                Default = 0,
                NoResize = 1
            }

            public float MarginTop { get; set; }
            public float MarginRight { get; set; }
            public float MarginBottom { get; set; }
            public float MarginLeft { get; set; }
            public string CompanyLogo { get; set; }
            public bool DisplayLogo { get; set; }
            public bool DisplayLogoOnFirstPageOnly { get; set; }
            public string IconCheckboxChecked { get; set; }
            public string IconCheckboxUnchecked { get; set; }
            public ReSizeMode ImageReSizeMode { get; set; }
            public string FontName => "Arial Unicode MS";
        }

        public ExcelConfig Excel { get; set; }

        public WordConfig Word { get; set; }

        public PdfConfig Pdf { get; set; }

        public bool CompressImage { get; set; }

        public static ExportConfig Load(XElement element)
        {
            var excel = element.Descendants("excel").Single();
            var exportElement = element.Descendants("export").Single();
            var word = element.Descendants("word").Single();
            var pdf = element.Descendants("pdf").Single();

            var jsonConfig = new ExportConfig
            {
                Excel = new ExcelConfig
                {
                    TitleColor = (string)excel.Attribute("title-color"),
                    TitleBackgroundColor = (string)excel.Attribute("title-background-color"),
                    RowBackgroundColor = (string)excel.Attribute("row-background-color"),
                    RowAlternateBackgroundColor = (string)excel.Attribute("row-alternate-background-color"),
                    ColumnHeaderBackgroundColor = (string)excel.Attribute("column-header-background-color"),
                    BorderColor = (string)excel.Attribute("border-color"),
                    ImageMaxDimension = (string)excel.Attribute("max-image-dimension"),
                    PageOrientation = (ExcelConfig.PageOrientationType)Enum.Parse(typeof(ExcelConfig.PageOrientationType), (string)excel.Attribute("page-orientation")),
                    ImageReSizeMode = (ExcelConfig.ReSizeMode)Enum.Parse(typeof(ExcelConfig.ReSizeMode), (string)excel.Attribute("image-resize-mode")),
                    PaperSize = (PaperSize)Enum.Parse(typeof(PaperSize), (string)excel.Attribute("paper-size"))
                },
                Word = new WordConfig
                {
                    TitleColor = (string)word.Attribute("title-color"),
                    TitleBackgroundColor = (string)word.Attribute("title-background-color"),
                    RowBackgroundColor = (string)word.Attribute("row-background-color"),
                    RowAlternateBackgroundColor = (string)word.Attribute("row-alternate-background-color"),
                    ColumnHeaderBackgroundColor = (string)word.Attribute("column-header-background-color"),
                    BorderColor = (string)word.Attribute("border-color"),
                    ImageMaxDimension = (string)word.Attribute("max-image-dimension"),
                    PageOrientation = (WordConfig.PageOrientationType)Enum.Parse(typeof(WordConfig.PageOrientationType), (string)word.Attribute("page-orientation")),
                    ImageReSizeMode = (WordConfig.ReSizeMode)Enum.Parse(typeof(WordConfig.ReSizeMode), (string)word.Attribute("image-resize-mode")),
                    PaperSize = (PaperSize)Enum.Parse(typeof(PaperSize), (string)word.Attribute("paper-size")),
                    MarginTop = (float)word.Attribute("margin-top"),
                    MarginBottom = (float)word.Attribute("margin-bottom"),
                    MarginLeft = (float)word.Attribute("margin-left"),
                    MarginRight = (float)word.Attribute("margin-right"),
                    DisplayLogo = (bool)word.Attribute("display-logo"),
                    DisplayLogoOnFirstPageOnly = (bool)word.Attribute("display-logo-on-first-page-only"),
                    CompanyLogo = "client/images/branding-logo.png"
                },
                Pdf = new PdfConfig
                {
                    TitleColor = (string)pdf.Attribute("title-color"),
                    TitleBackgroundColor = (string)pdf.Attribute("title-background-color"),
                    RowBackgroundColor = (string)pdf.Attribute("row-background-color"),
                    RowAlternateBackgroundColor = (string)pdf.Attribute("row-alternate-background-color"),
                    ColumnHeaderBackgroundColor = (string)pdf.Attribute("column-header-background-color"),
                    BorderColor = (string)pdf.Attribute("border-color"),
                    ImageMaxDimension = (string)pdf.Attribute("max-image-dimension"),
                    ImageReSizeMode = (PdfConfig.ReSizeMode)Enum.Parse(typeof(PdfConfig.ReSizeMode), (string)pdf.Attribute("image-resize-mode")),
                    MarginTop = (float)pdf.Attribute("margin-top"),
                    MarginBottom = (float)pdf.Attribute("margin-bottom"),
                    MarginLeft = (float)pdf.Attribute("margin-left"),
                    MarginRight = (float)pdf.Attribute("margin-right"),
                    DisplayLogo = (bool)pdf.Attribute("display-logo"),
                    DisplayLogoOnFirstPageOnly = (bool)pdf.Attribute("display-logo-on-first-page-only"),
                    CompanyLogo = "client/images/branding-logo.png",
                    IconCheckboxChecked = "client/images/checkbox2.check.png",
                    IconCheckboxUnchecked = "client/images/checkbox2.uncheck.png"
                },
                CompressImage = bool.Parse((string)exportElement.Attribute("compress-image"))
            };

            return jsonConfig;
        }
    }
}