using System;
using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public interface IUserColumnUrlResolver
    {
        UserColumnUrl Resolve(string value);
    }

    public class UserColumnUrlResolver : IUserColumnUrlResolver
    {
        const string Pattern = @"\[(.*?)\]";
        const char Separator = '|';

        public UserColumnUrl Resolve(string value)
        {
            if (!Regex.IsMatch(value, Pattern))
            {
                return new UserColumnUrl
                {
                    DisplayText = string.Empty,
                    Url = value
                };
            }

            var givenUrl = Regex.Matches(Convert.ToString(value), Pattern);
            var getMatch = givenUrl[0];
            var splitUrl = getMatch.Groups[1].Value.Split(Separator);
            return new UserColumnUrl
            {
                DisplayText = splitUrl[0],
                Url = splitUrl[1]
            };
        }
    }

    public class UserColumnUrl
    {
        public string DisplayText { get; set; }
        public string Url { get; set; }
    }
}