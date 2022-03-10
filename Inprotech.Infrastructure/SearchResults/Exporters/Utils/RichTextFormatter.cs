using System.Net;
using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Utils
{
    public sealed class RichTextFormater
    {
        const string MatchingSetOfTags = @"<\s*([^ >]+)[^>]*>.*?<\s*/\s*\1\s*>";
        const string SelfClosingTags = @"<[^>]+>";
        const string CarriageReturns = @"(\r\n|\n\r|\n|\r)";

        public static string EnhanceRichText(string htmlstring)
        {
            if ( string.IsNullOrWhiteSpace(htmlstring) || !Regex.Match(htmlstring, CarriageReturns).Success) return htmlstring;
            return WebUtility.HtmlDecode(Regex.Replace(htmlstring, CarriageReturns, "<br/>"));
        }

        public static bool TryEnhanceRichTextIfRequired(string text, out string enhancedText)
        {
            if (!ContainsHtml(text))
            {
                enhancedText = text;
                return false;
            }

            enhancedText = EnhanceRichText(text);
            return true;
        }

        public static bool ContainsHtml(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return false;

            return Regex.IsMatch(text, SelfClosingTags) || Regex.IsMatch(text, MatchingSetOfTags);
        }
    }
}
