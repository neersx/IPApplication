using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public class WorkspaceProfileFields
    {
        [JsonProperty("workspace")]
        public List<string> Workspace { get; set; }
    }
}
