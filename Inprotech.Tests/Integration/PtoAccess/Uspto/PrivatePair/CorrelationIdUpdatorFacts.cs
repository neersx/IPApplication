using System;
using Inprotech.Integration;
using Inprotech.Integration.Persistence;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess.Uspto.PrivatePair
{
    public class CorrelationIdUpdatorFacts
    {
        public class UpdateIfRequiredMethod
        {
            [Theory]
            [InlineData(DataSourceType.Epo)]
            [InlineData(DataSourceType.UsptoTsdr)]
            public void ReturnsIfCaseIsNotFromPrivatePair(DataSourceType source)
            {
                var @case = new Case
                {
                    Source = source
                };

                var f = new CorrelationIdUpdatorFixture();
                f.Subject.UpdateIfRequired(@case);

                f.CaseCorrelationResolver.DidNotReceiveWithAnyArgs().Resolve(Arg.Any<string>(), out _);
                f.Repository.DidNotReceive().SaveChanges();
            }

            [Theory]
            [InlineData(null)]
            [InlineData(1)]
            public void ShouldNotSaveIfCorrelationIdAreBothSame(int? currentlyHeldCorrelationId)
            {
                var @case = new Case
                {
                    ApplicationNumber = "1234",
                    CorrelationId = currentlyHeldCorrelationId
                };

                var f = new CorrelationIdUpdatorFixture()
                    .WithCaseCorrelationId(currentlyHeldCorrelationId);

                f.Subject.UpdateIfRequired(@case);

                f.Repository.DidNotReceive().SaveChanges();
            }

            [Fact]
            public void RetunsIfNoCasePassed()
            {
                var f = new CorrelationIdUpdatorFixture();
                f.Subject.UpdateIfRequired(null);

                f.CaseCorrelationResolver.DidNotReceiveWithAnyArgs().Resolve(Arg.Any<string>(), out _);
                f.Repository.DidNotReceive().SaveChanges();
            }

            [Fact]
            public void ShouldNullifyCorrelationIdAndThrowExceptionWhenMultipleMatchesFound()
            {
                var @case = new Case
                {
                    ApplicationNumber = "1234",
                    CorrelationId = Fixture.Integer()
                };

                var f = new CorrelationIdUpdatorFixture()
                    .WithMultipleCasesHavingSameApplicationNumbers();

                var exception = Record.Exception(
                                                 () => { f.Subject.UpdateIfRequired(@case); });

                Assert.NotNull(exception);
                f.Repository.Received(1).SaveChanges();

                Assert.Null(@case.CorrelationId);
                Assert.Equal(Fixture.Today(), @case.UpdatedOn);
            }

            [Fact]
            public void ShouldSaveWhenCorrelationIsDifferent()
            {
                var newCorrelationId = Fixture.Integer();

                var @case = new Case
                {
                    ApplicationNumber = "1234",
                    CorrelationId = null
                };
                var f = new CorrelationIdUpdatorFixture()
                    .WithCaseCorrelationId(newCorrelationId);

                f.Subject.UpdateIfRequired(@case);

                f.Repository.Received(1).SaveChanges();
            }
        }

        public class CheckIfValidMethod : FactBase
        {
            [Theory]
            [InlineData(DataSourceType.Epo)]
            [InlineData(DataSourceType.UsptoTsdr)]
            public void ReturnsIfCaseIsNotFromPrivatePair(DataSourceType source)
            {
                var @case = new Case
                {
                    Source = source
                };

                var f = new CorrelationIdUpdatorFixture();
                f.Subject.CheckIfValid(@case);

                f.CaseCorrelationResolver.DidNotReceiveWithAnyArgs().Resolve(Arg.Any<string>(), out _);
            }

            [Fact]
            public void RetunsIfNoCasePassed()
            {
                var f = new CorrelationIdUpdatorFixture();
                f.Subject.CheckIfValid(null);

                f.CaseCorrelationResolver.DidNotReceiveWithAnyArgs().Resolve(Arg.Any<string>(), out _);
            }

            [Fact]
            public void ThrowsExceptionWithoutNullifyingWhenCorrelationDoNotMatch()
            {
                var existingCorrelationId = Fixture.Integer();
                var resolvedCorrelationId = Fixture.Integer();

                var @case = new Case
                {
                    CorrelationId = existingCorrelationId
                }.In(Db);

                var f = new CorrelationIdUpdatorFixture()
                    .WithCaseCorrelationId(resolvedCorrelationId);

                var exception = Record.Exception(
                                                 () => { f.Subject.CheckIfValid(@case); });

                Assert.IsType<CorrespondingCaseChangedException>(exception);
                Assert.NotNull(@case.CorrelationId);
            }

            [Fact]
            public void ThrowsExceptionWithoutNullifyingWhenMultipleMatchesFound()
            {
                var @case = new Case
                {
                    CorrelationId = Fixture.Integer()
                }.In(Db);

                var f = new CorrelationIdUpdatorFixture()
                    .WithMultipleCasesHavingSameApplicationNumbers();

                var exception = Record.Exception(
                                                 () => { f.Subject.CheckIfValid(@case); });

                Assert.IsType<MultiplePossibleInprotechCasesException>(exception);
                Assert.NotNull(@case.CorrelationId);
            }
        }

        public class CorrelationIdUpdatorFixture : IFixture<ICorrelationIdUpdator>
        {
            public CorrelationIdUpdatorFixture()
            {
                Repository = Substitute.For<IRepository>();
                CaseCorrelationResolver = Substitute.For<ICaseCorrelationResolver>();
                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                Subject = new CorrelationIdUpdator(Repository, CaseCorrelationResolver, SystemClock);
            }

            public IRepository Repository { get; }

            public ICaseCorrelationResolver CaseCorrelationResolver { get; }

            public Func<DateTime> SystemClock { get; set; }

            public ICorrelationIdUpdator Subject { get; }

            public CorrelationIdUpdatorFixture WithCaseCorrelationId(int? value)
            {
                CaseCorrelationResolver.Resolve(Arg.Any<string>(), out _)
                                       .Returns(x =>
                                       {
                                           x[1] = false;
                                           return value;
                                       });
                return this;
            }

            public CorrelationIdUpdatorFixture WithMultipleCasesHavingSameApplicationNumbers()
            {
                CaseCorrelationResolver.Resolve(Arg.Any<string>(), out _)
                                       .Returns(x =>
                                       {
                                           x[1] = true;
                                           return null;
                                       });
                return this;
            }
        }
    }
}