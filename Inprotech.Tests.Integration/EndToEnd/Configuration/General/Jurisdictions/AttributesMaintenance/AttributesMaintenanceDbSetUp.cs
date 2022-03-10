using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.AttributesMaintenance
{
    public class AttributesMaintenanceDbSetUp : DbSetup
    {
        public const string CountryCode1 = "a01";
        public const string CountryName1 = "a01 - country";
        public const string TableType1 = "e2e-attribute1";
        public const string TableType2 = "e2e-attribute2";

        public const string TableCode1 = "e2e-attributeValue1";
        public const string TableCode2 = "e2e-attributeValue2";
        public const string TableCode3 = "e2e-attributeValue3";
        public const string TableCode4 = "e2e-attributeValue4";
        public const string TableCode5 = "e2e-attributeValue5";

        public void Prepare()
        {
            DbContext.Set<Country>().Add(new Country(CountryCode1, CountryName1, "1"));

            var tableTypeId = DbContext.Set<TableType>().Max(_ => _.Id) + 1;

            var tableType1 = new TableType((short)tableTypeId) {Name = TableType1, DatabaseTable = "TABLECODES"};
            var tableType2 = new TableType((short) (tableTypeId +1)) {Name = TableType2, DatabaseTable = "TABLECODES" };

            DbContext.Set<TableType>().Add(tableType1);
            DbContext.Set<TableType>().Add(tableType2);

            DbContext.SaveChanges();

            var tableCodeId = DbContext.Set<TableCode>().Max(_ => _.Id) + 1;

            var tableCode1 = new TableCode(tableCodeId, tableType1.Id, TableCode1);
            var tableCode2 = new TableCode(tableCodeId + 1, tableType1.Id, TableCode2);
            var tableCode3 = new TableCode(tableCodeId + 2, tableType2.Id, TableCode3);
            var tableCode4 = new TableCode(tableCodeId + 3, tableType2.Id, TableCode4);

            DbContext.Set<TableCode>().Add(tableCode1);
            DbContext.Set<TableCode>().Add(tableCode2);
            DbContext.Set<TableCode>().Add(tableCode3);
            DbContext.Set<TableCode>().Add(tableCode4);

            DbContext.Set<SelectionTypes>().Add(new SelectionTypes(tableType1) { MinimumAllowed = 1, MaximumAllowed = 1, ParentTable = KnownTableAttributes.Country });
            DbContext.Set<SelectionTypes>().Add(new SelectionTypes(tableType2) { MinimumAllowed = 0, MaximumAllowed = 10, ParentTable = KnownTableAttributes.Country });

            DbContext.Set<TableAttributes>().Add(new TableAttributes(KnownTableAttributes.Country, CountryCode1) {SourceTableId = tableType1.Id, TableCodeId = tableCode1.Id});
            DbContext.Set<TableAttributes>().Add(new TableAttributes(KnownTableAttributes.Country, CountryCode1) { SourceTableId = tableType2.Id, TableCodeId = tableCode3.Id });

            DbContext.SaveChanges();
        }
    }
}
