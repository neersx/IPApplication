using System;
using System.Globalization;
using System.Xml;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases;
using Regex = System.Text.RegularExpressions.Regex;

namespace Inprotech.Web.Processing
{
    public interface ICpaXmlExporter
    {
        FileExportResponse DownloadCpaXmlExport(int processId, int userId);
    }

    public class CpaXmlExporter : ICpaXmlExporter
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ICpaXmlData _cpaXmlData;
        readonly Func<DateTime> _now;

        public CpaXmlExporter(IPreferredCultureResolver preferredCultureResolver, ICpaXmlData cpaXmlData, Func<DateTime> now)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _cpaXmlData = cpaXmlData;
            _now = now;
        }

        public FileExportResponse DownloadCpaXmlExport(int processId, int userId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var xmlDocument = _cpaXmlData.GetCpaXmlData(userId, processId, culture);

            var response = new FileExportResponse
            {
                ContentType = "text/xml;",
                FileName = GenerateFileName(xmlDocument),
                Document = xmlDocument
            };

            return response;
        }

        string GenerateFileName(XmlNode cpaXmlExportData)
        {
            var filename = string.Empty;
            var xmlNodeList = cpaXmlExportData.SelectNodes("NewDataSet//Table//CPAXMLDATA");

            if (xmlNodeList != null && xmlNodeList.Count >= 3)
            {
                var transactionHeaderNodeString = xmlNodeList[2].FirstChild.InnerText;
                var xmlString = new XmlDocument {XmlResolver = null};
                xmlString.LoadXml(transactionHeaderNodeString);

                var senderFilenameNode = xmlString.SelectSingleNode("TransactionHeader/SenderDetails/SenderFilename");
                if (senderFilenameNode != null)
                    filename = senderFilenameNode.InnerText;
            }

            if (!string.IsNullOrEmpty(filename))
                return filename;

            var now = _now();
            const string pattern = "[/:]";
            var regex = new Regex(pattern);
            filename = "Data Import~" +
                       Regex.Replace(regex.Replace(DateTime.SpecifyKind(now, DateTimeKind.Utc).ToString(CultureInfo.InvariantCulture),
                                                   string.Empty), @"\s*", string.Empty) + ".xml";
            return filename;
        }
    }
}