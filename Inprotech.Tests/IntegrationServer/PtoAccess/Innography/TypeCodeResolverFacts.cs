using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class TypeCodeResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void Resolve()
            {
                int childCaseId1, childCaseId2;
                var f = new TypeCodeResolverFixture(Db)
                        .WithCase(childCaseId1 = Fixture.Integer(), "DE")
                        .WithParentDc1Case(childCaseId1, "EP")
                        .WithCase(childCaseId2 = Fixture.Integer(), "DE")
                        .WithParentDc1Case(childCaseId2, "EA");

                var result = f.Subject.GetTypeCodes().OrderBy(_ => _.TypeCode).ToArray();

                Assert.Equal("EAPO", result.First().TypeCode);
                Assert.Equal(childCaseId2, result.First().CaseId);

                Assert.Equal("EPPAT", result.Last().TypeCode);
                Assert.Equal(childCaseId1, result.Last().CaseId);
            }
        }

        public class TypeCodeResolverFixture : IFixture<ITypeCodeResolver>
        {
            readonly InMemoryDbContext _db;

            public TypeCodeResolverFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new TypeCodeResolver(db);

                AddInnographyTableType();
                AddTableAttribute("EP", "EPPAT");
                AddTableAttribute("EA", "EAPO");

                new CaseRelation(KnownRelations.DesignatedCountry1, "Designated Country", null).In(db);
            }

            public ITypeCodeResolver Subject { get; }

            public TypeCodeResolverFixture WithCase(int caseId, string countryCode)
            {
                new Case(caseId, "child" + caseId, new CountryBuilder {Id = countryCode}.Build().In(_db),
                         new CaseTypeBuilder().Build().In(_db), new PropertyTypeBuilder().Build().In(_db)).In(_db);

                return this;
            }

            public TypeCodeResolverFixture WithParentDc1Case(int childCaseId, string parentCountry)
            {
                var country = _db.Set<Country>().SingleOrDefault(_ => _.Id == parentCountry);
                var dc1 = _db.Set<CaseRelation>().SingleOrDefault(_ => _.Relationship == KnownRelations.DesignatedCountry1);

                var childCase = _db.Set<Case>().Single(_ => _.Id == childCaseId);

                var parentCase = new Case("parent" + childCaseId, country, new CaseTypeBuilder().Build().In(_db), new PropertyTypeBuilder().Build().In(_db)).In(_db);
                parentCase.RelatedCases.Add(new RelatedCase(parentCase.Id, childCase.Country.Id, "some number", dc1, childCaseId).In(_db));

                var a = _db.Set<RelatedCase>().First();
                var b = a;
                return this;
            }

            void AddTableAttribute(string countryCode, string usercode)
            {
                var tableType = _db.Set<TableType>().Single(_ => _.Id == (short) TableTypes.IPOneDataType);

                var nextId = _db.Set<TableCode>().Any() ? _db.Set<TableCode>().Max(_ => _.Id) + 1 : 1;
                var tableCode = new TableCode(nextId, (int) TableTypes.IPOneDataType, "InnographyType", usercode).In(_db);
                tableType.TableCodes.Add(tableCode);

                new CountryBuilder {Id = countryCode}.Build().In(_db);
                new TableAttributes(KnownTableAttributes.Country, countryCode) {SourceTableId = tableType.Id, TableCode = tableCode}.In(_db);
            }

            void AddInnographyTableType()
            {
                new TableType((short) TableTypes.IPOneDataType).In(_db);
            }
        }
    }
}