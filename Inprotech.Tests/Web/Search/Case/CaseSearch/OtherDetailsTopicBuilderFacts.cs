using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class OtherDetailsTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultOperatorsForOtherDetailsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

                var fixture = new OtherDetailsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("otherDetails", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var otherDetailsTopic = (OtherDetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.FileLocationOperator);
                Assert.Equal(Operators.StartsWith, otherDetailsTopic.BayNoOperator);
                Assert.Equal(Operators.StartsWith, otherDetailsTopic.PurchaseOrderNoOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForInstructionOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForCharacteristicOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.EntitySizeOperator);
                Assert.False(otherDetailsTopic.IncludeInherited);
                Assert.False(otherDetailsTopic.Letters);
                Assert.False(otherDetailsTopic.Charges);
                Assert.False(otherDetailsTopic.PolicingIncomplete);
                Assert.False(otherDetailsTopic.GlobalNameChangeIncomplete);
                Assert.True(otherDetailsTopic.ForInstruction);
                Assert.Null(otherDetailsTopic.FileLocation);
                Assert.Null(otherDetailsTopic.BayNo);
                Assert.Null(otherDetailsTopic.Instruction);
                Assert.Null(otherDetailsTopic.Characteristic);
                Assert.Null(otherDetailsTopic.PurchaseOrderNo);
                Assert.Null(otherDetailsTopic.EntitySize);
            }

            [Fact]
            public void ReturnsValuesForOtherDetailsTopic()
            {
                var fl1 = new TableCodeBuilder {TableType = (short) TableTypes.FileLocation}.Build().In(Db);
                var fl2 = new TableCodeBuilder {TableType = (short) TableTypes.FileLocation}.Build().In(Db);
                var e1 = new TableCodeBuilder {TableType = (short) TableTypes.EntitySize}.Build().In(Db);
                var bayNo = Fixture.String("BayNo");
                var ch = new InprotechKaizen.Model.StandingInstructions.Characteristic {Id = Fixture.Short(), Description = Fixture.String("Characteristic")}.In(Db);
                var purchaseOrder = Fixture.String("Purchase");

                var filterCriteria = "<FilterCriteria ID='1'>" +
                                        "<FileLocationKeys Operator='0'>"+ fl1.Id +", "+ fl2.Id+"</FileLocationKeys>" +
                                        "<FileLocationBayNo Operator='2'>"+ bayNo +"</FileLocationBayNo>" +
                                        "<StandingInstructions IncludeInherited='0'><CharacteristicFlag Operator='0'>"+ ch.Id +"</CharacteristicFlag></StandingInstructions>" +
                                        "<StatusFlags CheckDeadCaseRestriction='1' />" +
                                        "<QueueFlags><HasLettersOnQueue>1</HasLettersOnQueue><HasChargesOnQueue>1</HasChargesOnQueue></QueueFlags>" +
                                        "<HasIncompletePolicing>1</HasIncompletePolicing>" +
                                        "<HasIncompleteNameChange>1</HasIncompleteNameChange>" +
                                        "<InheritedName />" +
                                        "<PurchaseOrderNo Operator='2'>"+ purchaseOrder +"</PurchaseOrderNo><CaseNameGroup />" +
                                        "<EntitySize Operator='1'>"+e1.Id+"</EntitySize>"+
                                        "</FilterCriteria>";
                
                var fixture = new OtherDetailsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("otherDetails", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var otherDetailsTopic = (OtherDetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.FileLocationOperator);
                Assert.Equal(Operators.StartsWith, otherDetailsTopic.BayNoOperator);
                Assert.Equal(Operators.StartsWith, otherDetailsTopic.PurchaseOrderNoOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForInstructionOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForCharacteristicOperator);
                Assert.Equal(Operators.NotEqualTo, otherDetailsTopic.EntitySizeOperator);
                Assert.False(otherDetailsTopic.IncludeInherited);
                Assert.True(otherDetailsTopic.Letters);
                Assert.True(otherDetailsTopic.Charges);
                Assert.True(otherDetailsTopic.PolicingIncomplete);
                Assert.True(otherDetailsTopic.GlobalNameChangeIncomplete);
                Assert.False(otherDetailsTopic.ForInstruction);
                Assert.Equal(2, otherDetailsTopic.FileLocation?.Count());
                Assert.Equal(fl1.Id, otherDetailsTopic.FileLocation?.FirstOrDefault()?.Key);
                Assert.Equal(bayNo ,otherDetailsTopic.BayNo);
                Assert.Null(otherDetailsTopic.Instruction);
                Assert.Equal(ch.Id, otherDetailsTopic.Characteristic?.Id);
                Assert.Equal(purchaseOrder, otherDetailsTopic.PurchaseOrderNo);
                Assert.Equal(e1.Name, otherDetailsTopic.EntitySize?.Value);
            }

            [Fact]
            public void ReturnsValuesForOtherDetailsTopicWhenInstructionIsAdded()
            {
                var instr = new InprotechKaizen.Model.StandingInstructions.Instruction {Id = Fixture.Short(), Description = Fixture.String("Instruction")}.In(Db);
                
                var filterCriteria = "<FilterCriteria ID='1'>" +
                                        "<StandingInstructions IncludeInherited='1' />" +
                                        "<InstructionKey Operator='0'>"+instr.Id+"</InstructionKey>" +
                                        "</FilterCriteria>";
                
                var fixture = new OtherDetailsTopicBuilderFixture(Db);
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("otherDetails", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var otherDetailsTopic = (OtherDetailsTopic) topic.FormData;
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForInstructionOperator);
                Assert.Equal(Operators.EqualTo, otherDetailsTopic.ForCharacteristicOperator);
                Assert.True(otherDetailsTopic.IncludeInherited);
                Assert.True(otherDetailsTopic.ForInstruction);
                Assert.Equal(instr.Id, otherDetailsTopic.Instruction?.Id);
                Assert.Null(otherDetailsTopic.Characteristic);
            }
        }

        public class OtherDetailsTopicBuilderFixture : IFixture<OtherDetailsTopicBuilder>
        {
            public OtherDetailsTopicBuilderFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new OtherDetailsTopicBuilder(db, CultureResolver);
            }

            public IPreferredCultureResolver CultureResolver { get; set; }

            public OtherDetailsTopicBuilder Subject { get; set; }
        }
    }
}
