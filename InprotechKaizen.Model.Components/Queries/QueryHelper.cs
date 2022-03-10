using System;
using System.Linq;
using System.Xml.Linq;

namespace InprotechKaizen.Model.Components.Queries
{
    public static class QueryHelper
    {
        public static void AddSortAttributes(string sortBy, string sortDir, int sortSeq, XDocument outputColumns)
        {
            if (!string.IsNullOrEmpty(sortBy))
            {
                outputColumns.Descendants("Column")
                             .Single(
                                     c =>
                                         c.Attributes()
                                          .Any(
                                               a =>
                                                   a.Name.LocalName == "PublishName" &&
                                                   a.Value.Equals(sortBy, StringComparison.InvariantCultureIgnoreCase)))
                             .Add(new XAttribute("SortOrder", sortSeq),
                                  new XAttribute("SortDirection",
                                                 string.Equals(sortDir, "desc", StringComparison.InvariantCultureIgnoreCase) ? "D" : "A"));
            }
        }

        public static XElement BuildOutputColumn(string procedureName, string id, string publishName=null, string qualifier=null)
        {
            if (publishName == null)
                publishName = id;

            if (qualifier == null)
            {
                return new XElement("Column", new XAttribute("ProcedureName", procedureName), new XAttribute("ID", id),
                                    new XAttribute("PublishName", publishName));
            }

            return new XElement("Column", new XAttribute("ProcedureName", procedureName), new XAttribute("ID", id),
                                new XAttribute("PublishName", publishName), new XAttribute("Qualifier", qualifier));

        }
    }
}