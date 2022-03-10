using System.Collections.Generic;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Maintenance.Topics
{
    public class MaintenanceSaveModel
    {
        public Dictionary<string, JObject> Topics { get; set; }
    }
}
