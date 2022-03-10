using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.TextsMaintenance
{
    public class TextsMaintenanceDbSetUp : DbSetup
    {
        public const string CountryCode1 = "c1";
        public const string CountryName1 = "c1 - country";
        public const string CountryCode2 = "c2";
        public const string CountryName2 = "c2 - country";

        public const string TextType1 = "Text Type 1";
        public const string TextType2 = "Text Type 2";
        public const string TextType3 = "Text Type 3";

        public const string PropertyTypeCode1 = "1";
        public const string PropertyTypeCode2 = "2";
        public const string PropertyTypeCode3 = "3";
        public const string PropertyTypeDesc1 = "Property Description 1";
        public const string PropertyTypeDesc2 = "Property Description 2";
        public const string PropertyTypeDesc3 = "Property Description 3";

        public void Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int) TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;
            var country = DbContext.Set<Country>().Add(new Country(CountryCode1, CountryName1, "0") {PostalName = "c02c02", NameStyleId = nameStyleId, AddressStyleId = addressStyleId});
            DbContext.Set<Country>().Add(new Country(CountryCode2, CountryName2, "0") { PostalName = "c03c03", NameStyleId = nameStyleId, AddressStyleId = addressStyleId });

            var textType1 = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.CountryTextType, Name = TextType1 });
            var textType2 = InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.CountryTextType, Name = TextType2 });
            InsertWithNewId(new TableCode { TableTypeId = (int)TableTypes.CountryTextType, Name = TextType3 });

            var propertyType1 = DbContext.Set<PropertyType>().Add(new PropertyType(PropertyTypeCode1, PropertyTypeDesc1));
            var propertyType2 = DbContext.Set<PropertyType>().Add(new PropertyType(PropertyTypeCode2, PropertyTypeDesc2));
            var propertyType3 = DbContext.Set<PropertyType>().Add(new PropertyType(PropertyTypeCode3, PropertyTypeDesc3));

            var validPropertyType1 = new ValidProperty { Country = country, PropertyType = propertyType1, PropertyTypeId = PropertyTypeCode1, PropertyName = PropertyTypeDesc1};
            var validPropertyType2 = new ValidProperty { Country = country, PropertyType = propertyType2, PropertyTypeId = PropertyTypeCode2, PropertyName = PropertyTypeDesc2 };
            var validPropertyType3 = new ValidProperty { Country = country, PropertyType = propertyType3, PropertyTypeId = PropertyTypeCode3, PropertyName = PropertyTypeDesc3 };

            DbContext.Set<ValidProperty>().Add(validPropertyType1);
            DbContext.Set<ValidProperty>().Add(validPropertyType2);
            DbContext.Set<ValidProperty>().Add(validPropertyType3);

            DbContext.Set<CountryText>().Add(new CountryText(CountryCode1, textType1, propertyType1)
            {
                SequenceId = 0
            });

            DbContext.Set<CountryText>().Add(new CountryText(CountryCode1, textType2, propertyType2)
            {
                SequenceId = 1
            });

            DbContext.SaveChanges();
        }
    }
}
