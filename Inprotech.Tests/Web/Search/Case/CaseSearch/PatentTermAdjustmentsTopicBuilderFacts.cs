using Inprotech.Web.Search.Case.CaseSearch;
using System.Xml.Linq;
using InprotechKaizen.Model;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class PatentTermAdjustmentsTopicBuilderFacts
    {
        public class Build : FactBase
        {
            XElement GetXElement(string filterCriteria)
            {
                var xDoc = XDocument.Parse(filterCriteria);
                return xDoc.Root;
            }

            [Fact]
            public void ReturnsDefaultOperatorsForPatentTermAdjustmentsTopic()
            {
                const string filterCriteria = @"<FilterCriteria ID='1'><AccessMode>1</AccessMode><IsAdvancedFilter>false</IsAdvancedFilter></FilterCriteria>";

                var fixture = new PatentTermAdjustmentsTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("patentTermAdjustments", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var ptaTopic = (PatentTermAdjustmentsTopic) topic.FormData;
                Assert.Equal(Operators.Between, ptaTopic.ApplicantDelayOperator);
                Assert.Equal(Operators.Between, ptaTopic.SuppliedPtaOperator);
                Assert.Equal(Operators.Between, ptaTopic.DeterminedByUsOperator);
                Assert.Equal(Operators.Between, ptaTopic.IpOfficeDelayOperator);
                Assert.False(ptaTopic.PtaDiscrepancies);
                Assert.Null(ptaTopic.FromApplicantDelay);
                Assert.Null(ptaTopic.ToApplicantDelay);
                Assert.Null(ptaTopic.FromPtaDeterminedByUs);
                Assert.Null(ptaTopic.ToPtaDeterminedByUs);
                Assert.Null(ptaTopic.FromSuppliedPta);
                Assert.Null(ptaTopic.ToSuppliedPta);
                Assert.Null(ptaTopic.FromIpOfficeDelay);
                Assert.Null(ptaTopic.ToIpOfficeDelay);
            }

            [Fact]
            public void ReturnsValuesForPatentTermAdjustmentsTopic()
            {
                var filterCriteria = "<FilterCriteria ID='1'>" +
                                         "<PatentTermAdjustments>" +
                                             "<IPOfficeAdjustment Operator='7'>" +
                                                "<FromDays>1</FromDays>" +
                                                "<ToDays>10</ToDays>" +
                                             "</IPOfficeAdjustment>" +
                                             "<CalculatedAdjustment Operator='8'>" +
                                                "<FromDays>0</FromDays>" +
                                                "<ToDays>20</ToDays>" +
                                             "</CalculatedAdjustment>" +
                                             "<IPOfficeDelay Operator='7'>" +
                                                "<FromDays>1</FromDays>" +
                                                "<ToDays>100</ToDays>" +
                                             "</IPOfficeDelay>" +
                                             "<ApplicantDelay Operator='8'>" +
                                                "<FromDays>1</FromDays>" +
                                                "<ToDays>10</ToDays>" +
                                             "</ApplicantDelay>" +
                                             "<HasDiscrepancy>1</HasDiscrepancy>" +
                                         "</PatentTermAdjustments>" +
                                     "</FilterCriteria>";
                
                var fixture = new PatentTermAdjustmentsTopicBuilderFixture();
                var topic = fixture.Subject.Build(GetXElement(filterCriteria));
                
                Assert.Equal("patentTermAdjustments", topic.TopicKey);
                Assert.NotNull(topic.FormData);
                var ptaTopic = (PatentTermAdjustmentsTopic) topic.FormData;
                Assert.Equal(Operators.Between, ptaTopic.SuppliedPtaOperator);
                Assert.Equal(Operators.NotBetween, ptaTopic.DeterminedByUsOperator);
                Assert.Equal(Operators.Between, ptaTopic.IpOfficeDelayOperator);
                Assert.Equal(Operators.NotBetween, ptaTopic.ApplicantDelayOperator);
                Assert.True(ptaTopic.PtaDiscrepancies);
                Assert.Equal(1, ptaTopic.FromSuppliedPta);
                Assert.Equal(10, ptaTopic.ToSuppliedPta);
                Assert.Equal(0, ptaTopic.FromPtaDeterminedByUs);
                Assert.Equal(20, ptaTopic.ToPtaDeterminedByUs);
                Assert.Equal(1, ptaTopic.FromIpOfficeDelay);
                Assert.Equal(100, ptaTopic.ToIpOfficeDelay);
                Assert.Equal(1, ptaTopic.FromApplicantDelay);
                Assert.Equal(10, ptaTopic.ToApplicantDelay);
            }
        }

        public class PatentTermAdjustmentsTopicBuilderFixture : IFixture<PatentTermAdjustmentsTopicBuilder>
        {
            public PatentTermAdjustmentsTopicBuilderFixture()
            {
                Subject = new PatentTermAdjustmentsTopicBuilder();
            }

            public PatentTermAdjustmentsTopicBuilder Subject { get; set; }
        }
    }
}
