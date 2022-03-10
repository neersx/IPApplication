using Aspose.Cells;
using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;
using Inprotech.Infrastructure.Web;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using Newtonsoft.Json.Linq;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Excel
{
    public class ExcelStyle
    {
        public bool IsHidden { get; set; }
        public bool IsBold { get; set; }
        public int FontSize { get; set; }
    }

    public class ExcelCellAttribute : Attribute
    {
        public readonly bool Bold;
        public readonly int Col;

        public readonly int Row;

        public ExcelCellAttribute(int row, int col)
        {
            Row = row;
            Col = col;
        }

        public ExcelCellAttribute(int row, int col, bool bold)
        {
            Row = row;
            Col = col;
            Bold = bold;
        }
    }

    public class ExcelTableAttribute : Attribute
    {
        public readonly int Col;

        public readonly int Row;

        public ExcelTableAttribute(int row, int col)
        {
            Row = row;
            Col = col;
        }
    }

    public class ExcelListAttribute : Attribute
    {
        public readonly int Col;

        public readonly int Row;

        public ExcelListAttribute(int row, int col)
        {
            Row = row;
            Col = col;
        }
    }

    public class ExcelRowNumberAttribute : Attribute
    {
    }

    public class ExcelHeaderAttribute : Attribute
    {
        public readonly string Format;

        public readonly string Header;

        public ExcelHeaderAttribute(string header)
        {
            Header = header;
            Format = null;
        }

        public ExcelHeaderAttribute(string header, string format)
        {
            Header = header;
            Format = format;
        }

        public Type Converter { get; set; }
    }

    public class ExcelWorksheet
    {
        public string Name { get; set; }
    }

    public class ExcelWorkbook : ExcelWorksheet
    {
        public ExcelWorkbook()
        {
            Worksheets = new List<ExcelWorksheet>();
        }

        public List<ExcelWorksheet> Worksheets { get; set; }
    }

    public class SimpleExcelExporter : ISimpleExcelExporter
    {
        readonly Dictionary<Type, IDataConverter> _dataConverters = new Dictionary<Type, IDataConverter>();
        readonly IExportHelperService _exportHelperService;

        public SimpleExcelExporter(IExportHelperService exportHelperService)
        {
            _exportHelperService = exportHelperService;
        }

        public HttpResponseMessage Export(PagedResults pagedResults, string fileName)
        {
            var result = new HttpResponseMessage(HttpStatusCode.OK)
                         {
                             Content = new StreamContent(Export(pagedResults.Data))
                         };

            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.ms-excel");
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = fileName};
            return result;
        }

        public Stream Export(IEnumerable<object> data)
        {
            var wb = new ExcelWorkbook
                     {
                         Worksheets = new List<ExcelWorksheet>
                                      {
                                          new SimpleWorksheet
                                          {
                                              Name = "Export",
                                              Table = data.ToList()
                                          }
                                      }
                     };

            var output = new MemoryStream();
            Export(wb, output);
            return output;
        }

        void Export(ExcelWorkbook report, Stream output)
        {
            #region fixup worksheet names - should be less than 31 char, no special chars

            foreach (var s in report.Worksheets)
                s.Name = s.Name.Substring(0, Math.Min(s.Name.Length, 27));

            var duplicateGroups = (from s in report.Worksheets
                                   group s by s.Name
                                   into g
                                   select new
                                          {
                                              Name = g.Key,
                                              Cnt = g.Count(),
                                              Worksheets = g.ToList()
                                          }
                                   into groupped
                                   where groupped.Cnt > 1
                                   select groupped).ToList();

            foreach (var g in duplicateGroups)
            {
                var i = 0;

                foreach (var s in g.Worksheets)
                    s.Name = s.Name.Substring(0, Math.Min(s.Name.Length, 27)) + string.Format("-{0:00}", i++);
            }

            #endregion

            var licensePath = "Aspose.Cells.lic";
            
            var license = new License();
            license.SetLicense(licensePath);

            var config = _exportHelperService.LayoutSettings;

            var wb = new Workbook().ApplyLayoutSettings(config);

            wb.Worksheets.Clear();

            foreach (var s in report.Worksheets)
            {
                var ws = wb.Worksheets.Add(s.Name);

                ws.PageSetup.Orientation = config.Excel.PageOrientation == ExportConfig.ExcelConfig.PageOrientationType.Landscape ? PageOrientationType.Landscape : PageOrientationType.Portrait;
                ws.PageSetup.Zoom = 100;

                #region format cells

                var cells = (from p in s.GetType().GetProperties()
                             from a in p.GetCustomAttributes(true).OfType<ExcelCellAttribute>()
                             select new
                                    {
                                        a.Row,
                                        a.Col,
                                        a.Bold,
                                        Val = p.GetValue(s)
                                    }).ToList();

                foreach (var c in cells)
                {
                    SetCell(ws.Cells[c.Row, c.Col], c.Val, null, null);
                    if (c.Bold)
                    {
                        var cell = ws.Cells[c.Row, c.Col];
                        var style = cell.GetStyle();
                        style.Font.IsBold = true;
                        cell.SetStyle(style);
                    }
                }

                #endregion

                #region format tables

                var tables = (from p in s.GetType().GetProperties()
                              from a in p.GetCustomAttributes(true).OfType<ExcelTableAttribute>()
                              select new
                                     {
                                         a.Row,
                                         a.Col,
                                         Val = p.GetValue(s)
                                     }).ToList();

                foreach (var t in tables)
                {
                    var row = t.Row;
                    var col = t.Col;

                    var rowType = t.Val.GetType().GetGenericArguments()[0];
                    if (rowType == typeof(object))
                    {
                        var enumerable = t.Val as IEnumerable;
                        if (enumerable != null)
                        {
                            foreach (var o in (IEnumerable) t.Val)
                            {
                                if (o != null) rowType = o.GetType();
                                break;
                            }
                        }
                    }

                    var headers = (from p in rowType.GetProperties()
                                   from a in p.GetCustomAttributes(true).OfType<ExcelHeaderAttribute>()
                                   let style = t.Val.GetType().GetGenericArguments()[0].GetProperties().FirstOrDefault(x => x.Name == p.Name + "Style" && x.PropertyType == typeof(ExcelStyle))
                                   select new
                                          {
                                              Header = _exportHelperService.Translate(a.Header),
                                              a.Format,
                                              a.Converter,
                                              Prop = p,
                                              StyleProp = style
                                          }).ToList();

                    foreach (var h in headers)
                    {
                        ws.Cells[row, col].Value = h.Header;

                        var style = ws.Cells[row, col].GetStyle();

                        style.Font.IsBold = true;
                        style.ForegroundColor = Use(style.ForegroundColor, config.Excel.ColumnHeaderBackgroundColor);
                        style.Pattern = BackgroundType.Solid;

                        ws.Cells[row, col].SetStyle(style);

                        col++;
                    }

                    row++;

                    foreach (var o in (IEnumerable) t.Val)
                    {
                        col = t.Col;

                        foreach (var h in headers)
                        {
                            var value = Convert(h.Converter, h.Prop.GetValue(o));
                            
                            var style = ws.Cells[row, col].GetStyle();

                            var configuredColor = row % 2 == 0 ? config.Excel.RowBackgroundColor : config.Excel.RowAlternateBackgroundColor;

                            style.ForegroundColor = Use(style.ForegroundColor, configuredColor);
                            style.Pattern = BackgroundType.Solid;

                            ws.Cells[row, col].SetStyle(style);

                            ExcelStyle customStyle = null;
                            if (h.StyleProp != null) customStyle = (ExcelStyle) h.StyleProp.GetValue(o);
                            SetCell(ws.Cells[row, col], value, h.Format, customStyle);

                            col++;
                        }

                        row++;
                    }
                }

                #endregion
            }

            wb.Save(output, SaveFormat.Xlsx);
            output.Seek(0, SeekOrigin.Begin);
        }

        static void SetCell(Cell cell, object val, string format, ExcelStyle style)
        {
            if (cell == null) throw new ArgumentNullException(nameof(cell));

            if (style != null && style.IsHidden) return;

            if (val is string)
            {
                cell.Value = "'" + val;
            }
            else if (val is JObject || val is JArray)
            {
                var allowedString = System.Convert.ToString(val);
                if (allowedString.Length >= Int16.MaxValue)
                {
                    allowedString = allowedString.Substring(0, Int16.MaxValue);
                }

                cell.Value = allowedString;
            }
            else
            {
                if (val == null) return;
                if (val is DateTime)
                {
                    if (format != null)
                    {
                        var s = cell.GetStyle();
                        s.Custom = format;
                        cell.SetStyle(s);
                    }

                    cell.Value = val;

                    return;
                }

                cell.Value = val;
                if (format != null)
                {
                    var s = cell.GetStyle();
                    s.Custom = format;
                    cell.SetStyle(s);
                }
            }

            if (style != null)
            {
                if (style.IsHidden) return;

                var s = cell.GetStyle();
                s.Font.IsBold = style.IsBold;

                if (style.FontSize > 0)
                {
                    s.Font.Size = style.FontSize;
                }

                cell.SetStyle(s);
            }
        }

        static Color Use(Color color, string configuredColor)
        {
            if (string.IsNullOrWhiteSpace(configuredColor))
            {
                return color;
            }

            return ColorTranslator.FromHtml(configuredColor);
        }

        object Convert(Type converterType, object v)
        {
            if (converterType == null || !converterType.IsAssignableTo<IDataConverter>())
            {
                return v;
            }

            IDataConverter dataConverter;
            if (!_dataConverters.TryGetValue(converterType, out dataConverter))
            {
                dataConverter = (IDataConverter) Activator.CreateInstance(converterType);
                _dataConverters.Add(converterType, dataConverter);
            }

            return dataConverter.Convert(v);
        }

        public class SimpleWorksheet : ExcelWorksheet
        {
            [ExcelTable(0, 0)]
            public List<object> Table { get; set; }
        }
    }

    public static class WorkBookExtensions
    {
        public static Workbook ApplyLayoutSettings(this Workbook workbook, ExportConfig config)
        {
            var titleColor = string.IsNullOrWhiteSpace(config.Excel.TitleColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.TitleColor);
            var titleBgColor = string.IsNullOrWhiteSpace(config.Excel.TitleBackgroundColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.TitleBackgroundColor);
            var rowBgColor = string.IsNullOrWhiteSpace(config.Excel.RowBackgroundColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.RowBackgroundColor);
            var rowAlternateBgColor = string.IsNullOrWhiteSpace(config.Excel.RowAlternateBackgroundColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.RowAlternateBackgroundColor);
            var columnHeaderBgColor = string.IsNullOrWhiteSpace(config.Excel.ColumnHeaderBackgroundColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.ColumnHeaderBackgroundColor);
            var borderColor = string.IsNullOrWhiteSpace(config.Excel.BorderColor) ? Color.Empty : ColorTranslator.FromHtml(config.Excel.BorderColor);

            workbook.ChangePalette(titleColor, 55);
            workbook.ChangePalette(titleBgColor, 54);
            workbook.ChangePalette(rowBgColor, 53);
            workbook.ChangePalette(rowAlternateBgColor, 52);
            workbook.ChangePalette(columnHeaderBgColor, 51);
            workbook.ChangePalette(borderColor, 50);

            return workbook;
        }
    }
}