using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class OrganisationBuilder : IBuilder<Organisation>
    {
        public int NameNo { get; set; }
        public string RegistrationNo { get; set; }
        public string Incorporated { get; set; }

        public Organisation Build()
        {
            var organisation = new Organisation(NameNo)
            {
                RegistrationNo = RegistrationNo,
                Incorporated = Incorporated
            };
            return organisation;
        }

        public Organisation BuildForName(Name name)
        {
            NameNo = name.Id;
            return Build();
        }
    }
}
