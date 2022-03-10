using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.ClassesMaintenance
{
    class ClassesMaintenanceDbSetUp : DbSetup
    {
        public const string CountryCode1 = "c01";
        public const string CountryName1 = "c01 - country";
        public const string Class1 = "1C";
        public const string Class2 = "2C";

        public void Prepare(bool testClassItems = true)
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;

            DbContext.Set<Country>().Add(new Country(CountryCode1, CountryName1, "0") { PostalName = "c05c05", NameStyleId = nameStyleId, AddressStyleId = addressStyleId });

            DbContext.SaveChanges();

            var language = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.Language);
            var propertyType = DbContext.Set<PropertyType>().Single(_ => _.Code == "T");
            propertyType.AllowSubClass = testClassItems? 2 : 1;

            DbContext.SaveChanges();

            var class1 = DbContext.Set<TmClass>().Add(new TmClass(CountryCode1, Class1, propertyType.Code));
            var class2 = DbContext.Set<TmClass>().Add(new TmClass(CountryCode1, Class2, propertyType.Code){SubClass = "sc01"});

            DbContext.SaveChanges();

            if (testClassItems)
            {
                DbContext.Set<ClassItem>().Add(new ClassItem("iteme2e1", "Item1 Description", language.Id, class1.Id));
                DbContext.Set<ClassItem>().Add(new ClassItem("iteme2e2", "Item2 Description", language.Id, class1.Id));
                DbContext.Set<ClassItem>().Add(new ClassItem("iteme2e3", "Item3 Description", language.Id, class2.Id));
                DbContext.Set<ClassItem>().Add(new ClassItem("iteme2e4", "Item4 Description", language.Id, class2.Id));

                DbContext.SaveChanges();
            }
        }
    }
}