using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class WorkflowEntryStepViewModel
    {
        public int Id { get; set; }

        public AvailableTopic Step { get; set; }

        public string Title { get; set; }

        public string ScreenTip { get; set; }

        public bool IsMandatory { get; set; }

        public bool IsInherited { get; set; }

        public int DisplaySequence { get; set; }

        public StepCategory[] Categories { get; set; }
    }
}