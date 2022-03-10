using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class CaseHeaderComparerFacts : FactBase
    {
        public CaseHeaderComparerFacts()
        {
            _fixture = new CaseHeaderComparerFixture(Db);
        }

        readonly CaseHeaderComparisonScenarioBuilder _scenarioBuilder = new CaseHeaderComparisonScenarioBuilder();
        readonly CaseHeaderComparerFixture _fixture;
        readonly ComparisonResult _comparisonResult = new ComparisonResult(Fixture.String());

        [Theory]
        [InlineData("Ref", "REF", false)]
        [InlineData("Ref", "ref", false)]
        [InlineData("Ref", "REF1", true)]
        [InlineData("Ref1", "REF", true)]
        [InlineData("Ref1", "", true)]
        [InlineData("Ref1", null, true)]
        public void ComparesIrn(string inproIrn, string sourceIrn, bool expectedIsDifferent)
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                Ref = sourceIrn
            };

            var @case = new CaseBuilder
            {
                Irn = inproIrn
            }.Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(inproIrn, _comparisonResult.Case.Ref.OurValue);
            Assert.Equal(sourceIrn, _comparisonResult.Case.Ref.TheirValue);
            Assert.Equal(expectedIsDifferent, _comparisonResult.Case.Ref.Different);
        }

        [Theory]
        [InlineData("title", "TITLE", false, false)]
        [InlineData("Title", "title", false, false)]
        [InlineData("Title", "TITLE1", true, true)]
        [InlineData("Title1", "TITLE", true, true)]
        [InlineData("Title1", "", true, false)]
        [InlineData("Title1", null, true, false)]
        public void ComparesTitle(string inproTitle, string sourceTitle, bool expectedIsDifferent,
                                  bool expectedIsUpdatable)
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                Title = sourceTitle
            };

            var @case = new CaseBuilder
            {
                Title = inproTitle
            }.Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(inproTitle, _comparisonResult.Case.Title.OurValue);
            Assert.Equal(sourceTitle, _comparisonResult.Case.Title.TheirValue);
            Assert.Equal(expectedIsDifferent, _comparisonResult.Case.Title.Different);
            Assert.Equal(expectedIsUpdatable, _comparisonResult.Case.Title.Updateable);
        }

        [Theory]
        [InlineData("dead", "DEAD", false)]
        [InlineData("Dead", "dead", false)]
        [InlineData("Dead", "DEAD1", true)]
        [InlineData("Dead1", "DEAD", true)]
        [InlineData("Dead1", "", true)]
        [InlineData("Dead1", null, true)]
        public void ComparesStatus(string inproStatus, string sourceStatus, bool expectedIsDifferent)
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                Status = sourceStatus
            };

            var @case = new CaseBuilder
            {
                Status = new StatusBuilder
                {
                    Name = inproStatus
                }.Build()
            }.Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(inproStatus, _comparisonResult.Case.Status.OurValue);
            Assert.Equal(sourceStatus, _comparisonResult.Case.Status.TheirValue);
            Assert.Equal(expectedIsDifferent, _comparisonResult.Case.Status.Different);
            Assert.Equal(false, _comparisonResult.Case.Status.Updateable);
        }

        public class CaseHeaderComparerFixture : IFixture<CaseHeaderComparer>
        {
            public CaseHeaderComparerFixture(InMemoryDbContext db)
            {
                ClassStringComparer = Substitute.For<IClassStringComparer>();
                ClassStringComparer.Equals(Arg.Any<string>(), Arg.Any<string>())
                                   .Returns(true);
                DbContext = db;
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                PreferredCulture.Resolve().ReturnsForAnyArgs("en-Us");

                Subject = new CaseHeaderComparer(DbContext, PreferredCulture, ClassStringComparer);
            }

            public IClassStringComparer ClassStringComparer { get; set; }

            public IDbContext DbContext { get; set; }
            public IPreferredCultureResolver PreferredCulture { get; set; }

            public CaseHeaderComparer Subject { get; set; }
        }

        [Fact]
        public void ComparesInternationalClasses()
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                IntClasses = "1,2,3"
            };

            var @case = new CaseBuilder().Build();
            @case.IntClasses = "01,02,03";

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.NotNull(_comparisonResult.Case.IntClasses);

            _fixture.ClassStringComparer.Received(1).Equals("01,02,03", "1,2,3");
        }

        [Fact]
        public void ComparesLocalClasses()
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                LocalClasses = "1,2,3"
            };

            var @case = new CaseBuilder().Build();
            @case.LocalClasses = "01,02,03";

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.NotNull(_comparisonResult.Case.LocalClasses);

            _fixture.ClassStringComparer.Received(1).Equals("01,02,03", "1,2,3");
        }

        [Fact]
        public void DoesNotReturnIfClassesFromBothSourcesAreNull()
        {
            var @case = new CaseBuilder().Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Null(_comparisonResult.Case.IntClasses);
            Assert.Null(_comparisonResult.Case.LocalClasses);
        }

        [Fact]
        public void ReturnsCaseId()
        {
            var @case = new CaseBuilder().Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(@case.Id, _comparisonResult.Case.CaseId);
        }

        [Fact]
        public void ReturnsCountryAndPropertyType()
        {
            var @case = new CaseBuilder().Build().In(Db);

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(@case.Country.Name, _comparisonResult.Case.Country.OurValue);
            Assert.Equal(@case.PropertyType.Name, _comparisonResult.Case.PropertyType.OurValue);
        }

        [Fact]
        public void ReturnsStatusDate()
        {
            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                StatusDate = Fixture.Today()
            };

            var @case = new CaseBuilder().Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Null(_comparisonResult.Case.StatusDate.OurValue);
            Assert.Equal(Fixture.Today(), _comparisonResult.Case.StatusDate.TheirValue);
            Assert.Equal(true, _comparisonResult.Case.StatusDate.Different);
            Assert.Equal(false, _comparisonResult.Case.StatusDate.Updateable);
        }

        [Fact]
        public void ReturnsSourceId()
        {
            var sourceId = Fixture.String();

            _scenarioBuilder.CaseHeader = new CaseHeader
            {
                Id = sourceId
            };

            var @case = new CaseBuilder().Build();

            _fixture.Subject.Compare(@case, new[] {_scenarioBuilder.Build()}, _comparisonResult);

            Assert.Equal(sourceId, _comparisonResult.Case.SourceId);
        }
    }
}