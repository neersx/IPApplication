using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items
{
    public class OpenItemNumbersFacts : FactBase
    {
        OpenItemNumbers CreateSubject(string draftPrefix)
        {
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.Read<string>(SiteControls.DRAFTPREFIX).Returns(draftPrefix);

            return new OpenItemNumbers(Db, siteControlReader);
        }

        [Fact]
        public async Task ShouldAcquireOpenItemNumber()
        {
            var entity = new SpecialName().In(Db);
            var staffId = Fixture.Integer();

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal("DN1", r);
            Assert.Equal(1, entity.LastDraftNo);
        }

        [Fact]
        public async Task ShouldAcquireNextOpenItemNumberForSameEntity()
        {
            var entity = new SpecialName().In(Db);
            var staffId = Fixture.Integer();

            new OpenItem { ItemEntityId = entity.Id, OpenItemNo = "DN1" }.In(Db);
            new OpenItem { ItemEntityId = entity.Id, OpenItemNo = "DN2" }.In(Db);

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal("DN3", r);
            Assert.Equal(3, entity.LastDraftNo);
        }

        [Fact]
        public async Task ShouldAcquireNextOpenItemNumberBasedOnLastDraftNumber()
        {
            var lastDraftNumber = Fixture.Short();
            var entity = new SpecialName { LastDraftNo = lastDraftNumber }.In(Db);
            var staffId = Fixture.Integer();

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal($"DN{lastDraftNumber + 1}", r);
            Assert.Equal(lastDraftNumber + 1, entity.LastDraftNo);
        }

        [Fact]
        public async Task ShouldAcquireNextOpenItemNumberBasedOnLastDraftNumberConsideringStaffPrefix()
        {
            var staffId = Fixture.Integer();
            var lastDraftNumber = Fixture.Short();
            var entity = new SpecialName { LastDraftNo = lastDraftNumber }.In(Db);

            new TableAttributes("NAME", staffId.ToString())
            {
                SourceTableId = (short)TableTypes.Office,
                TableCodeId = new Office
                {
                    ItemNoPrefix = "GG"
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal($"DNGG{lastDraftNumber + 1}", r);
            Assert.Equal(lastDraftNumber + 1, entity.LastDraftNo);
        }

        [Fact]
        public async Task ShouldAcquireNextOpenItemNumberForSameEntityConsideringStaffPrefix()
        {
            var entity = new SpecialName().In(Db);
            var staffId = Fixture.Integer();

            new TableAttributes("NAME", staffId.ToString())
            {
                SourceTableId = (short)TableTypes.Office,
                TableCodeId = new Office
                {
                    ItemNoPrefix = "GG"
                }.In(Db).Id
            }.In(Db);

            new OpenItem { ItemEntityId = entity.Id, OpenItemNo = "DNGG1" }.In(Db);
            new OpenItem { ItemEntityId = entity.Id, OpenItemNo = "DN2" }.In(Db);

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal("DNGG2", r);
            Assert.Equal(2, entity.LastDraftNo);
        }

        [Fact]
        public async Task ShouldAcquireOpenItemNumberConsideringStaffPrefix()
        {
            var entity = new SpecialName().In(Db);
            var staffId = Fixture.Integer();

            new TableAttributes("NAME", staffId.ToString())
            {
                SourceTableId = (short)TableTypes.Office,
                TableCodeId = new Office
                {
                    ItemNoPrefix = "GG"
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject("DN");

            var r = await subject.AcquireNextDraftNumber(entity.Id, staffId);

            Assert.Equal("DNGG1", r);
            Assert.Equal(1, entity.LastDraftNo);
        }
    }
}