using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Search.Case.CaseSearch;
using Inprotech.Web.Search.CaseSupportData;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class TextTopicBuilderFacts
    {
        public class BuildMethod : FactBase
        {
            [Fact]
            public void ReturnsTextTopicFormDataWhenKeyWordIsPicklist()
            {
               var keyword = new KeyWordBuilder() {KeyWord = "RONDON", KeywordNo = 1, StopWord = 1}.Build().In(Db);
               var f = new TextTopicBuilderFixture(Db);
               var topic = f.Subject.Build(f.GetFilterCriteriaWhenKeyWordIsPicklist());

               Assert.Equal("Text",topic.TopicKey);
               Assert.NotNull(topic.FormData);
               var textTopic = topic.FormData as TextTopic;
               Assert.NotNull(textTopic);
               Assert.Equal(1, textTopic.Id);
               Assert.Equal(Operators.NotEqualTo,textTopic.KeywordOperator);
               Assert.Equal(string.Empty,textTopic.KeywordTextValue);
               Assert.NotNull(textTopic.KeywordValue);
               Assert.Equal(keyword.KeyWord, textTopic.KeywordValue.Key);
               Assert.Equal("_B", textTopic.TextType);
               Assert.Equal(Operators.EndsWith, textTopic.TextTypeOperator);
               Assert.Equal("xyz", textTopic.TextTypeValue);
               Assert.Equal(Operators.Contains, textTopic.TitleMarkOperator);
               Assert.Equal("The", textTopic.TitleMarkValue);
               Assert.Equal(Operators.EqualTo, textTopic.TitleUseSoundsLike);
               Assert.Equal(Operators.NotEqualTo, textTopic.TypeOfMarkOperator);
               Assert.Equal(5106, textTopic.TypeOfMarkValue?.Key);
               Assert.Equal("Colour Marks", textTopic.TypeOfMarkValue?.Value);
            }

            [Fact]
            public void ReturnsTextTopicFormDataWhenKeyWordIsTextBox()
            {
                var f = new TextTopicBuilderFixture(Db);
                var topic = f.Subject.Build(f.GetFilterCriteriaWhenKeyWordIsTextBox());
                Assert.Equal("Text",topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var textTopic = topic.FormData as TextTopic;
                Assert.NotNull(textTopic);
                Assert.Equal(1, textTopic.Id);
                Assert.Equal(Operators.Contains, textTopic.KeywordOperator);
                Assert.Equal("abc",textTopic.KeywordTextValue);
                Assert.Null(textTopic.KeywordValue);
                Assert.Equal("_B", textTopic.TextType);
                Assert.Equal(Operators.EndsWith, textTopic.TextTypeOperator);
                Assert.Equal("xyz", textTopic.TextTypeValue);
                Assert.Equal(Operators.Contains, textTopic.TitleMarkOperator);
                Assert.Equal("The", textTopic.TitleMarkValue);
                Assert.Equal(Operators.EqualTo, textTopic.TitleUseSoundsLike);
                Assert.Equal(Operators.NotEqualTo, textTopic.TypeOfMarkOperator);
                Assert.Equal(5106, textTopic.TypeOfMarkValue?.Key);
                Assert.Equal("Colour Marks", textTopic.TypeOfMarkValue?.Value);
            }

            [Fact]
            public void ReturnsTextTopicWithDefaultvalue()
            {
                var f = new TextTopicBuilderFixture(Db);
                var topic = f.Subject.Build(f.GetDefaultFilterCriteria());
                
                Assert.Equal("Text",topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var textTopic = topic.FormData as TextTopic;
                Assert.NotNull(textTopic);
                Assert.Equal(1, textTopic.Id);
                Assert.Equal(Operators.EqualTo,textTopic.KeywordOperator);
                Assert.Equal(string.Empty,textTopic.KeywordTextValue);
                Assert.Null(textTopic.KeywordValue);
                Assert.Null(textTopic.TextType);
                Assert.Equal(Operators.StartsWith, textTopic.TextTypeOperator);
                Assert.Null(textTopic.TextTypeValue);
                Assert.Equal(Operators.StartsWith, textTopic.TitleMarkOperator);
                Assert.Null(textTopic.TitleMarkValue);
                Assert.Equal(Operators.EqualTo, textTopic.TitleUseSoundsLike);
                Assert.Equal(Operators.EqualTo, textTopic.TypeOfMarkOperator);
                Assert.Null(textTopic.TypeOfMarkValue);
            }
        }

        public class TextTopicBuilderFixture : IFixture<TextTopicBuilder>
        {
            public TextTopicBuilderFixture(InMemoryDbContext db)
            {
                TypeOfMark = Substitute.For<ITypeOfMark>();
                TypeOfMark.Get().Returns(new List<KeyValuePair<int, string>>()
                {
                    new KeyValuePair<int, string>(5106,"Colour Marks")
                });
                Subject = new TextTopicBuilder(db, TypeOfMark);
            }

            public TextTopicBuilder Subject { get; }

            public ITypeOfMark TypeOfMark { get; set; }
            
            public XElement GetFilterCriteriaWhenKeyWordIsPicklist()
            {
                var xmlFilterCriteria = @"<Search>
                   <Report>
                      <ReportTitle>Text</ReportTitle>
                   </Report>
                   <Filtering>
                      <csw_ListCase>
                         <FilterCriteriaGroup>
                            <FilterCriteria ID='1'>
                               <AccessMode>1</AccessMode>
                               <IsAdvancedFilter>true</IsAdvancedFilter>
                               <TypeOfMarkKey Operator='1'>5106</TypeOfMarkKey>
                               <Title Operator='4'>The</Title>
                               <KeyWord Operator='1'>RONDON</KeyWord>
                               <StandingInstructions IncludeInherited='0' />
                               <StatusFlags CheckDeadCaseRestriction='1' />
                               <InheritedName />
                               <CaseNameGroup />
                               <AttributeGroup BooleanOr='0' />
                               <CaseTextGroup>
                                  <CaseText Operator='3'>
                                     <TypeKey>_B</TypeKey>
                                     <Text>xyz</Text>
                                  </CaseText>
                               </CaseTextGroup>
                               <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1'>
                                  <Period>
                                     <Type>D</Type>
                                     <Quantity />
                                  </Period>
                               </Event>
                               <Actions />
                            </FilterCriteria>
                         </FilterCriteriaGroup>                       
                      </csw_ListCase>
                   </Filtering>
                </Search>";
                return GetFirstFilterCriteria(xmlFilterCriteria);
            }

            public XElement GetFilterCriteriaWhenKeyWordIsTextBox()
            {
                var xmlFilterCriteria = @"<Search>
   <Report>
      <ReportTitle>Text</ReportTitle>
   </Report>
   <Filtering>
      <csw_ListCase>
         <FilterCriteriaGroup>
            <FilterCriteria ID='1'>
               <AccessMode>1</AccessMode>
               <IsAdvancedFilter>true</IsAdvancedFilter>
               <TypeOfMarkKey Operator='1'>5106</TypeOfMarkKey>
               <Title Operator='4'>The</Title>
               <KeyWord Operator='4'>abc</KeyWord>
               <StandingInstructions IncludeInherited='0' />
               <StatusFlags CheckDeadCaseRestriction='1' />
               <InheritedName />
               <CaseNameGroup />
               <AttributeGroup BooleanOr='0' />
               <CaseTextGroup>
                  <CaseText Operator='3'>
                     <TypeKey>_B</TypeKey>
                     <Text>xyz</Text>
                  </CaseText>
               </CaseTextGroup>
               <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1'>
                  <Period>
                     <Type>D</Type>
                     <Quantity />
                  </Period>
               </Event>
               <Actions />
            </FilterCriteria>
         </FilterCriteriaGroup>
         <ColumnFilterCriteria>
            <DueDates UseEventDates='1' UseAdHocDates='0'>
               <Dates UseDueDate='0' UseReminderDate='0' />
               <Actions IncludeClosed='0' IsRenewalsOnly='1' IsNonRenewalsOnly='1' />
               <DueDateResponsibilityOf IsAnyName='0' IsStaff='0' IsSignatory='0' />
            </DueDates>
         </ColumnFilterCriteria>
      </csw_ListCase>
   </Filtering>
</Search>";
                return GetFirstFilterCriteria(xmlFilterCriteria);
            }

            public XElement GetDefaultFilterCriteria()
            {
                var xmlFilterCriteria = @"<Search>
                   <Report>
                      <ReportTitle>blanktext</ReportTitle>
                   </Report>
                   <Filtering>
                      <csw_ListCase>
                         <FilterCriteriaGroup>
                            <FilterCriteria ID='1'>
                               <AccessMode>1</AccessMode>
                               <IsAdvancedFilter>true</IsAdvancedFilter>
                               <StandingInstructions IncludeInherited='0' />
                               <StatusFlags CheckDeadCaseRestriction='1' />
                               <InheritedName />
                               <CaseNameGroup />
                               <AttributeGroup BooleanOr='0' />
                               <Event Operator='' IsRenewalsOnly='0' IsNonRenewalsOnly='0' ByEventDate='1' />
                               <Actions />
                            </FilterCriteria>
                         </FilterCriteriaGroup>
                         <ColumnFilterCriteria>
                            <DueDates UseEventDates='1' UseAdHocDates='0'>
                               <Dates UseDueDate='0' UseReminderDate='0' />
                               <Actions IncludeClosed='0' IsRenewalsOnly='1' IsNonRenewalsOnly='1' />
                               <DueDateResponsibilityOf IsAnyName='0' IsStaff='0' IsSignatory='0' />
                            </DueDates>
                         </ColumnFilterCriteria>
                      </csw_ListCase>
                   </Filtering>
                </Search>";
                return GetFirstFilterCriteria(xmlFilterCriteria);
            }

            XElement GetFirstFilterCriteria(string xmlFilterCriteria)
            {
                var xDoc = XDocument.Parse(xmlFilterCriteria);
                var filterCriteria = xDoc.Descendants("FilterCriteriaGroup").First().Elements().First();
                return filterCriteria;
            }
        }
    }
}
