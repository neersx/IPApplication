using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public interface IStepCategory
    {
        string CategoryType { get; }
        StepCategory Get(TopicControlFilter filter, Criteria criteria = null);
    }
}