using System.Collections.Generic;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class NameGroupBuilder : IBuilder<NameGroup>
    {
        public string GroupName { get; set; }
        public short Id { get; set; }

        public List<NameGroupMember> Members { get; } = new List<NameGroupMember>();

        public NameGroup Build()
        {
            var ng = new NameGroup(Id == 0 ? Fixture.Short() : Id, GroupName ?? Fixture.String());

            foreach (var mt in Members)
                ng.Members.Add(mt);

            return ng;
        }
    }
}