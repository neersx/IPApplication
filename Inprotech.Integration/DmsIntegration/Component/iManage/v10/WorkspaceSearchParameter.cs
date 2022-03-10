using Newtonsoft.Json;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public class WorkspaceSearchParameter
    {
        public WorkspaceSearchParameter()
        {
            Filters = new WorkspaceSearchFilter();
            ProfileFields = new WorkspaceProfileFields();
        }

        [JsonProperty("profile_fields")]
        public WorkspaceProfileFields ProfileFields { get; set; }

        [JsonProperty("filters")]
        public WorkspaceSearchFilter Filters { get; set; }
    }
}
