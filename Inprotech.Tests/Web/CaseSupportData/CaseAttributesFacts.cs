using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class CaseAttributesFacts
    {
        public class GetMethod : FactBase
        {
            public GetMethod()
            {
                new CaseTypeBuilder {Name = "Assignment"}.Build().In(Db);
                new CaseTypeBuilder {Name = "Properties"}.Build().In(Db);

                _tableTypeIndustry = new TableTypeBuilder(Db) {Name = "Industry"}.For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                _tableTypeOffice = new TableTypeBuilder(Db) {Name = "Office"}.For(TableTypes.Office).BuildWithTableCodes().In(Db);
                _tableTypeImageType = new TableTypeBuilder(Db) {Name = "Image Type"}.For(TableTypes.ImageType).BuildWithTableCodes().In(Db);
                _tableTypeProductInterest = new TableTypeBuilder(Db) {Name = "Product Interest"}.For(TableTypes.ProductInterest).BuildWithTableCodes().In(Db);

                new SelectionTypesBuilder(Db) {TableType = _tableTypeIndustry, ParentTable = "ASSIGNMENT/RECORDALS/COPYRIGHT"}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = _tableTypeOffice, ParentTable = "INTERNAL/DOMAIN NAME"}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = _tableTypeImageType, ParentTable = "PROPERTIES/PATENTS"}.Build().In(Db);
                new SelectionTypesBuilder(Db) {TableType = _tableTypeProductInterest, ParentTable = "PROPERTIES/PATENTS"}.Build().In(Db);
            }

            readonly TableType _tableTypeIndustry;
            readonly TableType _tableTypeImageType;
            readonly TableType _tableTypeProductInterest;
            readonly TableType _tableTypeOffice;

            [Fact]
            public void GetsAllValidChecklists()
            {
                var f = new CaseAttributesFixture(Db);

                var r = f.Subject.Get().ToArray();

                Assert.Equal(3, r.Length);
                Assert.Equal(_tableTypeImageType.Id.ToString(), r[0].Key);
                Assert.Equal(_tableTypeImageType.Name, r[0].Value);
                Assert.Equal(_tableTypeIndustry.Id.ToString(), r[1].Key);
                Assert.Equal(_tableTypeIndustry.Name, r[1].Value);
                Assert.Equal(_tableTypeProductInterest.Id.ToString(), r[2].Key);
                Assert.Equal(_tableTypeProductInterest.Name, r[2].Value);
                Assert.DoesNotContain(new KeyValuePair<string, string>(_tableTypeOffice.Id.ToString(), _tableTypeOffice.Name), r);
            }
        }

        public class CaseAttributesFixture : IFixture<CaseAttributes>
        {
            public CaseAttributesFixture(InMemoryDbContext db)
            {
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new CaseAttributes(db, PreferredCultureResolver);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public CaseAttributes Subject { get; }
        }
    }
}