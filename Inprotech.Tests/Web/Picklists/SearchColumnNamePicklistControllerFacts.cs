using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class SearchColumnNamePicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            const int DataItemId = 2;
            const int DataItemId1 = 3;
            const int DataItemId2 = 4;
            const int ColumnId = -77;
            const int ContextId = (int)QueryContext.CaseSearch;
            const int ExternalContextId = (int)QueryContext.CaseSearchExternal;
            const string ProcedureName = "csw_ListCase";
                
            void SetupData()
            {
                new QueryContextModel {ProcedureName = ProcedureName}.In(Db).WithKnownId(ContextId);
                new QueryContextModel{ProcedureName = ProcedureName}.In(Db).WithKnownId(ExternalContextId);

                new QueryDataItem { ProcedureItemId = "UserColumn", ProcedureName = ProcedureName, DataFormatId = 9100, IsMultiResult = false, DataItemId = DataItemId }.In(Db);
                new QueryDataItem { ProcedureItemId = "FirmElementId", QualifierType = 1,ProcedureName = ProcedureName, DataFormatId = 9102, IsMultiResult = false, DataItemId = DataItemId1 }.In(Db);
                new QueryDataItem { ProcedureItemId = "NameKey", ProcedureName = ProcedureName, DataFormatId = 9102, IsMultiResult = false, DataItemId = DataItemId2 }.In(Db);

                new QueryImpliedItem {ProcedureItemId = "NameKey", Usage = "NameKey", Id =1}.In(Db);
                new QueryImpliedItem {ProcedureItemId = "RowKey", Usage = "RowKey", Id =2}.In(Db);

                new QueryImpliedData {ContextId = ContextId,DataItemId = DataItemId2, Id = 1}.In(Db);
                new QueryImpliedData {ContextId = ExternalContextId, DataItemId = DataItemId1, Id = 2}.In(Db);
                new QueryImpliedData {ContextId = ContextId,DataItemId = null, Id = 3}.In(Db);

                new TableCodeBuilder{TableType = (short)TableTypes.DataFormat, TableCode = 9100, Description = "String"}.Build().In(Db);
                new TableCodeBuilder{TableType = (short)TableTypes.DataFormat, TableCode = 9102, Description = "Number"}.Build().In(Db);
                
                new QueryContextColumn {ColumnId = ColumnId, ContextId = ContextId, GroupId = Fixture.Integer()}.In(Db);
            }

            [Fact]
            public void ReturnsColumnsForSameContextInAscendingOrderOfName()
            {
                SetupData();
                var f = new SearchColumnNamePicklistControllerFixture(Db);

                var r = f.Subject.Search(null, null, (int) QueryContext.CaseSearch);
                var queryColumns = r.Data.OfType<SearchColumnNamePayload>().ToArray();

                Assert.Equal(3, queryColumns.Length);

                Assert.Equal("FirmElementId", queryColumns[0].Description);
                Assert.Equal("Number", queryColumns[0].DataFormat);
                Assert.True(queryColumns[0].IsQualifierAvailable);
                Assert.False(queryColumns[0].IsUserDefined);
                Assert.False(queryColumns[0].IsUsedBySystem);

                Assert.Equal("NameKey", queryColumns[1].Description);
                Assert.Equal("Number", queryColumns[1].DataFormat);
                Assert.False(queryColumns[1].IsQualifierAvailable);
                Assert.False(queryColumns[1].IsUserDefined);
                Assert.False(queryColumns[1].IsUsedBySystem);

                Assert.Equal("UserColumn", queryColumns[2].Description);
                Assert.Equal("String", queryColumns[2].DataFormat);
                Assert.True(queryColumns[2].IsUserDefined);
                Assert.False(queryColumns[2].IsQualifierAvailable);
                Assert.False(queryColumns[2].IsUsedBySystem);

            }
        }
    }

    public class SearchColumnNamePicklistControllerFixture : IFixture<SearchColumnNamePicklistController>
    {
        public SearchColumnNamePicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new SearchColumnNamePicklistController(db, PreferredCultureResolver);
        }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public SearchColumnNamePicklistController Subject { get; }
    }
}
