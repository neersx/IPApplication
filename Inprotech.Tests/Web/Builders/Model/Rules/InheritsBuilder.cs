using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class InheritsBuilder : IBuilder<Inherits>
    {
        public InheritsBuilder(int childCriteriaNo, int parentCriteriaNo)
        {
            CriteriaNo = childCriteriaNo;
            FromCriteriaNo = parentCriteriaNo;
        }

        public InheritsBuilder(Criteria parent, Criteria child)
        {
            FromCriteria = parent;
            FromCriteriaNo = parent.Id;
            Criteria = child;
            CriteriaNo = child.Id;
        }

        public int CriteriaNo { get; set; }
        public int FromCriteriaNo { get; set; }
        public Criteria Criteria { get; set; }
        public Criteria FromCriteria { get; set; }

        public Inherits Build()
        {
            return new Inherits(CriteriaNo, FromCriteriaNo)
            {
                Criteria = Criteria ?? new CriteriaBuilder {Id = CriteriaNo}.Build(),
                FromCriteria = FromCriteria ?? new CriteriaBuilder {Id = FromCriteriaNo}.Build()
            };
        }
    }
}