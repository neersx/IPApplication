using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public class WorkflowSaveModel : WorkflowCharacteristics
    {
        public int Id { get; set; }
        public string CriteriaName { get; set; }
        public bool? IsLocalClient { get; set; }
        public bool IsProtected { get; set; }
        public bool InUse { get; set; }
    }
}