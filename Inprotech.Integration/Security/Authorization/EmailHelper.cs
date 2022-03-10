using System.Text.RegularExpressions;

namespace Inprotech.Integration.Security.Authorization
{
    public static class EmailHelper
    {
        public static bool HasHtmlTags(string input)
        {
            if (string.IsNullOrEmpty(input)) return false;

            var tagWithoutClosingRegex = new Regex(@"<[^>]+>");

            return tagWithoutClosingRegex.IsMatch(input);
        }
    }

    public class UserEmailContent
    {
        public string Subject { get; set; }
        public string Body { get; set; }
        public string Footer { get; set; }
    }
}
