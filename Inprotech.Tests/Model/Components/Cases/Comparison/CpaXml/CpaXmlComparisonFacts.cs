using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml
{
    public class CpaXmlComparisonFacts
    {
        public class CpaXmlComparisonFixture : IFixture<CpaXmlComparison>
        {
            public CpaXmlComparisonFixture()
            {
                ComparisonPreprocessor = Substitute.For<IComparisonPreprocessor>();
                ComparisonPreprocessor
                    .MapCodes(Arg.Any<IEnumerable<ComparisonScenario>>(), Arg.Any<string>())
                    .Returns(x => x[0]);

                CpaXmlCaseDetailsLoader = Substitute.For<ICpaXmlCaseDetailsLoader>();

                ComparisonScenarioResolver = Substitute.For<IComparisonScenarioResolver>();

                ComparisonScenarioResolvers = new List<IComparisonScenarioResolver>(
                                                                                    new[] {ComparisonScenarioResolver}
                                                                                   );

                Subject = new CpaXmlComparison(ComparisonPreprocessor, CpaXmlCaseDetailsLoader,
                                               ComparisonScenarioResolvers);
            }

            public IComparisonPreprocessor ComparisonPreprocessor { get; set; }

            public ICpaXmlCaseDetailsLoader CpaXmlCaseDetailsLoader { get; set; }

            public List<IComparisonScenarioResolver> ComparisonScenarioResolvers { get; set; }

            public IComparisonScenarioResolver ComparisonScenarioResolver { get; set; }

            public CpaXmlComparison Subject { get; set; }

            public CpaXmlComparisonFixture WithCaseDetails(CaseDetails caseDetails = null, IEnumerable<TransactionMessageDetails> messageDetails = null)
            {
                CpaXmlCaseDetailsLoader.Load(Arg.Any<string>())
                                       .Returns((caseDetails ?? new CaseDetails("P", "AU"), messageDetails ?? Enumerable.Empty<TransactionMessageDetails>()));

                return this;
            }

            public CpaXmlComparisonFixture Resolves(params ComparisonScenario[] scenarios)
            {
                ComparisonScenarioResolver
                    .Resolve(Arg.Any<CaseDetails>(), Arg.Any<IEnumerable<TransactionMessageDetails>>())
                    .Returns(scenarios);

                return this;
            }

            public CpaXmlComparisonFixture Allows(string sourceSystem, params ComparisonScenario[] scenarios)
            {
                ComparisonScenarioResolver.IsAllowed(sourceSystem).Returns(true);

                return this;
            }
        }

        [Fact]
        public void FindComparisonScenarios()
        {
            var a = new ComparisonScenario(ComparisonType.OfficialNumbers);
            var b = new ComparisonScenario(ComparisonType.Events);
            
            var sourceSystem = Fixture.String();

            var f = new CpaXmlComparisonFixture()
                    .WithCaseDetails()
                    .Allows(sourceSystem)
                    .Resolves(a, b);

            var r = f.Subject.FindComparisonScenarios(Fixture.String(), sourceSystem).ToArray();

            Assert.Equal(2, r.Count());
            Assert.Equal(a, r.First());
            Assert.Equal(b, r.Last());
        }

        [Fact]
        public void ExcludeDisallowedComparisonScenario()
        {
            var a = new ComparisonScenario(ComparisonType.OfficialNumbers);
            var b = new ComparisonScenario(ComparisonType.Events);
            
            var sourceSystem = Fixture.String();

            var f = new CpaXmlComparisonFixture()
                    .WithCaseDetails()
                    .Resolves(a, b);

            var r = f.Subject.FindComparisonScenarios(Fixture.String(), sourceSystem).ToArray();

            Assert.Empty(r);
        }
    }
}