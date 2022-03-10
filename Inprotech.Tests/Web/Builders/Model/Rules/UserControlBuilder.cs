using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class UserControlBuilder : IBuilder<UserControl>
    {
        public string UserId { get; set; }
        public int? CriteriaNo { get; set; }
        public short? EntryNumber { get; set; }
        public decimal? Inherited { get; set; }

        public UserControl Build()
        {
            return new UserControl(
                                   UserId ?? Fixture.String(),
                                   CriteriaNo ?? Fixture.Integer(),
                                   EntryNumber ?? Fixture.Short())
            {
                Inherited = Inherited
            };
        }

        public static UserControlBuilder For(DataEntryTask dataEntryTask, string userId)
        {
            return new UserControlBuilder
            {
                UserId = userId,
                CriteriaNo = dataEntryTask.CriteriaId,
                EntryNumber = dataEntryTask.Id
            };
        }
    }
}