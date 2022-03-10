using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class AttributesTopicBuilderFacts : FactBase
    {
        XElement GetXElement(string filterCriteria)
        {
            var xDoc = XDocument.Parse(filterCriteria);
            return xDoc.Root;
        }

        [Fact]
        public void ReturnsDefaultOperatorsForAttributesTopic()
        {
            const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

            var fixture = new AttributesTopicBuilderFixture(Db);
            var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
            Assert.Equal("attributes", topic.TopicKey);
            Assert.NotNull(topic.FormData);
            var attrTopic = (AttributesTopic)topic.FormData;
            Assert.Equal(Operators.EqualTo, attrTopic.Attribute1?.AttributeOperator);
            Assert.Equal(Operators.EqualTo, attrTopic.Attribute2?.AttributeOperator);
            Assert.Equal(Operators.EqualTo, attrTopic.Attribute3?.AttributeOperator);
            Assert.Null(attrTopic.Attribute1?.AttributeType);
            Assert.Null(attrTopic.Attribute2?.AttributeType);
            Assert.Null(attrTopic.Attribute3?.AttributeType);
            Assert.Null(attrTopic.Attribute1?.AttributeValue);
            Assert.Null(attrTopic.Attribute2?.AttributeValue);
            Assert.Null(attrTopic.Attribute3?.AttributeValue);
        }

        [Fact]
        public void ReturnsValueForAttributesTopic()
        {
            var t1 = new TableTypeBuilder(Db) {Id = 44, DatabaseTable = "OFFICE" }.Build().In(Db);
            var t2 = new TableTypeBuilder(Db) {Id = Fixture.Short()}.Build().In(Db);
            var t3 = new TableTypeBuilder(Db) {Id = Fixture.Short()}.Build().In(Db);
            var c2 = new TableCodeBuilder {TableType = t1.Id, TableCode = Fixture.Integer()}.Build().In(Db);
            var c1 = new OfficeBuilder {Id = Fixture.Integer()}.Build().In(Db);

            var filterCriteria = "<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>true</IsAdvancedFilter>" +
                                    "<AttributeGroup BooleanOr='0'><Attribute Operator='0'><TypeKey>"+ t1.Id+"</TypeKey><AttributeKey>"+ c1.Id +"</AttributeKey></Attribute>" +
                                    "<Attribute Operator='1'><TypeKey>"+ t2.Id +"</TypeKey><AttributeKey>"+ c2.Id +"</AttributeKey></Attribute>" +
                                    "<Attribute Operator='0'><TypeKey>"+ t3.Id+"</TypeKey></Attribute></AttributeGroup><Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1' /><Actions /></FilterCriteria>";

            var fixture = new AttributesTopicBuilderFixture(Db);
            var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
            Assert.Equal("attributes", topic.TopicKey);
            Assert.NotNull(topic.FormData);
            var attrTopic = (AttributesTopic)topic.FormData;
            Assert.Equal(0, attrTopic.BooleanAndOr);
            Assert.Equal(Operators.EqualTo, attrTopic.Attribute1?.AttributeOperator);
            Assert.Equal(Operators.NotEqualTo, attrTopic.Attribute2?.AttributeOperator);
            Assert.Equal(Operators.EqualTo, attrTopic.Attribute3?.AttributeOperator);
            Assert.NotNull(attrTopic.Attribute1?.AttributeType);
            Assert.Contains(t1.Name, attrTopic.Attribute1?.AttributeType?.Values);
            Assert.NotNull(attrTopic.Attribute2?.AttributeType);
            Assert.Contains(t2.Name, attrTopic.Attribute2?.AttributeType?.Values);
            Assert.NotNull(attrTopic.Attribute3?.AttributeType);
            Assert.Contains(t3.Name, attrTopic.Attribute3?.AttributeType?.Values);
            Assert.NotNull(attrTopic.Attribute1?.AttributeValue);
            Assert.Equal(c1.Id,attrTopic.Attribute1?.AttributeValue?.Key);
            Assert.Equal(c2.Id,attrTopic.Attribute2?.AttributeValue?.Key);
            Assert.Null(attrTopic.Attribute3?.AttributeValue);
        }

        public class AttributesTopicBuilderFixture : IFixture<AttributesTopicBuilder>
        {
            public AttributesTopicBuilderFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new AttributesTopicBuilder(db, CultureResolver);
            }

            public IPreferredCultureResolver CultureResolver { get; set; }

            public AttributesTopicBuilder Subject { get; }
        }
    }
}
