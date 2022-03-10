using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public interface IAllDocumentsTabExtractor
    {
        IEnumerable<AvailableDocument> Extract(string html);
    }

    public class AllDocumentsTabExtractor : IAllDocumentsTabExtractor
    {
        static readonly string[] SupportedFormats = { "dd.MM.yyyy", "dd-MM-yyyy" };

        const string AllDocsRowMatchingPattern = "(?<docrow><tr>\\s*<td class=\"smallBorder\"><input type=\"checkbox\".*?</tr>)";
        const string DocAttrCapturePattern = "<td[^>]*?>(?<data>.*?)</td>";
        const string HyperlinkDetailsCapturePattern = "<a[^>]*?documentId=(?<documentId>.*?)(&amp;number=)(?<number>.*?)(&amp;.*?, ')(?<fileName>.*?)('.*?)[^>]*?>(?<desc>.*?)</a>";
        const string NoDocumentsMatchingPattern = "<table id=\"row\" class=\"application docList\">";

        const RegexOptions RegexOptions = System.Text.RegularExpressions.RegexOptions.Singleline | System.Text.RegularExpressions.RegexOptions.Compiled;

        public IEnumerable<AvailableDocument> Extract(string html)
        {
            if (html == null) throw new ArgumentNullException("html");

            if (!Regex.IsMatch(html, NoDocumentsMatchingPattern, RegexOptions))
                yield break;
            
            var docRowMatches = Regex.Matches(html, AllDocsRowMatchingPattern, RegexOptions);
            var unexpectedScrape = docRowMatches.Count == 0;

            foreach (Match m in docRowMatches)
            {
                if (!m.Success)
                {
                    unexpectedScrape = true;
                    break;
                }

                var data = Regex.Matches(m.Groups["docrow"].Value, DocAttrCapturePattern, RegexOptions);
                if (data.Count != 5)
                {
                    unexpectedScrape = true;
                    break;
                }

                var hyperLinkDetailsMatch = Regex.Match(data[2].ValueFor("data"),
                                               HyperlinkDetailsCapturePattern,
                                               RegexOptions);

                if (!hyperLinkDetailsMatch.Success)
                {
                    unexpectedScrape = true;
                    break;
                }

                yield return new AvailableDocument
                {
                    Date = ParseDocDate(data[1].ValueFor("data")),
                    DocumentName = hyperLinkDetailsMatch.ValueFor("desc"),
                    DocumentId = hyperLinkDetailsMatch.ValueFor("documentId"),
                    Procedure = WebUtility.HtmlDecode(data[3].ValueFor("data")),
                    NumberOfPages = int.Parse(data[4].ValueFor("data")),
                    Number = hyperLinkDetailsMatch.ValueFor("number")
                };
            }

            if (unexpectedScrape)
                throw new Exception("Unable to extract all documents tab document");
        }

        static DateTime ParseDocDate(string input)
        {
            return DateTime.ParseExact(input, SupportedFormats, CultureInfo.InvariantCulture, DateTimeStyles.None);
        }
    }

    public static class RegexExt
    {
        public static string ValueFor(this Match match, string groupName)
        {
            return match.Groups[groupName].Value.Trim();
        }
    }

    public class AvailableDocument
    {
        public string Number { get; set; }
        public string DocumentId { get; set; }
        public DateTime Date { get; set; }
        public string DocumentName { get; set; }
        public string Procedure { get; set; }
        public int NumberOfPages { get; set; }
    }

    public static class AvailableDocumentExt
    {
        public static string FileName(this AvailableDocument availableDocument)
        {
            const string fileNameTemplate = "{0}-{1:yyyy-MM-dd}-{2}-{3}.pdf";

            return EnsureSafeFileName(string.Format(fileNameTemplate,
                availableDocument.Number,
                availableDocument.Date,
                availableDocument.DocumentId,
                availableDocument.DocumentName));
        }

        static string EnsureSafeFileName(string fileName)
        {
            return Path.GetInvalidFileNameChars()
                .Aggregate(fileName, (current, c) => current.Replace(c.ToString(), string.Empty));
        }
    }
}
