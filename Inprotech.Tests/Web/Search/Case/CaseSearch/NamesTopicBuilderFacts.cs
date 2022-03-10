using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class NamesTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultOperatorsForNamesTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

                var fixture = new NamesTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("Names", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var namesTopic = (NamesTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, namesTopic.InstructorOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.AgentOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.OwnerOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.SignatoryOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.StaffOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.ParentNameOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.DefaultRelationshipOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.InheritedNameTypeOperator);
                Assert.False(namesTopic.IsSignatoryMyself);
                Assert.False(namesTopic.IsStaffMyself);
                Assert.False(namesTopic.SearchAttentionName);
                Assert.Null(namesTopic.Instructor);
                Assert.Null(namesTopic.Owner);
                Assert.Null(namesTopic.Agent);
                Assert.Null(namesTopic.Staff);
                Assert.Null(namesTopic.Signatory);
                Assert.Null(namesTopic.IncludeCaseValue);
                Assert.Null(namesTopic.ParentName);
                Assert.Null(namesTopic.DefaultRelationship);
                Assert.Null(namesTopic.InheritedNameType);
                Assert.Null(namesTopic.IsOtherCasesValue);
                Assert.Null(namesTopic.NameTypeValue);
            }

            [Fact]
            public void ReturnsValuesForNamesTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'>
                    <NameRelationships Operator='0'>
                        <NameTypes>~CN</NameTypes>
                        <Relationships>CON</Relationships>
                    </NameRelationships>
                    <InheritedName>
                        <ParentNameKey Operator='0'>10050</ParentNameKey>
                        <NameTypeKey Operator='0'>O</NameTypeKey>
                        <DefaultRelationshipKey Operator='0'>BIL</DefaultRelationshipKey>
                    </InheritedName>
                    <CaseNameFromCase>
                        <CaseKey>-486</CaseKey>
                        <NameTypeKey>EX</NameTypeKey>
                    </CaseNameFromCase>
                    <CaseNameGroup>
                        <CaseName Operator='0'>
                            <TypeKey>I</TypeKey>
                            <NameKeys>10054</NameKeys>
                        </CaseName>
                        <CaseName Operator='0'>
                            <TypeKey>O</TypeKey>
                            <NameKeys>7</NameKeys>
                        </CaseName>
                        <CaseName Operator='0'>
                            <TypeKey>A</TypeKey>
                            <NameKeys>-5001000</NameKeys>
                        </CaseName>
                        <CaseName Operator='0'>
                            <TypeKey>EMP</TypeKey>
                            <NameKeys IsCurrentUser='1'>-487</NameKeys>
                        </CaseName>
                        <CaseName Operator='1'>
                            <TypeKey>SIG</TypeKey>
                            <NameKeys IsCurrentUser='0'>11</NameKeys>
                        </CaseName>
                        <CaseName is-other-name-type='true' Operator='0'>
                            <TypeKey>D</TypeKey>
                            <NameKeys UseAttentionName='1'>-493</NameKeys>
                        </CaseName>
                    </CaseNameGroup>
                </FilterCriteria>";

                new InprotechKaizen.Model.Names.Name(10054){FirstName = "Instructor", LastName = "Instructor"}.In(Db);
                new InprotechKaizen.Model.Names.Name(7){FirstName = "Owner", LastName = "Owner"}.In(Db);
                new InprotechKaizen.Model.Names.Name(-5001000){FirstName = "Agent", LastName = "Agent"}.In(Db);
                new InprotechKaizen.Model.Names.Name(-487){FirstName = "Staff", LastName = "Staff"}.In(Db);
                new InprotechKaizen.Model.Names.Name(11){FirstName = "Signatory", LastName = "Signatory"}.In(Db);
                new InprotechKaizen.Model.Names.Name(-493){FirstName = "Debtor", LastName = "Debtor"}.In(Db);
                new InprotechKaizen.Model.Names.Name(10050){FirstName = "Parent", LastName = "Name"}.In(Db);
                new NameRelation("BIL", "Send Bills To", "Reverse Billing", 6, false, 0).In(Db);
                new NameRelation("CON", "Contact", "Contact For", 6, false, 0).In(Db);
                new NameTypeBuilder {NameTypeCode = "~CN", Name = "Contact"}.Build().In(Db);
                new NameTypeBuilder {NameTypeCode = "D", Name = "Debtor"}.Build().In(Db);
                new NameTypeBuilder {NameTypeCode = "O", Name = "Owner"}.Build().In(Db);
                new NameTypeBuilder {NameTypeCode = "EX", Name = "Examiner"}.Build().In(Db);
                new InprotechKaizen.Model.Cases.Case {Id = -486, Irn = "1234", PropertyType = new PropertyTypeBuilder().Build(), Country = new CountryBuilder().Build()}.In(Db);

                var fixture = new NamesTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("Names", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var namesTopic = (NamesTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, namesTopic.InstructorOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.AgentOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.OwnerOperator);
                Assert.Equal(Operators.NotEqualTo, namesTopic.SignatoryOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.StaffOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.ParentNameOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.DefaultRelationshipOperator);
                Assert.Equal(Operators.EqualTo, namesTopic.InheritedNameTypeOperator);
                Assert.False(namesTopic.IsSignatoryMyself);
                Assert.True(namesTopic.IsStaffMyself);
                Assert.Equal(10054, namesTopic.Instructor?[0].Key);
                Assert.Equal(7, namesTopic.Owner?[0].Key);
                Assert.Equal(-5001000, namesTopic.Agent?[0].Key);
                Assert.Equal(-487, namesTopic.Staff?[0].Key);
                Assert.Equal(11, namesTopic.Signatory?[0].Key);
                Assert.Equal(-493, namesTopic.Names?[0].Key);
                Assert.Equal(10050, namesTopic.ParentName?.Key);
                Assert.Equal("BIL", namesTopic.DefaultRelationship?.Code);
                Assert.Equal("CON", namesTopic.Relationship?[0].Code);
                Assert.Equal("D", namesTopic.NamesType);
                Assert.Equal("EX", namesTopic.IsOtherCasesValue);
                Assert.Equal("O", namesTopic.InheritedNameType?.Code);
                Assert.Equal("~CN", namesTopic.NameTypeValue?[0].Code);
            }
        }

        public class NamesTopicBuilderFixture : IFixture<NamesTopicBuilder>
        {
            public NamesTopicBuilderFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new NamesTopicBuilder(db, CultureResolver);
            }

            public IPreferredCultureResolver CultureResolver { get; set; }

            public NamesTopicBuilder Subject { get; set; }
        }
    }
}
