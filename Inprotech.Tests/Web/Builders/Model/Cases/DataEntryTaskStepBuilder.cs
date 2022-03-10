using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class DataEntryTaskStepBuilder : IBuilder<DataEntryTaskStep>
    {
        public string ScreenName { get; set; }
        public short? ScreenId { get; set; }
        public string ScreenTitle { get; set; }
        public short? DisplaySequence { get; set; }
        public decimal? Inherited { get; set; }
        public Criteria Criteria { get; set; }
        public DataEntryTask DataEntryTask { get; set; }
        public NameType NameType { get; set; }

        public DataEntryTaskStep Build()
        {
            var step = new DataEntryTaskStep(Criteria ?? new CriteriaBuilder().Build())
            {
                ScreenName = ScreenName ?? Fixture.String("ScreenName"),
                ScreenId = ScreenId ?? Fixture.Short(),
                DataEntryTaskId = DataEntryTask != null ? DataEntryTask.Id : Fixture.Short(),
                ScreenTitle = ScreenTitle ?? Fixture.String("ScreenTitle"),
                DisplaySequence = DisplaySequence ?? Fixture.Short(),
                Inherited = Inherited
            };

            if (NameType != null)
            {
                step.SetNameType(NameType);
            }

            return step;
        }
    }
}