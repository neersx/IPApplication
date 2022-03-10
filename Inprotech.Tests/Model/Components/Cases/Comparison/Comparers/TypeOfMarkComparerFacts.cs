using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class TypeOfMarkComparerFacts : FactBase
    {
        TypeOfMarkComparer CreateSubject(InMemoryDbContext db)
        {
            var preferredCulture = Substitute.For<IPreferredCultureResolver>();
            preferredCulture.Resolve().ReturnsForAnyArgs("en-Us");

            return new TypeOfMarkComparer(db, preferredCulture);
        }

        readonly TypeOfMarkComparisonScenarioBuilder _scenarioBuilder = new TypeOfMarkComparisonScenarioBuilder();
        readonly ComparisonResult _comparisonResult = new ComparisonResult(Fixture.String());

        [Theory]
        [InlineData("Word Mark", "WORD MARK", true, false, false)]
        [InlineData("Word Mark", "WORD MARK", false, true, true)]
        public void ComparesTypeOfMark(string inproTypeOfMark, string sourceTypeOfMark, bool mapValue, bool expectedIsDifferent,
                                        bool expectedIsUpdatable)
        {
            var @case = new CaseBuilder
            {
                 TypeOfMark = new TableCodeBuilder
                 {
                     TableCode = 5102,
                     TableType = (short?)TableTypes.TypeOfMark,
                     Description = inproTypeOfMark
                 }.Build().In(Db)
            }.Build().In(Db);

            _scenarioBuilder.TypeOfMark = new TypeOfMark
            {
                Id = mapValue ? @case.TypeOfMarkId : new TableCodeBuilder
                {
                    TableCode = 5103,
                    TableType = (short?) TableTypes.TypeOfMark,
                    Description = Fixture.String()
                }.Build().In(Db).Id,
                Description = sourceTypeOfMark
            };

            var f = CreateSubject(Db);
            f.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(inproTypeOfMark, _comparisonResult.Case.TypeOfMark.OurValue);
            Assert.Equal(sourceTypeOfMark, _comparisonResult.Case.TypeOfMark.TheirDescription);
            Assert.Equal(expectedIsDifferent, _comparisonResult.Case.TypeOfMark.Different);
            Assert.Equal(expectedIsUpdatable, _comparisonResult.Case.TypeOfMark.Updateable);
        }
    }
}
