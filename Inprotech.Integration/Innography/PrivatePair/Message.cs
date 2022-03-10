using System;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Message
    {
        [JsonProperty("meta")]
        public Meta Meta { get; set; }

        [JsonProperty("links")]
        [JsonConverter(typeof(SingleOrArrayConverter<LinkInfo>))]
        public IEnumerable<LinkInfo> Links { get; set; }
    }

    public static class MessageExt
    {
        public static LinkInfo For(this IEnumerable<LinkInfo> links, string linkType)
        {
            return links.FirstOrDefault(_ => _.LinkType == linkType);
        }

        public static string ApplicationId(this Message message)
        {
            var biblio = message.Links.For(LinkTypes.Biblio);
            var match = Regex.Match(biblio?.Link ?? string.Empty, "biblio_(?<name>.*?).json");
            return match.Groups["name"].Value;
        }

        public static string DocumentName(this LinkInfo linkInfo)
        {
            var documentUrl = new Uri(linkInfo.Link);
            return Path.GetFileName(documentUrl.LocalPath);
        }
    }
}