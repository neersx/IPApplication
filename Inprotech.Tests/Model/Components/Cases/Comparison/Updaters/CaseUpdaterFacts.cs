using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class CaseUpdaterFacts
    {
        public class UpdateMethod : FactBase
        {
            [Fact]
            public void UpdatesTitle()
            {
                var @case = new CaseBuilder().Build();
                var comparedCase = new Case
                {
                    Title = new Value<string>
                    {
                        OurValue = "A",
                        TheirValue = "B",
                        Different = true,
                        Updateable = true,
                        Updated = true
                    }
                };

                var subject = new CaseUpdater();
                subject.UpdateTitle(@case, comparedCase);

                Assert.Equal("B", @case.Title);
            }

            [Fact]
            public void UpdatesTypeOfMark()
            {
                var @case = new CaseBuilder().Build();
                var comparedCase = new Case
                {
                    TypeOfMark = new Value<string>
                    {
                        OurValue = string.Empty,
                        TheirDescription = "WORD ONLY",
                        TheirValue = "5102",
                        Different = true,
                        Updateable = true,
                        Updated = true
                    }
                };

                var subject = new CaseUpdater();
                subject.UpdateTypeOfMark(@case, comparedCase);

                Assert.Equal(int.Parse(comparedCase.TypeOfMark.TheirValue), @case.TypeOfMarkId);
            }
        }
    }
}