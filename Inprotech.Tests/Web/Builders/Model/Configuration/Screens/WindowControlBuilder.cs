using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Configuration.Screens
{
    public class WindowControlBuilder : IBuilder<WindowControl>
    {
        public int? CriteriaId { get; set; }

        public short? EntryNumber { get; set; }

        public string Name { get; set; }

        public WindowControl Build()
        {
            return EntryNumber == null
                ? new WindowControl(CriteriaId ?? Fixture.Integer(), Name)
                : new WindowControl(CriteriaId ?? Fixture.Integer(), EntryNumber.Value, Name);
        }

        public static WindowControlBuilder For(DataEntryTask dataEntryTask)
        {
            return new WindowControlBuilder
            {
                CriteriaId = dataEntryTask.Criteria.Id,
                Name = "WorkflowWizard",
                EntryNumber = dataEntryTask.Id
            };
        }
    }
}