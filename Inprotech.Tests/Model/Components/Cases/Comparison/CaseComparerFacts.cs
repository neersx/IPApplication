using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Model.Components.Cases.Comparison.Builders;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using NSubstitute;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Model.Components.Cases.Comparison
{
    public class CaseComparerFacts
    {
        public class CompareMethod : FactBase
        {
            [Fact]
            public async Task CallsFindComparisonScenarios()
            {
                var f = new CaseComparerFixture();
                var inproCase = new CaseBuilder().Build();

                await f.Subject.Compare(inproCase, "CPAXML", "EPO");

                f.CpaXmlComparision.Received(1).FindComparisonScenarios("CPAXML", "EPO");
            }

            [Fact]
            public async Task ComparesAllScenarios()
            {
                var comparer1 = Substitute.For<ISpecificComparer>();
                var comparer2 = Substitute.For<ISpecificComparer>();

                var f = new CaseComparerFixture(new[] {comparer1, comparer2});
                var inproCase = new CaseBuilder().Build();

                await f.Subject.Compare(inproCase, "CPAXML", "EPO");

                comparer1.Received(1).Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(), Arg.Any<ComparisonResult>());
                comparer2.Received(1).Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(), Arg.Any<ComparisonResult>());
            }

            [Fact]
            public async Task ReturnsComparisonResult()
            {
                var f = new CaseComparerFixture();
                var inproCase = new CaseBuilder().Build();
                var returnCase = new InprotechKaizen.Model.Components.Cases.Comparison.Results.Case {Ref = new Value<string> {OurValue = "123", TheirValue = "abc"}};
                f.Comparer.When(
                                _ =>
                                    _.Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(),
                                              Arg.Any<ComparisonResult>()))
                 .Do(
                     info => { ((ComparisonResult) info.Args()[2]).Case = returnCase; });

                f.CaseSecurity.CanAcceptChanges(Arg.Any<Case>()).Returns(true);

                var result = await f.Subject.Compare(inproCase, "CPAXML", "EPO");

                Assert.Equal(returnCase.Ref.OurValue, result.Case.Ref.OurValue);
                Assert.Equal(returnCase.Ref.TheirValue, result.Case.Ref.TheirValue);
                Assert.True(result.Updateable);
            }

            [Fact]
            public async Task ReturnsMappingErrors()
            {
                var f = new CaseComparerFixture();
                var inproCase = new CaseBuilder().Build();

                f.Comparer.When(
                                _ =>
                                    _.Compare(Arg.Any<Case>(), Arg.Any<IEnumerable<ComparisonScenario>>(),
                                              Arg.Any<ComparisonResult>()))
                 .Do(
                     info =>
                     {
                         throw new FailedMappingException(new[]
                         {
                             new FailedSourceBuilder {TypeId = 1, Code = "B", Name = "Bob"}.Build(),
                             new FailedSourceBuilder {TypeId = 1, Code = "C", Name = "Bob"}.Build()
                         });
                     });

                var result = await f.Subject.Compare(inproCase, "CPAXML", "EPO");

                var message = ((IEnumerable<string>) result.Errors.First().Message).ToArray();

                Assert.NotEmpty(result.Errors);
                Assert.NotNull(message);
                Assert.Equal(ComparisonErrorTypes.MappingError, result.Errors.First().Type);
                Assert.Equal("Bob", result.Errors.First().Key);
                Assert.Equal("B", message.First());
                Assert.Equal("C", message.Last());
            }
        }

        public class CaseComparerFixture : IFixture<CaseComparer>
        {
            public CaseComparerFixture()
            {
                CpaXmlComparision = Substitute.For<ICpaXmlComparison>();
                CaseSecurity = Substitute.For<ICaseSecurity>();
                Comparer = Substitute.For<ISpecificComparer>();
                
                Subject = new CaseComparer(CpaXmlComparision, CaseSecurity, new[] {Comparer});
            }

            public CaseComparerFixture(IEnumerable<ISpecificComparer> comparers)
            {
                CpaXmlComparision = Substitute.For<ICpaXmlComparison>();
                CaseSecurity = Substitute.For<ICaseSecurity>();

                Subject = new CaseComparer(CpaXmlComparision, CaseSecurity, comparers);
            }

            public ICpaXmlComparison CpaXmlComparision { get; }
            public ICaseSecurity CaseSecurity { get; }
            public ISpecificComparer Comparer { get; }
            public CaseComparer Subject { get; }
        }
    }
}