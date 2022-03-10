using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class DetailsTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            } 

            [Fact]
            public void ReturnsDefaultOperatorForDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

                var fixture = new DetailsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("Details", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var detailsTopic = (DetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseOfficeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.JurisdictionOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.PropertyTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseCategoryOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.SubTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.BasisOperator);
                Assert.Equal(Operators.StartsWith, detailsTopic.ClassOperator);
                Assert.False(detailsTopic.IncludeDraftCases);
                Assert.False(detailsTopic.IncludeWhereDesignated);
                Assert.False(detailsTopic.IncludeGroupMembers);
                Assert.True(detailsTopic.Local);
                Assert.False(detailsTopic.International);
                Assert.Null(detailsTopic.CaseOffice);
                Assert.Null(detailsTopic.CaseType);
                Assert.Null(detailsTopic.Jurisdiction);
                Assert.Null(detailsTopic.PropertyType);
                Assert.Null(detailsTopic.CaseCategory);
                Assert.Null(detailsTopic.SubType);
                Assert.Null(detailsTopic.Basis);
                Assert.Null(detailsTopic.Class);
            }

            [Fact]
            public void ReturnsValuesForDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'>
                                        <AccessMode>1</AccessMode>
                                        <IsAdvancedFilter>true</IsAdvancedFilter>
                                        <CaseReference Operator='2'>123</CaseReference>
                                        <CaseTypeKeys Operator='0' IncludeCRMCases='0'>A</CaseTypeKeys>
                                        <PropertyTypeKeys Operator='0'><PropertyTypeKey>T</PropertyTypeKey><PropertyTypeKey>P</PropertyTypeKey></PropertyTypeKeys>
                                        <SubTypeKey Operator='1'>N</SubTypeKey>
                                        <BasisKey Operator='0'>N</BasisKey>
                                        <FamilyKey Operator='0'>BALLOON,FLOAT</FamilyKey>
                                        <CategoryKey Operator='0'>N,5</CategoryKey>
                                        <OfficeKeys Operator='0'>10175,10272</OfficeKeys>
                                        <IncludeDraftCase>1</IncludeDraftCase>
                                        <Classes Operator='2' IsLocal='1' IsInternational='1'>12,24,48</Classes>
                                        <CountryCodes Operator='0' IncludeDesignations='1'>AU,US</CountryCodes>
                                    </FilterCriteria>";

                new OfficeBuilder {Id = 10175, Name = "City Office"}.Build().In(Db);
                new OfficeBuilder {Id = 10272, Name = "New Office"}.Build().In(Db);
                new CountryBuilder {Id = "AU"}.Build().In(Db);
                new CountryBuilder {Id = "US"}.Build().In(Db);
                
                var fixture = GetDetailsTopicBuilderFixture();

                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("Details", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var detailsTopic = (DetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseOfficeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.JurisdictionOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.PropertyTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseCategoryOperator);
                Assert.Equal(Operators.NotEqualTo, detailsTopic.SubTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.BasisOperator);
                Assert.Equal(Operators.StartsWith, detailsTopic.ClassOperator);
                Assert.True(detailsTopic.IncludeDraftCases);
                Assert.True(detailsTopic.IncludeWhereDesignated);
                Assert.False(detailsTopic.IncludeGroupMembers);
                Assert.True(detailsTopic.Local);
                Assert.True(detailsTopic.International);
                Assert.Equal("12,24,48", detailsTopic.Class);
                Assert.Equal(2, detailsTopic.CaseOffice.Length);
                Assert.Equal(10175, detailsTopic.CaseOffice[0].Key);
                Assert.Single(detailsTopic.CaseType);
                Assert.Equal("A", detailsTopic.CaseType[0].Code);
                Assert.Equal(2, detailsTopic.PropertyType.Length);
                Assert.Equal("T", detailsTopic.PropertyType[0].Code);
                Assert.Equal(2, detailsTopic.Jurisdiction.Length);
                Assert.Equal("AU", detailsTopic.Jurisdiction[0].Code);
                Assert.Equal(2, detailsTopic.CaseCategory.Length);
                Assert.Equal("N", detailsTopic.CaseCategory[0].Code);
                Assert.Equal("N", detailsTopic.SubType.Code);
                Assert.Equal("N", detailsTopic.Basis.Code);
            }

            DetailsTopicBuilderFixture GetDetailsTopicBuilderFixture()
            {
                var fixture = new DetailsTopicBuilderFixture(Db);
                fixture.CaseTypes.GetCaseTypesWithDetails().Returns(new List<CaseType>
                {
                    new CaseType(1, "A", "Properties")
                });
                fixture.PropertyTypes.GetPropertyTypes(Arg.Any<string[]>()).Returns(new List<PropertyTypeListItem>
                {
                    new PropertyTypeListItem {PropertyTypeKey = "T"},
                    new PropertyTypeListItem {PropertyTypeKey = "P"}
                });
                fixture.CaseCategories.GetCaseCategories(Arg.Any<string>(), Arg.Any<string[]>(), Arg.Any<string[]>()).Returns(new List<CaseCategoryListItem>
                {
                    new CaseCategoryListItem {CaseCategoryKey = "N", CaseTypeKey = "A"},
                    new CaseCategoryListItem {CaseCategoryKey = "5", CaseTypeKey = "A"}
                });
                fixture.SubTypes.GetSubTypes(Arg.Any<string>(), Arg.Any<string[]>(), Arg.Any<string[]>(), Arg.Any<string[]>()).Returns(new List<SubTypeListItem>
                {
                    new SubTypeListItem {SubTypeKey = "N"}
                });
                fixture.Basis.GetBasis(Arg.Any<string>(), Arg.Any<string[]>(), Arg.Any<string[]>(), Arg.Any<string[]>()).Returns(new List<BasisListItem>
                {
                    new BasisListItem {ApplicationBasisKey = "N"}
                });
                return fixture;
            }

            [Fact]
            public void ReturnsValuesForAlternateFilterForDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'>
                                        <CaseTypeKey Operator='0'>A,S</CaseTypeKey>
                                        <PropertyTypeKey Operator='0'>T</PropertyTypeKey>
                                        <Office Operator='0'>10175,10272</Office>
                                    </FilterCriteria>";

                new OfficeBuilder {Id = 10175, Name = "City Office"}.Build().In(Db);
                new OfficeBuilder {Id = 10272, Name = "New Office"}.Build().In(Db);
                
                var fixture = GetDetailsTopicBuilderFixture();

                var topic = fixture.Subject.Build(GetXElement(filterCriteria));

                Assert.Equal("Details", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var detailsTopic = (DetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseOfficeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.CaseTypeOperator);
                Assert.Equal(Operators.EqualTo, detailsTopic.PropertyTypeOperator);
                Assert.Equal(2, detailsTopic.CaseOffice.Length);
                Assert.Equal(10175, detailsTopic.CaseOffice[0].Key);
                Assert.Single(detailsTopic.CaseType);
                Assert.Equal("A", detailsTopic.CaseType[0].Code);
                Assert.Single(detailsTopic.PropertyType);
                Assert.Equal("T", detailsTopic.PropertyType[0].Code);
            }

            [Fact]
            public void CheckIfValidCombinationIsBeingReturnedForDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'>
                                        <CaseTypeKeys Operator='0' IncludeCRMCases='0'>A</CaseTypeKeys>
                                        <PropertyTypeKeys Operator='0'><PropertyTypeKey>T</PropertyTypeKey></PropertyTypeKeys>
                                        <SubTypeKey Operator='1'>N</SubTypeKey>
                                        <BasisKey Operator='0'>N</BasisKey>
                                        <CategoryKey Operator='0'>N</CategoryKey>
                                        <CountryCodes Operator='0' IncludeDesignations='1'>AU</CountryCodes>
                                    </FilterCriteria>";

                new CountryBuilder {Id = "AU"}.Build().In(Db);
                var fixture = GetDetailsTopicBuilderFixture();

                fixture.Subject.Build(GetXElement(filterCriteria));
                fixture.CaseCategories.Received(1).GetCaseCategories("A", Arg.Is<string[]>(_ => _.Contains("AU")), Arg.Is<string[]>(_ => _.Contains("T")));
                fixture.SubTypes.Received(1).GetSubTypes("A", Arg.Is<string[]>(_ => _.Contains("AU")), Arg.Is<string[]>(_ => _.Contains("T")), Arg.Is<string[]>(_ => _.Contains("N")));
                fixture.Basis.Received(1).GetBasis("A", Arg.Is<string[]>(_ => _.Contains("AU")), Arg.Is<string[]>(_ => _.Contains("T")), Arg.Is<string[]>(_ => _.Contains("N")));
            }

            [Fact]
            public void CheckIfGeneralRecordsAreBeingReturnedForDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'>
                                        <PropertyTypeKeys Operator='0'><PropertyTypeKey>T</PropertyTypeKey></PropertyTypeKeys>
                                        <SubTypeKey Operator='1'>N</SubTypeKey>
                                        <BasisKey Operator='0'>N</BasisKey>
                                        <CategoryKey Operator='0'>N,5</CategoryKey>
                                        <CountryCodes Operator='0' IncludeDesignations='1'>AU</CountryCodes>
                                    </FilterCriteria>";

                new CountryBuilder {Id = "AU"}.Build().In(Db);

                var fixture = GetDetailsTopicBuilderFixture();
                fixture.Subject.Build(GetXElement(filterCriteria));
                fixture.CaseCategories.Received(1).GetCaseCategories(null, null, null);
                fixture.SubTypes.Received(1).GetSubTypes(null, null, null, null);
                fixture.Basis.Received(1).GetBasis(null, null, null, null);
            }
        }

        public class DetailsTopicBuilderFixture : IFixture<DetailsTopicBuilder>
        {
            public DetailsTopicBuilderFixture(InMemoryDbContext db)
            {
                CaseTypes = Substitute.For<ICaseTypes>();
                Basis = Substitute.For<IBasis>();
                SubTypes = Substitute.For<ISubTypes>();
                CaseCategories = Substitute.For<ICaseCategories>();
                PropertyTypes = Substitute.For<IPropertyTypes>();

                Subject = new DetailsTopicBuilder(db, CaseTypes, Basis, SubTypes, CaseCategories, PropertyTypes);
            }

            public ICaseTypes CaseTypes { get; set; }
            public IBasis Basis { get; set; }
            public ISubTypes SubTypes { get; set; }
            public ICaseCategories CaseCategories { get; set; }
            public IPropertyTypes PropertyTypes { get; set; }

            public DetailsTopicBuilder Subject { get; set; }
        }
    }
}
