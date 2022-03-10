using System;
using System.Text.RegularExpressions;

namespace Inprotech.Integration.Reports
{
    [Serializable]
    public class ReportServerInternalServerErrorException : Exception
    {
        public ReportServerInternalServerErrorException(string reportPath, string rawHtml) : base(ReportServerErrorParser(reportPath, rawHtml))
        {
            ReportPath = reportPath;
            RawHtml = rawHtml;
        }

        public string ReportPath { get; set; }

        public string RawHtml { get; set; }

        static string ReportServerErrorParser(string reportPath, string html)
        {
            string Body()
            {
                const string patternBody = @"(?<body>(<body ).*?(</body>))";

                var bodyMatch = Regex.Match(html, patternBody, RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.Singleline);

                if (!bodyMatch.Success || !bodyMatch.Groups["body"].Success) return string.Empty;

                var body = bodyMatch.Groups["body"].Value
                                    .Replace("&#39;", "'")
                                    .Replace("&nbsp;", " ")
                                    .Replace("&quot;", "\"")
                                    .Replace("&lt;", "<")
                                    .Replace("&gt;", ">");

                return Regex.Replace(body, "<[^>]*>", string.Empty).Trim();
            }

            T SafeExtract<T>(Func<T> run)
            {
                try
                {
                    return run();
                }
                catch
                {
                    return default(T);
                }
            }

            return $"ReportPath: {reportPath}{Environment.NewLine}{SafeExtract(Body) ?? "Error occurred in Reporting Services request"}";
        }
    }
}