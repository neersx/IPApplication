using System.Collections.Generic;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Web.Configuration.Core
{
    public class SiteControlUpdateDetails
    {
        public int Id { get; set; }
        public object Value { get; set; }
        public string Notes { get; set; }
        public IEnumerable<Tag> Tags { get; set; }
    }
}