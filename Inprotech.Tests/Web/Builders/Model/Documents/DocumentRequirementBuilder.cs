using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Documents
{
    public class DocumentRequirementBuilder : IBuilder<DocumentRequirement>
    {
        public Criteria Criteria { get; set; }
        public DataEntryTask DataEntryTask { get; set; }
        public Document Document { get; set; }
        public bool IsMandatory { get; set; }
        public decimal? Inherited { get; set; }

        public DocumentRequirement Build()
        {
            return new DocumentRequirement(
                                           Criteria ?? new CriteriaBuilder().Build(),
                                           DataEntryTask ?? new DataEntryTaskBuilder().Build(),
                                           Document ?? new DocumentBuilder().Build(),
                                           IsMandatory)
            {
                Inherited = Inherited
            };
        }
    }
}