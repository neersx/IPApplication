using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations
{
    public class SingleNameConsolidationFacts : FactBase
    {
        public SingleNameConsolidationFacts()
        {
            _executeAs = new User().In(Db).Id;
            _to = new Name().In(Db).Id;
            _from = new Name().In(Db).Id;
        }

        readonly ITransactionRecordal _transactionRecordal = Substitute.For<ITransactionRecordal>();
        readonly IConsolidationSettings _consolidationSettings = Substitute.For<IConsolidationSettings>();
        readonly IDerivedAttention _derivedAttention = Substitute.For<IDerivedAttention>();

        readonly INameConsolidator _consolidator1 = Substitute.For<INameConsolidator>();
        readonly INameConsolidator _consolidator2 = Substitute.For<INameConsolidator>();

        readonly int _executeAs;
        readonly int _to;
        readonly int _from;

        SingleNameConsolidation CreateSubject()
        {
            var consolidatorProvider = Substitute.For<IConsolidatorProvider>();
            consolidatorProvider.Provide().Returns(new[] {_consolidator1, _consolidator2});

            return new SingleNameConsolidation(Db, _transactionRecordal, consolidatorProvider, _consolidationSettings, _derivedAttention, Fixture.Today);
        }

        [Fact]
        public async Task ShouldDeleteNameAsIndicated()
        {
            const bool keepConsolidatedName = false;

            var subject = CreateSubject();

            await subject.Consolidate(_executeAs, _from, _to, Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            Assert.Empty(Db.Set<Name>().Where(_ => _.Id == _from));
        }

        [Fact]
        public async Task ShouldForwardCorrectParametersToAllConsolidators()
        {
            var subject = CreateSubject();

            var keepAddressHistory = Fixture.Boolean();
            var keepTelecomHistory = Fixture.Boolean();
            var keepConsolidatedName = Fixture.Boolean();

            var nameTo = Db.Set<Name>().Single(_ => _.Id == _to);
            var nameFrom = Db.Set<Name>().Single(_ => _.Id == _from);

            await subject.Consolidate(_executeAs, _from, _to, keepAddressHistory, keepTelecomHistory, keepConsolidatedName);

            _consolidator1.Received(1)
                          .Consolidate(nameTo, nameFrom,
                                       Arg.Is<ConsolidationOption>(_ => _.KeepConsolidatedName == keepConsolidatedName && _.KeepAddressHistory == keepAddressHistory && _.KeepTelecomHistory == keepTelecomHistory))
                          .IgnoreAwaitForNSubstituteAssertion();

            _consolidator2.Received(1)
                          .Consolidate(nameTo, nameFrom,
                                       Arg.Is<ConsolidationOption>(_ => _.KeepConsolidatedName == keepConsolidatedName && _.KeepAddressHistory == keepAddressHistory && _.KeepTelecomHistory == keepTelecomHistory))
                          .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldKeepNameAsCeasedIfIndicated()
        {
            const bool keepConsolidatedName = true;

            var subject = CreateSubject();

            await subject.Consolidate(_executeAs, _from, _to, Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            Assert.Single(Db.Set<Name>().Where(_ => _.Id == _from));
            Assert.Equal(Fixture.Today(), Db.Set<Name>().Single(_ => _.Id == _from).DateCeased);
        }

        [Fact]
        public async Task ShouldKeepTrackOfNameReplaced()
        {
            var subject = CreateSubject();

            await subject.Consolidate(_executeAs, _from, _to, Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            Assert.NotNull(Db.Set<NameReplaced>().SingleOrDefault(_ => _.NewNameNo == _to && _.OldNameNo == _from));
        }

        [Fact]
        public async Task ShouldRecalculateDerivedAttention()
        {
            var subject = CreateSubject();

            await subject.Consolidate(_executeAs, _from, _to, Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            _derivedAttention.Received(1).Recalculate(_executeAs, _to).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldRecordTransactionUnderTheEndUserWhoScheduledTheRequest()
        {
            var subject = CreateSubject();

            await subject.Consolidate(_executeAs, _from, _to, Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var endUserSubmittedTheConsolidationRequest = Db.Set<User>().Single(_ => _.Id == _executeAs);
            var nameBeingConsolidatedInto = Db.Set<Name>().Single(_ => _.Id == _to);

            _transactionRecordal.Received(1)
                                .ExecuteTransactionFor(endUserSubmittedTheConsolidationRequest, nameBeingConsolidatedInto, NameTransactionMessageIdentifier.AmendedName);
        }
    }
}