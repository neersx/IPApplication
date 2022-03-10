using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class Link
    {
        public string Rel { get; set; }

        public string Href { get; set; }
    }

    public static class LinkEx
    {
        public static string ByRel(this IEnumerable<Link> links, string rel)
        {
            return links.FirstOrDefault(_ => _.Rel == rel)?.Href;
        }
    }
}