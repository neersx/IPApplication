using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class NameGroupMemberBuilder : IBuilder<NameGroupMember>
    {
        public NameType NameType { get; set; }

        public NameGroup NameGroup { get; set; }

        public NameGroupMember Build()
        {
            return new NameGroupMember(
                                       NameGroup ?? new NameGroupBuilder().Build(),
                                       NameType ?? new NameTypeBuilder().Build());
        }
    }
}