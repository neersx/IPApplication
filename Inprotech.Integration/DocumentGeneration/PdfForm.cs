using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Aspose.Pdf.Facades;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using FieldType = InprotechKaizen.Model.Components.DocumentGeneration.Services.FieldType;

namespace Inprotech.Integration.DocumentGeneration
{
    public interface IPdfForm
    {
        string EnsureExists(string pdfFormsDirectory);
        Task Fill(string filePath, string templateFile, IEnumerable<ItemProcessor> itemProcessors);
        CachedDocument GetCachedDocument(string fileKey, bool keepData = false);
        string CacheDocument(string path, string fileName);
        void CleanUp();
    }

    public class PdfForm : IPdfForm
    {
        readonly IFileHelpers _fileHelpers;
        readonly IPdfDocumentCache _pdfDocumentCache;
        readonly string _pdfFormsDirectory;
        readonly List<string> _tempFileNames = new List<string>();

        public PdfForm(IFileHelpers fileHelpers, ISiteControlReader siteControlReader, IPdfDocumentCache pdfDocumentCache)
        {
            _fileHelpers = fileHelpers;
            _pdfDocumentCache = pdfDocumentCache;
            _pdfFormsDirectory = siteControlReader.Read<string>(SiteControls.PDFFormsDirectory);
        }

        public string EnsureExists(string fileName)
        {
            if (_fileHelpers.Exists(fileName)) return fileName;

            if (!string.IsNullOrEmpty(_pdfFormsDirectory))
            {
                fileName = Path.Combine(_pdfFormsDirectory, Path.GetFileName(fileName) ?? string.Empty);
                if (_fileHelpers.Exists(fileName))
                {
                    return fileName;
                }
            }

            throw new FileNotFoundException($"'{fileName}' could not be found in the default location and the location specified by the \"PDF Forms Directory\" site control");
        }

        public CachedDocument GetCachedDocument(string fileKey, bool keepData = false)
        {
            return keepData ? _pdfDocumentCache.Retrieve(fileKey) : _pdfDocumentCache.RetrieveAndDelete(fileKey);
        }

        public string CacheDocument(string path, string fileName)
        {
            if (!_fileHelpers.Exists(path)) return string.Empty;

            var input = new CachedDocument
            {
                Data = _fileHelpers.ReadAllBytes(path),
                FileName = fileName
            };
            return _pdfDocumentCache.CacheDocument(input);
        }

        public async Task Fill(string filePath, string templateFile, IEnumerable<ItemProcessor> itemProcessors)
        {
            if (filePath == null) throw new ArgumentNullException(nameof(filePath));
            if (itemProcessors == null) throw new ArgumentNullException(nameof(itemProcessors));
            if (templateFile == null) throw new ArgumentNullException(nameof(templateFile));

            // make a copy for incremental save to preserve extended digital rights.
            _fileHelpers.Copy(templateFile, filePath);

            using (var stream = _fileHelpers.OpenRead(filePath, fileAccess: FileAccess.ReadWrite))
            {
                var form = new Form(stream);
                foreach (var itemProcessor in itemProcessors)
                {
                    if (itemProcessor.Exception != null)
                    {
                        continue;
                    }

                    if (!itemProcessor.Fields.Any())
                    {
                        itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.NoField, $"There is no field linked to this Item with name '{itemProcessor.ReferencedDataItem.ItemName}'.");
                        continue;
                    }

                    try
                    {
                        //With PDF, there is only one field
                        var field = itemProcessor.Fields[0];
                        if (field.FieldType == FieldType.Unknown)
                        {
                            continue;
                        }

                        if (field.FieldType == FieldType.XFA)
                        {
                            var value = GetValue(itemProcessor.TableResultSets, itemProcessor.Separator, itemProcessor.DateStyle, itemProcessor.EmptyValue);
                            var xmlData = "<?xml version=\"1.0\"?><xfa:data xmlns:xfa=\"http://www.xfa.org/schema/xfa-data/1.0/\">";
                            xmlData += value;
                            xmlData += "</xfa:data>";
                            var xmlFileName = GetTemporaryFile(".xml");
                            _tempFileNames.Add(xmlFileName);
                            _fileHelpers.WriteAllText(xmlFileName, xmlData, Encoding.UTF8);
                            using (var xmlInputStream = new FileStream(xmlFileName, FileMode.Open))
                            {
                                form.ImportXml(xmlInputStream, false);
                            }

                            continue;
                        }

                        var fieldName = form.FieldNames.FirstOrDefault(f => f.Equals(field.FieldName, StringComparison.InvariantCultureIgnoreCase));
                        if (string.IsNullOrEmpty(fieldName))
                        {
                            itemProcessor.Exception = new ItemProcessorException(ItemProcessErrorReason.FormFieldNotFound, $"Can't find Form Field '{field.FieldName}' in this PDF Form.");
                            continue;
                        }

                        if (field.FieldType == FieldType.Image)
                        {
                            var imageValue = GetImageValue(itemProcessor.TableResultSets);
                            if (imageValue != null)
                            {
                                var imageFileName = GetTemporaryFile(".png");
                                using (var fileStream = new FileStream(imageFileName, FileMode.Create, FileAccess.ReadWrite))
                                {
                                    fileStream.Write(imageValue, 0, imageValue.Length);
                                }

                                _tempFileNames.Add(imageFileName);
                                form.FillImageField(fieldName, imageFileName);
                            }
                        }
                        else
                        {
                            var value = GetValue(itemProcessor.TableResultSets, itemProcessor.Separator, itemProcessor.DateStyle, itemProcessor.EmptyValue);

                            switch (field.FieldType)
                            {
                                case FieldType.Text:
                                    form.FillField(fieldName, value.Replace("\r\n", "\n"));
                                    break;
                                case FieldType.CheckBox:
                                case FieldType.ComboBox:
                                case FieldType.ListBox:
                                case FieldType.RadioButton:
                                    form.FillField(fieldName, value);
                                    break;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        itemProcessor.Exception = ex;
                    }
                }

                form.Save(stream);
                _tempFileNames.Add(filePath);
            }
        }

        public void CleanUp()
        {
            foreach (var tempFileName in _tempFileNames)
            {
                try
                {
                    _fileHelpers.DeleteFile(tempFileName);
                }
                catch
                {
                }
            }
        }

        static string GetValue(IList<TableResultSet> tableResultSets, string separator, int dateStyle, string defaultValue)
        {
            var value = string.Empty;

            if (tableResultSets == null || !tableResultSets.Any())
            {
                return !string.IsNullOrEmpty(value) ? value : defaultValue;
            }

            var tableResultSet = tableResultSets.First();
            if (tableResultSet.RowResultSets == null || tableResultSet.RowResultSets.Count <= 0)
            {
                return !string.IsNullOrEmpty(value) ? value : defaultValue;
            }

            foreach (var rowResultSet in tableResultSet.RowResultSets)
            {
                if (!string.IsNullOrEmpty(value) && !string.IsNullOrEmpty(separator))
                {
                    switch (separator)
                    {
                        case "CHR9":
                            value += "\t";
                            break;
                        case "CHR10":
                        case "CHR11":
                        case "CHR13":
                            value += "\n";
                            break;
                        default:
                            value += separator;
                            break;
                    }
                }

                if (rowResultSet.Values != null && rowResultSet.Values.Count > 0)
                {
                    if (rowResultSet.Values[0] is DateTime)
                    {
                        value += ConvertDateTime((DateTime)rowResultSet.Values[0], dateStyle);
                    }
                    else
                    {
                        value += Convert.ToString(rowResultSet.Values[0]);
                    }
                }

                if (string.IsNullOrEmpty(separator))
                {
                    break;
                }
            }

            return !string.IsNullOrEmpty(value) ? value : defaultValue;
        }

        static byte[] GetImageValue(IList<TableResultSet> tableResultSets)
        {
            if (tableResultSets == null || !tableResultSets.Any())
            {
                return null;
            }

            var tableResultSet = tableResultSets.First();
            if (tableResultSet.RowResultSets == null || tableResultSet.RowResultSets.Count <= 0)
            {
                return null;
            }

            var rowResultSet = tableResultSet.RowResultSets[0];
            if (rowResultSet.Values == null || rowResultSet.Values.Count <= 0) return null;

            return rowResultSet.Values[0] as byte[];
        }

        static string ConvertDateTime(DateTime value, int dateStyle)
        {
            const string dateFormat = "d MMMM yyyy"; //Format conform to PassThru
            //TODO: use a new Site Control to control the format of the date
            return value.ToString(dateFormat);
        }

        static string GetTemporaryFile(string extension)
        {
            return Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + extension);
        }
    }
}