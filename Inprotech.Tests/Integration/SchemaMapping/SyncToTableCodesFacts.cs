using System.Linq;
using Inprotech.Integration.SchemaMapping;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping
{
    public class SyncToTableCodesFacts : FactBase
    {
        public SyncToTableCodesFacts()
        {
            _lastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

            _service = new SyncToTableCodes(Db, _lastInternalCodeGenerator);

            new LastInternalCode(KnownInternalCodeTable.TableCodes)
            {
                InternalSequence = 100
            }.In(Db);
        }

        const int TableTypeCode = -514;
        readonly ISyncToTableCodes _service;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        [Fact]
        public void NewTableCodeShouldUseIdReturnedByLastInternalCode()
        {
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "a"
            }.In(Db);

            _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.TableCodes).Returns(21);

            _service.Sync();

            Assert.Equal(21, Db.Set<TableCode>().Max(_ => _.Id));
        }

        [Fact]
        public void ShouldAddNewTableCodesFromNewMappings()
        {
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "a"
            }.In(Db);

            _service.Sync();

            var tc = Db.Set<TableCode>().Single();

            Assert.Equal(TableTypeCode, tc.TableTypeId);
            Assert.Equal("a", tc.Name);
            Assert.Equal("1", tc.UserCode);
        }

        [Fact]
        public void ShouldDeleteTableCodesFromDeletedMappings()
        {
            new TableCode
            {
                TableTypeId = TableTypeCode
            }.In(Db);

            Assert.Equal(1, Db.Set<TableCode>().Count());

            _service.Sync();

            Assert.Equal(0, Db.Set<TableCode>().Count());
        }

        [Fact]
        public void ShouldNotAffectOtherTableCodes()
        {
            new TableCode
            {
                TableTypeId = 1
            }.In(Db);

            _service.Sync();

            Assert.Equal(1, Db.Set<TableCode>().Count());
        }

        [Fact]
        public void ShouldUpdateMatchingTableCodes()
        {
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "a"
            }.In(Db);

            var tc = new TableCode
            {
                TableTypeId = TableTypeCode,
                UserCode = "1",
                Name = string.Empty
            }.In(Db);

            _service.Sync();

            Assert.Equal("a", tc.Name);
        }
    }
}