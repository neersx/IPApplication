using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess.Uspto.PrivatePair
{
    public class CaseCorrelationResolverFacts
    {
        public class ResolveMethod
        {
            readonly CaseCorrelationResolverFixture _fixture = new CaseCorrelationResolverFixture();

            [Fact]
            public void ReturnsCorrelationIdWhenApplicationNumberMatchOneUsPatents()
            {
                _fixture.InprotechCaseResolver
                        .ResolveUsing(Arg.Any<string>())
                        .Returns(
                                 new[]
                                 {
                                     new EligibleCase {CaseKey = 123}
                                 });

                Assert.Equal(123, _fixture.Subject.Resolve(Fixture.String(), out var multipleCases));
                Assert.False(multipleCases);
            }

            [Fact]
            public void ReturnsNullWhenApplicationNumberDoesNotMatchAnyUsPatents()
            {
                _fixture.InprotechCaseResolver
                        .ResolveUsing(Arg.Any<string>())
                        .Returns(new EligibleCase[0]);

                Assert.Null(_fixture.Subject.Resolve(Fixture.String(), out var multipleCases));
                Assert.False(multipleCases);
            }

            [Fact]
            public void ReturnsNullWhenApplicationNumberMatchTooManyUsPatents()
            {
                _fixture.InprotechCaseResolver
                        .ResolveUsing(Arg.Any<string>())
                        .Returns(
                                 new[]
                                 {
                                     new EligibleCase(),
                                     new EligibleCase()
                                 });

                Assert.Null(_fixture.Subject.Resolve(Fixture.String(), out var multipleCases));
                Assert.True(multipleCases);
            }
        }

        public class CaseCorrelationResolverFixture : IFixture<ICaseCorrelationResolver>
        {
            public CaseCorrelationResolverFixture()
            {
                InprotechCaseResolver = Substitute.For<IInprotechCaseResolver>();

                Subject = new CaseCorrelationResolver(InprotechCaseResolver);
            }

            public IInprotechCaseResolver InprotechCaseResolver { get; set; }

            public ICaseCorrelationResolver Subject { get; }
        }
    }
}