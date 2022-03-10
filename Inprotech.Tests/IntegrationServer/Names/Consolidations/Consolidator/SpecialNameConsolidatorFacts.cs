using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class SpecialNameConsolidatorFacts : FactBase
    {
        public SpecialNameConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateSpecialName()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromSpecialName = new SpecialName(Fixture.Boolean(), _from)
            {
                IsIpOffice = Fixture.Decimal(),
                IsBankOrFinancialInstitution = Fixture.Decimal(),
                LastOpenItemNo = Fixture.Integer(),
                LastDraftNo = Fixture.Integer(),
                LastAccountsReceivableNo = Fixture.Integer(),
                LastAccountsPayableNo = Fixture.Integer(),
                LastInternalItemNo = Fixture.Integer(),
                Currency = Fixture.String()
            }.In(Db);

            var subject = new SpecialNameConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<SpecialName>().Where(_ => _.Id == _to.Id));
            Assert.Single(Db.Set<SpecialName>().Where(_ => _.Id == _from.Id));
            Assert.Equal(fromSpecialName.IsEntity, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsEntity);
            Assert.Equal(fromSpecialName.IsIpOffice, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsIpOffice);
            Assert.Equal(fromSpecialName.IsBankOrFinancialInstitution, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsBankOrFinancialInstitution);
            Assert.Equal(fromSpecialName.LastOpenItemNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastOpenItemNo);
            Assert.Equal(fromSpecialName.LastDraftNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastDraftNo);
            Assert.Equal(fromSpecialName.LastInternalItemNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastInternalItemNo);
            Assert.Equal(fromSpecialName.LastAccountsReceivableNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastAccountsReceivableNo);
            Assert.Equal(fromSpecialName.LastAccountsPayableNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastAccountsPayableNo);
            Assert.Equal(fromSpecialName.Currency, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).Currency);
        }

        [Fact]
        public async Task ShouldNotConsolidateSpecialNameIfAlreadyExists()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var currentSpecialName = new SpecialName(Fixture.Boolean(), _to)
            {
                IsIpOffice = Fixture.Decimal(),
                IsBankOrFinancialInstitution = Fixture.Decimal(),
                LastOpenItemNo = Fixture.Integer(),
                LastDraftNo = Fixture.Integer(),
                LastAccountsReceivableNo = Fixture.Integer(),
                LastAccountsPayableNo = Fixture.Integer(),
                LastInternalItemNo = Fixture.Integer(),
                Currency = Fixture.String()
            }.In(Db);

            new SpecialName(Fixture.Boolean(), _from)
            {
                IsIpOffice = Fixture.Decimal(),
                IsBankOrFinancialInstitution = Fixture.Decimal(),
                LastOpenItemNo = Fixture.Integer(),
                LastDraftNo = Fixture.Integer(),
                LastAccountsReceivableNo = Fixture.Integer(),
                LastAccountsPayableNo = Fixture.Integer(),
                LastInternalItemNo = Fixture.Integer(),
                Currency = Fixture.String()
            }.In(Db);

            var subject = new SpecialNameConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<SpecialName>().Where(_ => _.Id == _to.Id));
            Assert.Single(Db.Set<SpecialName>().Where(_ => _.Id == _from.Id));
            Assert.Equal(currentSpecialName.IsEntity, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsEntity);
            Assert.Equal(currentSpecialName.IsIpOffice, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsIpOffice);
            Assert.Equal(currentSpecialName.IsBankOrFinancialInstitution, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).IsBankOrFinancialInstitution);
            Assert.Equal(currentSpecialName.LastOpenItemNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastOpenItemNo);
            Assert.Equal(currentSpecialName.LastDraftNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastDraftNo);
            Assert.Equal(currentSpecialName.LastInternalItemNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastInternalItemNo);
            Assert.Equal(currentSpecialName.LastAccountsReceivableNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastAccountsReceivableNo);
            Assert.Equal(currentSpecialName.LastAccountsPayableNo, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).LastAccountsPayableNo);
            Assert.Equal(currentSpecialName.Currency, Db.Set<SpecialName>().Single(_ => _.Id == _to.Id).Currency);
        }
    }
}