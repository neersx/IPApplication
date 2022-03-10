using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class ChecklistBuilder : IBuilder<CheckList>
    {
        public short Id { get; set; }

        public string Description { get; set; }

        public short ChecklistTypeFlag { get; set; }

        public CheckList Build()
        {
            return new CheckList(Id != 0 ? Id : Fixture.Short(), string.IsNullOrEmpty(Description) ? Fixture.String() : Description);
        }
    }
}