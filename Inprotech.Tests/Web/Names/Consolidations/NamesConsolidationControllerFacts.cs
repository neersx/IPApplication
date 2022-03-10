using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Names.Consolidations;
using Inprotech.Web.Names.Consolidations;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Consolidations
{
    public class NamesConsolidationControllerFacts
    {
        class NamesConsolidationControllerFixture : IFixture<NamesConsolidationController>
        {
            public NamesConsolidationControllerFixture()
            {
                var securityUser = Substitute.For<ISecurityContext>();
                securityUser.User.Returns(new User());

                SiteControlReader = Substitute.For<ISiteControlReader>();

                ConfigureJob = Substitute.For<IConfigureJob>();
                NamesConsolidationValidator = Substitute.For<INamesConsolidationValidator>();
                Subject = new NamesConsolidationController(securityUser, SiteControlReader, NamesConsolidationValidator, ConfigureJob);
            }

            public ISiteControlReader SiteControlReader { get; }

            public IConfigureJob ConfigureJob { get; }

            public INamesConsolidationValidator NamesConsolidationValidator { get; }

            public NamesConsolidationController Subject { get; }

            public NamesConsolidationControllerFixture WithValidationResultForAll(bool financialCheckPerformed, IEnumerable<NamesConsolidationResult> errors)
            {
                NamesConsolidationValidator.Validate(Arg.Any<int>(), Arg.Any<int[]>(), Arg.Any<bool>()).Returns((financialCheckPerformed, errors));
                return this;
            }

            public NamesConsolidationControllerFixture WithSchedulesSuccessful()
            {
                ConfigureJob.TryCreateOneTimeJob(nameof(NameConsolidationJob), Arg.Any<NameConsolidationArgs>()).Returns(true);
                return this;
            }
        }

        [Fact]
        public async Task ShouldReturnErrors()
        {
            var f = new NamesConsolidationControllerFixture()
                .WithValidationResultForAll(false, new[]
                {
                    new NamesConsolidationResult(Fixture.Integer(), Fixture.String()),
                    new NamesConsolidationResult(Fixture.Integer(), Fixture.String(), true)
                });

            var r = await f.Subject.Consolidate(Fixture.Integer(), new NamesConsolidationController.ConsolidationData
            {
                NamesToBeConsolidated = new[] {Fixture.Integer(), Fixture.Integer()}
            });

            Assert.False((bool) r.Status);
            Assert.Equal(2, ((NamesConsolidationResult[]) r.Errors).Length);
        }

        [Fact]
        public async Task ShouldReturnSuccessWhenIgnoreValidationsAndFinancialCheckPerformed()
        {
            var f = new NamesConsolidationControllerFixture()
                    .WithSchedulesSuccessful()
                    .WithValidationResultForAll(true, new[]
                    {
                        new NamesConsolidationResult(Fixture.Integer(), Fixture.String())
                    });

            var r = await f.Subject.Consolidate(Fixture.Integer(), new NamesConsolidationController.ConsolidationData
            {
                NamesToBeConsolidated = new[] {Fixture.Integer(), Fixture.Integer()},
                IgnoreFinancialWarnings = true
            });
            Assert.True((bool) r.Status);
        }

        [Fact]
        public async Task ShouldReturnSuccessWhenNoErrors()
        {
            var f = new NamesConsolidationControllerFixture()
                    .WithSchedulesSuccessful()
                    .WithValidationResultForAll(false, Enumerable.Empty<NamesConsolidationResult>());

            var r = await f.Subject.Consolidate(Fixture.Integer(), new NamesConsolidationController.ConsolidationData
            {
                NamesToBeConsolidated = new[] {Fixture.Integer(), Fixture.Integer()}
            });
            Assert.True((bool) r.Status);
        }

        [Fact]
        public async Task ShouldSendJobArgsToOrchestrator()
        {
            var f = new NamesConsolidationControllerFixture()
                    .WithSchedulesSuccessful()
                    .WithValidationResultForAll(false, Enumerable.Empty<NamesConsolidationResult>());

            var targetNameId = Fixture.Integer();
            var nameToBeConsolidated = Fixture.Integer();
            var keepTelecomHistory = Fixture.Boolean();
            var keepAddressHistory = Fixture.Boolean();
            var keepConsolidatedName = Fixture.Boolean();

            f.SiteControlReader.Read<bool?>(SiteControls.KeepConsolidatedName).Returns(keepConsolidatedName);

            await f.Subject.Consolidate(targetNameId, new NamesConsolidationController.ConsolidationData
            {
                NamesToBeConsolidated = new[] {nameToBeConsolidated},
                KeepAddressHistory = keepAddressHistory,
                KeepTelecomHistory = keepTelecomHistory
            });

            f.ConfigureJob
             .Received(1)
             .TryCreateOneTimeJob("NameConsolidationJob",
                                  Arg.Is<NameConsolidationArgs>(_ => _.KeepTelecomHistory == keepTelecomHistory &&
                                                                     _.KeepAddressHistory == keepAddressHistory &&
                                                                     _.KeepConsolidatedName == keepConsolidatedName &&
                                                                     _.TargetId == targetNameId &&
                                                                     _.NameIds.Contains(nameToBeConsolidated)));
        }

        [Fact]
        public async Task ShouldThrowInvalidOperationExceptionWhenThereIsAlreadyConsolidationInProgress()
        {
            var f = new NamesConsolidationControllerFixture()
                .WithValidationResultForAll(false, Enumerable.Empty<NamesConsolidationResult>());

            await Assert.ThrowsAsync<InvalidOperationException>(async () => await f.Subject.Consolidate(Fixture.Integer(), new NamesConsolidationController.ConsolidationData
            {
                NamesToBeConsolidated = new[] {Fixture.Integer()}
            }));
        }
    }
}