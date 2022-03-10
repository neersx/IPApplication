using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class RolesControlBuilder : IBuilder<RolesControl>
    {
        public int? RoleId { get; set; }
        public int? CriteriaNo { get; set; }
        public short? EntryNumber { get; set; }
        public bool? Inherited { get; set; }

        public RolesControl Build()
        {
            return new RolesControl(
                                    RoleId ?? Fixture.Integer(),
                                    CriteriaNo ?? Fixture.Integer(),
                                    EntryNumber ?? Fixture.Short())
            {
                Inherited = Inherited
            };
        }

        public static RolesControlBuilder For(DataEntryTask dataEntryTask, int roleId)
        {
            return new RolesControlBuilder
            {
                RoleId = roleId,
                CriteriaNo = dataEntryTask.CriteriaId,
                EntryNumber = dataEntryTask.Id
            };
        }
    }
}